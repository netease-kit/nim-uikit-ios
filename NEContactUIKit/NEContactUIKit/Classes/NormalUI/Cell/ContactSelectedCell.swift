
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class ContactSelectedCell: NEBaseContactSelectedCell {
  override open func commonUI() {
    super.commonUI()
    sImageView.highlightedImage = UIImage.ne_imageNamed(name: "select")
    NSLayoutConstraint.activate([
      sImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      sImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
    ])
  }

  override open func setConfig() {
    super.setConfig()
    titleLabel.font = .systemFont(ofSize: NEKitContactConfig.shared.ui.contactProperties.itemTitleSize > 0 ? NEKitContactConfig.shared.ui.contactProperties.itemTitleSize : 14)
  }

  override open func setupCommonCircleHeader() {
    super.setupCommonCircleHeader()
    NSLayoutConstraint.activate([
      avatarImageView.widthAnchor.constraint(equalToConstant: 36),
      avatarImageView.heightAnchor.constraint(equalToConstant: 36),
      avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),
    ])
  }
}
