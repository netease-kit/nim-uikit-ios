// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import AVFoundation
import NECommonUIKit
import UIKit

// MARK: - NEScanBeamView

/// 扫描光束渲染视图
/// 使用 Core Graphics 绘制两层叠加的椭圆径向渐变，
/// 精确还原 Figma 效果：以底部中心为原点向上发散的柔和光晕，水平方向也自然衰减。
///
/// Figma 原理：
///   两个纯色矩形（外层 306×46 @ y=41，内层 216×20 @ y=54）叠加大 Gaussian Blur
///   矩形中心均落在容器底边（y=64），blur 向上/两侧扩散 → 底部亮、顶部透明的椭圆光晕
@objcMembers
open class NEScanBeamView: UIView {
  /// 内层细光束颜色（底部最亮区域）子类可 override
  open var beamColor: UIColor = .init(red: 0.275, green: 0.525, blue: 1.0, alpha: 1.0) {
    didSet { setNeedsDisplay() }
  }

  /// 外层宽光晕颜色，子类可 override
  open var glowColor: UIColor = .init(red: 0.337, green: 0.659, blue: 1.0, alpha: 1.0) {
    didSet { setNeedsDisplay() }
  }

  override public init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    isOpaque = false
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    backgroundColor = .clear
    isOpaque = false
  }

  override open func draw(_ rect: CGRect) {
    guard let ctx = UIGraphicsGetCurrentContext() else { return }
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    // 渐变中心：rect 底部中心（Figma 矩形中心均落在容器底边）
    let center = CGPoint(x: rect.midX, y: rect.maxY)

    // —— 外层宽光晕 ——
    // Figma: 306×46 @ (32, 41)，blur=37.8px
    // 水平扩散 ≈ 153+38=191pt ≈ 51% 宽；垂直扩散 ≈ 23+38=61pt ≈ 96% 高
    drawEllipticalGradient(
      ctx: ctx, colorSpace: colorSpace,
      colors: [glowColor, glowColor.withAlphaComponent(0.28), .clear],
      locations: [0.0, 0.50, 1.0],
      center: center,
      hRadius: rect.width * 0.53,
      vRadius: rect.height * 0.96
    )

    // —— 内层细光束 ——
    // Figma: 216×20 @ (77, 54)，blur=23.9px
    // 水平扩散 ≈ 108+24=132pt ≈ 35% 宽；垂直扩散 ≈ 10+24=34pt ≈ 53% 高
    drawEllipticalGradient(
      ctx: ctx, colorSpace: colorSpace,
      colors: [beamColor, beamColor.withAlphaComponent(0.22), .clear],
      locations: [0.0, 0.42, 1.0],
      center: center,
      hRadius: rect.width * 0.36,
      vRadius: rect.height * 0.53
    )
  }

  /// 以 center 为原点，绘制水平方向拉伸的椭圆径向渐变
  private func drawEllipticalGradient(ctx: CGContext,
                                      colorSpace: CGColorSpace,
                                      colors: [UIColor],
                                      locations: [CGFloat],
                                      center: CGPoint,
                                      hRadius: CGFloat,
                                      vRadius: CGFloat) {
    guard vRadius > 0 else { return }
    let cgColors = colors.map(\.cgColor) as CFArray
    guard let gradient = CGGradient(
      colorsSpace: colorSpace,
      colors: cgColors,
      locations: locations
    ) else { return }

    ctx.saveGState()
    // 将原点平移到渐变中心，X 轴缩放实现椭圆（水平半径/垂直半径）
    ctx.translateBy(x: center.x, y: center.y)
    ctx.scaleBy(x: hRadius / vRadius, y: 1.0)
    ctx.drawRadialGradient(
      gradient,
      startCenter: .zero, startRadius: 0,
      endCenter: .zero, endRadius: vRadius,
      options: .drawsBeforeStartLocation
    )
    ctx.restoreGState()
  }
}

// MARK: - NEBaseScanQRViewController

/// 扫一扫基类 ViewController，负责相机授权检查、扫码逻辑及结果回调
@objcMembers
open class NEBaseScanQRViewController: NEBaseViewController, AVCaptureMetadataOutputObjectsDelegate {
  // MARK: - Public properties

