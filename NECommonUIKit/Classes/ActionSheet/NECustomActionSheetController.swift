// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit

public class NECustomAlertAction: UIView {
  public var showDefaultLine = false

  public lazy var contentText: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textAlignment = .center
    label.font = .systemFont(ofSize: 16)
    label.textColor = .ne_darkText
    return label
  }()

  public var clickAction: (() -> Void)?
  public var cancelAction: (() -> Void)?

  var cornerLayer = CAShapeLayer()
  public var fillColor: UIColor = .white
  public var edgeInset: UIEdgeInsets = .init(top: 0, left: 20, bottom: 0, right: 20)
  private var type: CornerType = .none
  public var dividerLineLeftMargin: NSLayoutConstraint?
  public var dividerLineRightMargin: NSLayoutConstraint?
  public var cornerType: CornerType {
    get { type }
    set {
      if type != newValue {
        type = newValue
        sizeToFit()
      }
    }
  }

  public lazy var dividerLine: UIView = {
    let line = UIView()
    line.translatesAutoresizingMaskIntoConstraints = false
    line.backgroundColor = NEConstant.hexRGB(0xF5F8FC)
    line.isHidden = true
    return line
  }()

  public init(title: String?, _ completion: (() -> Void)?) {
    super.init(frame: .zero)
    layer.insertSublayer(cornerLayer, below: layer)
    addSubview(dividerLine)

    dividerLineLeftMargin = dividerLine.leftAnchor.constraint(equalTo: leftAnchor, constant: 36)
    dividerLineRightMargin = dividerLine.rightAnchor.constraint(equalTo: rightAnchor, constant: -20)

    NSLayoutConstraint.activate([
      dividerLineLeftMargin!,
      dividerLineRightMargin!,
      dividerLine.heightAnchor.constraint(equalToConstant: 1),
      dividerLine.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    backgroundColor = .clear
    contentText.text = title
    clickAction = completion

    edgeInset = .zero
    dividerLine.isHidden = false
    dividerLine.backgroundColor = UIColor(hexString: "#EDEDED")
    dividerLineLeftMargin?.constant = 0
    dividerLineRightMargin?.constant = 0
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupUI() {
    addSubview(contentText)
    NSLayoutConstraint.activate([
      contentText.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
      contentText.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
      contentText.topAnchor.constraint(equalTo: topAnchor, constant: 0),
      contentText.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
    ])

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleViewTap(sender:)))
    addGestureRecognizer(tapGesture)
  }

  override open func draw(_ rect: CGRect) {
    drawRoundedCorner(rect: rect)
  }

  open func drawRoundedCorner(rect: CGRect) {
    var path = UIBezierPath()
    let roundRect = CGRect(
      x: rect.origin.x + edgeInset.left,
      y: rect.origin.y + edgeInset.top,
      width: rect.width - (edgeInset.left + edgeInset.right),
      height: rect.height - (edgeInset.top + edgeInset.bottom)
    )
    if type == .none {
      path = UIBezierPath(rect: roundRect)
      if showDefaultLine { dividerLine.isHidden = false }
    }
    var corners = UIRectCorner()
    if type.contains(CornerType.topLeft) {
      corners = corners.union(.topLeft)
      if showDefaultLine { dividerLine.isHidden = false }
    }
    if type.contains(CornerType.topRight) {
      corners = corners.union(.topRight)
    }
    if type.contains(CornerType.bottomLeft) {
      corners = corners.union(.bottomLeft)
      if showDefaultLine { dividerLine.isHidden = true }
    }
    if type.contains(CornerType.bottomRight) {
      corners = corners.union(.bottomRight)
    }
    path = UIBezierPath(
      roundedRect: roundRect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: 10, height: 10)
    )

    cornerLayer.path = path.cgPath
    cornerLayer.fillColor = fillColor.cgColor
  }

  /// 处理点击
  /// - Parameter sender: 手势
  @objc
  private func handleViewTap(sender: UITapGestureRecognizer) {
    if let cancelBlock = cancelAction {
      cancelBlock()
    }
    if let clickBlock = clickAction {
      clickBlock()
    }
  }
}

@objcMembers
public class NECustomActionSheetController: UIViewController {
  var sheetHeight: CGFloat = 0
  var topAction: NECustomAlertAction?
  public lazy var cancelAction: NECustomAlertAction = {
    let view = NECustomAlertAction(title: commonLocalizable("cancel"), nil)
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  public var boldDividerLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor(hexString: "#F7F7F7")
    return view
  }()

  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    modalPresentationStyle = .overFullScreen
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: DispatchWorkItem(block: {
      UIView.animate(withDuration: 0.25) {
        self.view.backgroundColor = UIColor(white: 0, alpha: 0.4)
      }
    }))
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDismissTap))
    view.addGestureRecognizer(tapGesture)
  }

  /// 处理点击消失
  /// - Parameter sender: 手势
  @objc
  private func handleDismissTap() {
    dismiss(animated: false)
  }

  func setupUI() {
    cancelAction.clickAction = handleDismissTap
    addAction(cancelAction, 89)
    view.addSubview(boldDividerLine)
    NSLayoutConstraint.activate([
      boldDividerLine.leftAnchor.constraint(equalTo: view.leftAnchor),
      boldDividerLine.rightAnchor.constraint(equalTo: view.rightAnchor),
      boldDividerLine.bottomAnchor.constraint(equalTo: cancelAction.topAnchor),
      boldDividerLine.heightAnchor.constraint(equalToConstant: 6),
    ])
    sheetHeight += 6
  }

  open func addAction(_ action: NECustomAlertAction, _ actionHeight: CGFloat = 51) {
    action.translatesAutoresizingMaskIntoConstraints = false
    action.cancelAction = handleDismissTap
    view.addSubview(action)
    NSLayoutConstraint.activate([
      action.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
      action.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
      action.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -sheetHeight),
      action.heightAnchor.constraint(equalToConstant: actionHeight),
    ])
    sheetHeight += actionHeight
    topAction?.cornerType = .none
    topAction = action
    topAction?.cornerType = .topLeft.union(.topRight)
  }
}
