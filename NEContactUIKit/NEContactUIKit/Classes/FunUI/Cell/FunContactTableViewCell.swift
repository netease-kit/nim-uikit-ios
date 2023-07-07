
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECoreIMKit
import Foundation
import NECoreKit

@objcMembers
open class FunContactTableViewCell: NEBaseContactTableViewCell {
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
    bottomLine.backgroundColor = .funContactLineBorderColor
  }

  override open func initSubviewsLayout() {
    if NEKitContactConfig.shared.ui.avatarType == .rectangle {
      avatarImage.layer.cornerRadius = NEKitContactConfig.shared.ui.avatarCornerRadius
    } else if NEKitContactConfig.shared.ui.avatarType == .cycle {
      avatarImage.layer.cornerRadius = 20.0
    } else {
      avatarImage.layer.cornerRadius = 4.0 // Fun UI
    }
  }

  override open func setConfig() {
    super.setConfig()
    titleLabel.font = NEKitContactConfig.shared.ui.titleFont ?? UIFont.systemFont(ofSize: 17)
  }

  override open func setModel(_ model: ContactInfo) {
    super.setModel(model)
    arrow.isHidden = true
  }
}
