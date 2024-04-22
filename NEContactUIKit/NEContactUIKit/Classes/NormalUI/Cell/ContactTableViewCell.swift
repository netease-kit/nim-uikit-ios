
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIM2Kit
import NECoreKit
import UIKit

@objcMembers
open class ContactTableViewCell: NEBaseContactTableViewCell {
  override open func setConfig() {
    super.setConfig()
    titleLabel.font = .systemFont(ofSize: NEKitContactConfig.shared.ui.contactProperties.itemTitleSize > 0 ? NEKitContactConfig.shared.ui.contactProperties.itemTitleSize : 14)
  }

  override open func commonUI() {
    super.commonUI()
    bottomLine.backgroundColor = .ne_greyLine
  }

  override open func setupCommonCircleHeader() {
    super.setupCommonCircleHeader()
    NSLayoutConstraint.activate([
      avatarImageView.widthAnchor.constraint(equalToConstant: 36),
      avatarImageView.heightAnchor.constraint(equalToConstant: 36),
      avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),
    ])
  }

  override open func setModel(_ model: ContactInfo) {
    super.setModel(model)
    if model.contactCellType == 2 {
      bottomLine.isHidden = true
    }
  }
}
