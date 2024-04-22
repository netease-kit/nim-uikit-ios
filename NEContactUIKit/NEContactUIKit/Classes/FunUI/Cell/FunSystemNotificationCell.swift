
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class FunSystemNotificationCell: NEBaseSystemNotificationCell {
  override open func setupCommonCircleHeader() {
    super.setupCommonCircleHeader()
    avatarImageView.layer.cornerRadius = 4
    NSLayoutConstraint.activate([
      avatarImageView.widthAnchor.constraint(equalToConstant: 40),
      avatarImageView.heightAnchor.constraint(equalToConstant: 40),
      avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),
    ])
  }

  override open func setupUI() {
    super.setupUI()

    contentView.updateLayoutConstraint(firstItem: line, seconedItem: contentView, attribute: .right, constant: 0)
    line.backgroundColor = .funContactLineBorderColor
    agreeButton.backgroundColor = .funContactThemeColor
    agreeButton.setTitleColor(.white, for: .normal)
    agreeButton.layer.borderColor = UIColor.funContactThemeColor.cgColor
  }
}
