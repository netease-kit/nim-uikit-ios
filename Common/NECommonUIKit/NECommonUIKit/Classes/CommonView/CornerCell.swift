
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import UIKit

public struct CornerType: OptionSet {
  public init(rawValue: Int) { self.rawValue = rawValue }
  public let rawValue: Int
  public static let none = CornerType(rawValue: 1)
  public static let topLeft = CornerType(rawValue: 2)
  public static let topRight = CornerType(rawValue: 4)
  public static let bottomLeft = CornerType(rawValue: 8)
  public static let bottomRight = CornerType(rawValue: 16)
}

@objcMembers
open class CornerCell: UITableViewCell {
  public var cornerLayer = CAShapeLayer()
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

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = .clear
    selectionStyle = .none
    layer.insertSublayer(cornerLayer, below: contentView.layer)
    contentView.addSubview(dividerLine)

    dividerLineLeftMargin = dividerLine.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 36)
    dividerLineRightMargin = dividerLine.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20)

    NSLayoutConstraint.activate([
      dividerLineLeftMargin!,
      dividerLineRightMargin!,
      dividerLine.heightAnchor.constraint(equalToConstant: 1),
      dividerLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  public lazy var dividerLine: UIView = {
    let line = UIView()
    line.translatesAutoresizingMaskIntoConstraints = false
    line.backgroundColor = NEConstant.hexRGB(0xF5F8FC)
    line.isHidden = true
    return line
  }()

  public var showDefaultLine = false

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
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
}
