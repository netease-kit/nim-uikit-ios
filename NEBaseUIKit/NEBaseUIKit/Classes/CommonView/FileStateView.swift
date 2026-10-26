
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEChatKit

@objc
public enum FileState: Int {
  case FileOpen = 1
  case FileDownload
}

@objcMembers
open class FileStateView: UIView {
  private var didSetupUI = false
  private var currentProgress: Float = 0

  public lazy var circleLayer: CAShapeLayer = {
    let layer = CAShapeLayer()
    layer.isHidden = true
    return layer
  }()

  public lazy var progressLayer: CAShapeLayer = {
    let layer = CAShapeLayer()
    layer.isHidden = true
    return layer
  }()

  public var state = FileState.FileOpen {
    didSet {
      switch state {
      case .FileOpen:
        FileOpenImage.isHidden = false
        verticalLineLeft.isHidden = true
        verticalLineRight.isHidden = true
        circleLayer.isHidden = true
        progressLayer.isHidden = true
        alphaBackView.isHidden = true
      case .FileDownload:
        FileOpenImage.isHidden = true
        verticalLineLeft.isHidden = false
        verticalLineRight.isHidden = false
        circleLayer.isHidden = false
        progressLayer.isHidden = false
        alphaBackView.isHidden = false
      }
    }
  }

  public lazy var FileOpenImage: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
//      image.image = UIImage.ne_imageNamed(name: "save_btn")
    imageView.isHidden = false
    return imageView
  }()

  public lazy var alphaBackView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = NEConstant.hexRGB(0x000000).withAlphaComponent(0.2)
    view.clipsToBounds = true
    view.isHidden = true
    return view
  }()

  public lazy var verticalLineLeft: UIView = {
    let line = UIView()
    line.translatesAutoresizingMaskIntoConstraints = false
    line.backgroundColor = .white
    line.clipsToBounds = true
    line.layer.cornerRadius = 1.5
    line.isHidden = true
    return line
  }()

  public lazy var verticalLineRight: UIView = {
    let line = UIView()
    line.translatesAutoresizingMaskIntoConstraints = false
    line.backgroundColor = .white
    line.clipsToBounds = true
    line.layer.cornerRadius = 1.5
    line.isHidden = true
    return line
  }()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  func setupUI() {
    guard !didSetupUI else { return }
    didSetupUI = true
    addSubview(FileOpenImage)
    NSLayoutConstraint.activate([
      FileOpenImage.centerXAnchor.constraint(equalTo: centerXAnchor),
      FileOpenImage.centerYAnchor.constraint(equalTo: centerYAnchor),
      FileOpenImage.widthAnchor.constraint(equalToConstant: 32),
      FileOpenImage.heightAnchor.constraint(equalToConstant: 32),
    ])

    addSubview(alphaBackView)
    NSLayoutConstraint.activate([
      alphaBackView.centerXAnchor.constraint(equalTo: centerXAnchor),
      alphaBackView.centerYAnchor.constraint(equalTo: centerYAnchor),
      alphaBackView.widthAnchor.constraint(equalToConstant: 32),
      alphaBackView.heightAnchor.constraint(equalToConstant: 32),
    ])

    addSubview(verticalLineLeft)
    NSLayoutConstraint.activate([
      verticalLineLeft.centerYAnchor.constraint(equalTo: centerYAnchor),
      verticalLineLeft.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -3.5),
      verticalLineLeft.heightAnchor.constraint(equalToConstant: 10.0),
      verticalLineLeft.widthAnchor.constraint(equalToConstant: 2),
    ])

    addSubview(verticalLineRight)
    NSLayoutConstraint.activate([
      verticalLineRight.centerYAnchor.constraint(equalTo: centerYAnchor),
      verticalLineRight.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 3.5),
      verticalLineRight.heightAnchor.constraint(equalToConstant: 10.0),
      verticalLineRight.widthAnchor.constraint(equalToConstant: 2),
    ])

    circleLayer.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
    circleLayer.fillColor = UIColor.clear.cgColor
    circleLayer.lineWidth = 2
    circleLayer.frame = bounds
    layer.addSublayer(circleLayer)

    layer.addSublayer(progressLayer)
  }

  override open func layoutSubviews() {
    super.layoutSubviews()
    updateProgressLayers()
  }

  open func setProgress(_ progress: Float) {
    currentProgress = min(max(progress, 0), 1)
    if currentProgress < 1.0, state == .FileOpen {
      state = .FileDownload
    }
    updateProgressLayers()
    if currentProgress >= 1.0, state == .FileDownload {
      state = .FileOpen
    }
  }

  private func updateProgressLayers() {
    let center = CGPoint(x: bounds.midX, y: bounds.midY)
    let borderPath = UIBezierPath(
      arcCenter: center,
      radius: 9,
      startAngle: 0,
      endAngle: 2 * Double.pi,
      clockwise: true
    )
    circleLayer.frame = bounds
    circleLayer.path = borderPath.cgPath

    let start = -0.5 * Float.pi
    let end = currentProgress * 2 * Float.pi - 0.5 * Float.pi

    let progressPath = UIBezierPath(
      arcCenter: center,
      radius: 9,
      startAngle: CGFloat(start),
      endAngle: CGFloat(end),
      clockwise: true
    )
    progressLayer.frame = bounds
    progressLayer.path = progressPath.cgPath
    progressLayer.strokeColor = UIColor.white.cgColor
    progressLayer.fillColor = UIColor.clear.cgColor
    progressLayer.lineWidth = 2
  }
}