  /// 扫描结果回调，返回识别到的字符串；返回 true 表示结果已处理（扫码页可退出），false 表示无效需继续扫描
  public var onScanResult: ((String) -> Bool)?

  /// 扫描光束内层细光束颜色，子类可 override
  /// 基础版：#4686FF，通用版：#22D39B
  open var scanBeamColor: UIColor {
    UIColor(red: 0.275, green: 0.525, blue: 1.0, alpha: 1.0) // #4686FF
  }

  /// 扫描光束外层光晕颜色，子类可 override
  /// 基础版：#56A8FF，通用版：#5DE9A6
  open var scanBeamGlowColor: UIColor {
    UIColor(red: 0.337, green: 0.659, blue: 1.0, alpha: 1.0) // #56A8FF
  }

  /// 光束视图高度（Figma Group 1889 高度 = 64pt）
  open var scanBeamHeight: CGFloat { 64 }

  /// 动画时长（秒）：光束从屏幕顶部移动到底部的时间
  open var scanAnimationDuration: TimeInterval { 2.5 }

  // MARK: - Private properties

  private var captureSession: AVCaptureSession?
  private var previewLayer: AVCaptureVideoPreviewLayer?

  /// 光束容器 topAnchor 约束，用于驱动从上到下的动画
  private var scanBeamTopConstraint: NSLayoutConstraint?

  /// 是否已完成首次 layout 并启动动画
  private var isAnimationStarted = false

  // MARK: - UI elements

