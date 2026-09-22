
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

private let operationLabelHeight: CGFloat = 32
private let operationDefaultFontSize: CGFloat = 14
private let operationMinimumFontSize: CGFloat = 9
private let operationMinimumScaleFactor: CGFloat = 0.8

@objcMembers
open class OperationCell: UICollectionViewCell {
  public var imageView = UIImageView()
  public var label = UILabel()
  public var model: OperationItem? {
    didSet {
      if let imageName = model?.imageName,
         !imageName.isEmpty,
         let image = UIImage.ne_imageNamed(name: imageName) {
        imageView.image = image
      } else {
        imageView.image = model?.image
      }

      label.text = model?.text
      configureLabelText()
    }
  }

  override public init(frame: CGRect) {
    super.init(frame: frame)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonUI()
  }

  override open func layoutSubviews() {
    super.layoutSubviews()
    if type(of: self) == OperationCell.self {
      configureLabelText()
    }
  }

  open func commonUI() {
    contentView.accessibilityIdentifier = "id.menuCell"

    imageView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(imageView)
    imageView.contentMode = .center
    imageView.accessibilityIdentifier = "id.menuIcon"
    NSLayoutConstraint.activate([
      imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 0),
      imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
      imageView.widthAnchor.constraint(equalToConstant: 18),
      imageView.heightAnchor.constraint(equalToConstant: 18),
    ])

    label.font = UIFont.systemFont(ofSize: 14)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_darkText
    label.textAlignment = .center
    label.numberOfLines = 2
    label.lineBreakMode = .byCharWrapping
    label.accessibilityIdentifier = "id.menuTitle"
    contentView.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 2),
      label.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0),
      label.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0),
      label.heightAnchor.constraint(equalToConstant: operationLabelHeight),
    ])
  }

  private func configureLabelText() {
    let isPlugin = model?.type == .plugin
    let baseFontSize = isPlugin ? 11 : operationDefaultFontSize
    let minimumScaleFactor = isPlugin ? 0.65 : operationMinimumScaleFactor
    let baseFont = UIFont.systemFont(ofSize: baseFontSize)
    let layoutWidth = contentView.bounds.width
    let availableWidth = layoutWidth > 0 ? layoutWidth : 50
    let availableHeight = label.bounds.height > 0 ? label.bounds.height : operationLabelHeight
    let text = label.text ?? ""
    let textWidth = (text as NSString).size(withAttributes: [.font: baseFont]).width

    // Keep short titles in the existing two-line cell, but scale titles that
    // only miss the fixed column by a few points instead of clipping them.
    if (isPlugin || textWidth > availableWidth) && textWidth * minimumScaleFactor <= availableWidth {
      label.font = baseFont
      label.numberOfLines = 1
      label.adjustsFontSizeToFitWidth = true
      label.minimumScaleFactor = minimumScaleFactor
      label.lineBreakMode = .byClipping
      return
    }

    var fontSize = baseFontSize
    let measureLabel = UILabel()
    measureLabel.text = text
    measureLabel.numberOfLines = 0
    measureLabel.lineBreakMode = .byCharWrapping
    while fontSize > operationMinimumFontSize {
      measureLabel.font = UIFont.systemFont(ofSize: fontSize)
      let measuredSize = measureLabel.sizeThatFits(
        CGSize(width: availableWidth, height: .greatestFiniteMagnitude)
      )
      if measuredSize.height <= min(availableHeight, measureLabel.font.lineHeight * 2) {
        break
      }
      fontSize -= 0.5
    }

    label.font = UIFont.systemFont(ofSize: fontSize)
    label.numberOfLines = 2
    label.adjustsFontSizeToFitWidth = false
    label.minimumScaleFactor = 1
    label.lineBreakMode = .byCharWrapping
  }
}
