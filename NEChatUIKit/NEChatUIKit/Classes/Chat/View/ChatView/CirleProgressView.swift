
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class CirleProgressView: UIView {
//    0~1
  public var progress: Float = 0 {
    didSet {
      if progress == 0 {
        borderLayer.isHidden = true
        sectorLayer.isHidden = true
        imageView.isHidden = false
        imageView.image = UIImage.ne_imageNamed(name: "chat_unread")
      } else if progress == 1.0 {
        borderLayer.isHidden = true
        sectorLayer.isHidden = true
        imageView.isHidden = false
        imageView.image = UIImage.ne_imageNamed(name: "chat_read_all")
      } else {
        imageView.isHidden = true
        borderLayer.isHidden = false
        sectorLayer.isHidden = false
        drawCircle(progress: progress)
      }
    }
  }

  public var borderLayer = CAShapeLayer()
  public var sectorLayer = CAShapeLayer()
  private var imageView = UIImageView(image: UIImage.ne_imageNamed(name: "chat_unread"))

//    override func draw(_ rect: CGRect) {
//        drawCircle(progress: progress)
//    }

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    imageView.frame = bounds
    imageView.contentMode = .center
    addSubview(imageView)

    let borderPath = UIBezierPath(
      arcCenter: CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0),
      radius: 8,
      startAngle: 0,
      endAngle: 2 * Double.pi,
      clockwise: false
    )
    borderLayer.path = borderPath.cgPath
    borderLayer.strokeColor = UIColor.ne_blueText.cgColor
    borderLayer.fillColor = UIColor.clear.cgColor
    borderLayer.lineWidth = 2
    borderLayer.frame = bounds
    layer.addSublayer(borderLayer)

    sectorLayer.frame = bounds
    sectorLayer.fillColor = UIColor.ne_blueText.cgColor
    layer.addSublayer(sectorLayer)
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func drawCircle(progress: Float) {
    let center = CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0)
    let start = -Float.pi / 2.0
    let end = start + (progress * 2 * Float.pi)

    let sectorPath = UIBezierPath(
      arcCenter: center,
      radius: 8,
      startAngle: CGFloat(start),
      endAngle: CGFloat(end),
      clockwise: true
    )
    sectorPath.addLine(to: center)
    sectorLayer.path = sectorPath.cgPath
  }
}