  /// 全屏相机预览层容器
  public let previewContainer: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    return v
  }()

  /// 扫描光束视图（NEScanBeamView），从上到下循环动画
  public lazy var scanBeamView: NEScanBeamView = {
    let v = NEScanBeamView()
    v.translatesAutoresizingMaskIntoConstraints = false
    return v
  }()

  // MARK: - Life cycle

  override open func viewDidLoad() {
    super.viewDidLoad()
    title = localizable("scan_qr")
    setupScanUI()
    checkCameraPermission()
  }

  override open func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    previewLayer?.frame = previewContainer.bounds
    // 首次 layout 完成后启动动画（navigationView.frame 已确定）
    if !isAnimationStarted, view.bounds.height > 0 {
      isAnimationStarted = true
      startScanAnimation()
    }
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    startRunning()
    if isAnimationStarted {
      startScanAnimation()
    }
  }

  override open func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    stopRunning()
    stopScanAnimation()
  }

  // MARK: - UI Setup

  /// 构建扫码页面 UI，子类可 override 调整样式
  open func setupScanUI() {
    view.backgroundColor = .black

    // 相机预览：全屏，插入到 navigationView 下层
    view.insertSubview(previewContainer, belowSubview: navigationView)
    NSLayoutConstraint.activate([
      previewContainer.topAnchor.constraint(equalTo: view.topAnchor),
      previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      previewContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    // navigationView：透明背景 + 白色标题/返回按钮
    navigationView.backgroundColor = .clear
    navigationView.navTitle.textColor = .white
    navigationView.titleBarBottomLine.isHidden = true
    if let backImg = navigationView.backButton.image(for: .normal)?
      .withRenderingMode(.alwaysTemplate) {
      navigationView.backButton.setImage(backImg, for: .normal)
    }
    navigationView.backButton.tintColor = .white

    // 扫描光束视图：全宽，高度固定，Y 轴由 topAnchor 约束驱动动画
    view.insertSubview(scanBeamView, belowSubview: navigationView)
    let topConstraint = scanBeamView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0)
    topConstraint.isActive = true
    scanBeamTopConstraint = topConstraint
    NSLayoutConstraint.activate([
      scanBeamView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scanBeamView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scanBeamView.heightAnchor.constraint(equalToConstant: scanBeamHeight),
    ])

    // 将皮肤颜色同步到光束视图
    scanBeamView.beamColor = scanBeamColor
    scanBeamView.glowColor = scanBeamGlowColor
  }

  // MARK: - Animation

  /// 启动扫描光束从上到下循环移动的动画
  open func startScanAnimation() {
    // 停止旧动画，避免重叠
    scanBeamView.layer.removeAllAnimations()

    let navBottom = navigationView.frame.maxY
    let viewHeight = view.bounds.height

    // 立刻将光束定位到导航栏正下方（无动画，不触发隐式动画）
    UIView.performWithoutAnimation {
      self.scanBeamTopConstraint?.constant = navBottom
      self.view.layoutIfNeeded()
    }

    animateBeamStep(from: navBottom, to: viewHeight)
  }

  /// 单次动画步骤（递归调用实现无缝循环）
  private func animateBeamStep(from startY: CGFloat, to endY: CGFloat) {
    UIView.animate(
      withDuration: scanAnimationDuration,
      delay: 0,
      options: [.curveLinear, .allowUserInteraction]
    ) { [weak self] in
      self?.scanBeamTopConstraint?.constant = endY
      self?.view.layoutIfNeeded()
    } completion: { [weak self] finished in
      guard finished, let self = self else { return }
      // 瞬间重置到起始位置，然后再次向下
      UIView.performWithoutAnimation {
        self.scanBeamTopConstraint?.constant = startY
        self.view.layoutIfNeeded()
      }
      self.animateBeamStep(from: startY, to: endY)
    }
  }

  /// 停止扫描光束动画
  open func stopScanAnimation() {
    scanBeamView.layer.removeAllAnimations()
  }

  // MARK: - Camera permission

  private func checkCameraPermission() {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    switch status {
    case .authorized:
      setupCaptureSession()
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
        DispatchQueue.main.async {
          if granted {
            self?.setupCaptureSession()
          } else {
            self?.showNoPermissionTip()
          }
        }
      }
    default:
      showNoPermissionTip()
    }
  }

  private func showNoPermissionTip() {
    showToast(localizable("scan_qr_no_camera_permission"))
  }

  // MARK: - Capture session

  private func setupCaptureSession() {
    guard let device = AVCaptureDevice.default(for: .video),
          let input = try? AVCaptureDeviceInput(device: device) else { return }

    let session = AVCaptureSession()
    session.sessionPreset = .high

    guard session.canAddInput(input) else { return }
    session.addInput(input)

    let output = AVCaptureMetadataOutput()
    guard session.canAddOutput(output) else { return }
    session.addOutput(output)

    output.setMetadataObjectsDelegate(self, queue: .main)
    let supportedTypes: [AVMetadataObject.ObjectType] = [
      .qr, .ean13, .ean8, .code128, .code39, .code93, .aztec, .pdf417, .dataMatrix,
    ]
    output.metadataObjectTypes = supportedTypes.filter {
      output.availableMetadataObjectTypes.contains($0)
    }

    captureSession = session

    let previewLayer = AVCaptureVideoPreviewLayer(session: session)
    previewLayer.videoGravity = .resizeAspectFill
    previewLayer.frame = view.bounds
    previewContainer.layer.insertSublayer(previewLayer, at: 0)
    self.previewLayer = previewLayer

    // 全屏识别区域（光束仅作视觉引导，实际识别不限区域）
    output.rectOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)

    startRunning()
  }

  private func startRunning() {
    guard let session = captureSession, !session.isRunning else { return }
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      self?.captureSession?.startRunning()
    }
  }

  private func stopRunning() {
    guard let session = captureSession, session.isRunning else { return }
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      self?.captureSession?.stopRunning()
    }
  }

  // MARK: - AVCaptureMetadataOutputObjectsDelegate

  public func metadataOutput(_ output: AVCaptureMetadataOutput,
                             didOutput metadataObjects: [AVMetadataObject],
                             from connection: AVCaptureConnection) {
    guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
          let value = obj.stringValue, !value.isEmpty else { return }

    stopRunning()
    UINotificationFeedbackGenerator().notificationOccurred(.success)
    handleScanResult(value)
  }

  // MARK: - Result handling

  /// 处理扫描结果，子类可 override 自定义逻辑
  open func handleScanResult(_ result: String) {
    if let callback = onScanResult {
      // 导航权完全交给回调方，自身不再 pop（回调内会处理扫码页的出栈）
      // 回调返回 true 表示结果有效已处理，false 表示无效需继续扫描
      let handled = callback(result)
      if !handled {
        // 结果无效：重新启动摄像头，允许继续扫描
        startRunning()
      }
    } else {
      showToast(String(format: localizable("scan_qr_result"), result))
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
        self?.navigationController?.popViewController(animated: true)
      }
    }
  }
}
