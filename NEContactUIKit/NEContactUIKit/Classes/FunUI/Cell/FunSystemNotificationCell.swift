
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreIMKit
import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class FunSystemNotificationCell: NEBaseSystemNotificationCell {
  override open func setupCommonCircleHeader() {
    super.setupCommonCircleHeader()
    avatarImage.layer.cornerRadius = 4
    NSLayoutConstraint.activate([
      avatarImage.widthAnchor.constraint(equalToConstant: 40),
      avatarImage.heightAnchor.constraint(equalToConstant: 40),
      avatarImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),
    ])
  }

  override open func setupUI() {
    super.setupUI()

    contentView.updateLayoutConstraint(firstItem: line, seconedItem: contentView, attribute: .right, constant: 0)
    line.backgroundColor = .funContactLineBorderColor
    agreeBtn.backgroundColor = .funContactThemeColor
    agreeBtn.setTitleColor(.white, for: .normal)
    agreeBtn.layer.borderColor = UIColor.funContactThemeColor.cgColor
  }
}
