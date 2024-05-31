
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import UIKit

@objcMembers
open class UserInfoHeaderView: NEBaseUserInfoHeaderView {
  override open func commonUI() {
    super.commonUI()
    avatarImageView.layer.cornerRadius = 30

    NSLayoutConstraint.activate([
      lineView.leftAnchor.constraint(equalTo: leftAnchor),
      lineView.rightAnchor.constraint(equalTo: rightAnchor),
      lineView.bottomAnchor.constraint(equalTo: bottomAnchor),
      lineView.heightAnchor.constraint(equalToConstant: 6),
    ])
  }
}
