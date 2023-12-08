
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunContactSelectedCell: NEBaseContactSelectedCell {
  override open func setupCommonCircleHeader() {
    super.setupCommonCircleHeader()
    NSLayoutConstraint.activate([
      avatarImage.widthAnchor.constraint(equalToConstant: 40),
      avatarImage.heightAnchor.constraint(equalToConstant: 40),
      avatarImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),
    ])
  }

  override open func commonUI() {
    super.commonUI()
    sImage.highlightedImage = UIImage.ne_imageNamed(name: "fun_select")
    NSLayoutConstraint.activate([
      sImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      sImage.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
    ])

    bottomLine.backgroundColor = .funContactLineBorderColor
  }

  override open func initSubviewsLayout() {
    if NEKitContactConfig.shared.ui.contactProperties.avatarType == .rectangle {
      avatarImage.layer.cornerRadius = NEKitContactConfig.shared.ui.contactProperties.avatarCornerRadius
    } else if NEKitContactConfig.shared.ui.contactProperties.avatarType == .cycle {
      avatarImage.layer.cornerRadius = 20.0
    } else {
      avatarImage.layer.cornerRadius = 4.0 // Fun UI
    }
  }

  override open func setConfig() {
    super.setConfig()
    titleLabel.font = .systemFont(ofSize: NEKitContactConfig.shared.ui.contactProperties.itemTitleSize > 0 ? NEKitContactConfig.shared.ui.contactProperties.itemTitleSize : 17)
  }

  override open func setModel(_ model: ContactInfo) {
    super.setModel(model)
    arrow.isHidden = true
  }
}
