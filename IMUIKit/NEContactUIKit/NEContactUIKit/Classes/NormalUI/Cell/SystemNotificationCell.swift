
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class SystemNotificationCell: NEBaseSystemNotificationCell {
  override open func setupCommonCircleHeader() {
    super.setupCommonCircleHeader()
    userHeaderView.layer.cornerRadius = 18
    NSLayoutConstraint.activate([
      userHeaderView.widthAnchor.constraint(equalToConstant: 36),
      userHeaderView.heightAnchor.constraint(equalToConstant: 36),
      userHeaderView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),
    ])
  }
}
