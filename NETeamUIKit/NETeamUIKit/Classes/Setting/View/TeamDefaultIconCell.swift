
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECommonKit

@objcMembers
public class TeamDefaultIconCell: UICollectionViewCell {
  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  override public var isSelected: Bool {
    didSet {
      print("default icon select ", isSelected)
      selectBack.isHidden = !isSelected
    }
  }

  lazy var iconImage: UIImageView = {
    let image = UIImageView()
    image.translatesAutoresizingMaskIntoConstraints = false
    return image
  }()

  lazy var selectBack: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = NEConstant.hexRGB(0xF4F4F4)
    view.clipsToBounds = true
    view.layer.cornerRadius = 8.0
    view.isHidden = true
    return view
  }()

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupUI() {
    contentView.addSubview(selectBack)
    NSLayoutConstraint.activate([
      selectBack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      selectBack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      selectBack.widthAnchor.constraint(equalToConstant: 48.0),
      selectBack.heightAnchor.constraint(equalToConstant: 48.0),
    ])

    contentView.addSubview(iconImage)
    NSLayoutConstraint.activate([
      iconImage.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      iconImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      iconImage.heightAnchor.constraint(equalToConstant: 32),
      iconImage.widthAnchor.constraint(equalToConstant: 32),
    ])
  }
}
