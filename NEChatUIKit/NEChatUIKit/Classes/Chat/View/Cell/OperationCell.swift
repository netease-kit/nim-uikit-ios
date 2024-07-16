
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

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

  public func commonUI() {
    contentView.accessibilityIdentifier = "id.menuCell"

    imageView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(imageView)
    imageView.contentMode = .center
    imageView.accessibilityIdentifier = "id.menuIcon"
    NSLayoutConstraint.activate([
      imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 0),
      imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
      imageView.widthAnchor.constraint(equalToConstant: 18),
      imageView.heightAnchor.constraint(equalToConstant: 18),
    ])

    label.font = UIFont.systemFont(ofSize: 14)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_darkText
    label.textAlignment = .center
    label.accessibilityIdentifier = "id.menuTitle"
    contentView.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
      label.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0),
      label.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0),
      label.heightAnchor.constraint(equalToConstant: 18),
    ])
  }
}
