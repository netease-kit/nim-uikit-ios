
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

  override open func setData(user: NEUserWithFriend?) {
    super.setData(user: user)
    guard let userFriend = user else {
      return
    }
    // title

    if let alias = userFriend.friend?.alias, !alias.isEmpty {
      commonUI(showDetail: true)
      titleLabel.text = alias
      let uid = userFriend.user?.accountId ?? ""
      detailLabel.text = "\(localizable("nick")):\(userFriend.user?.name ?? uid)"
      detailLabel2.text = "\(localizable("account")):\(uid)"
    } else {
      commonUI(showDetail: false)
      titleLabel.text = userFriend.showName()
      detailLabel.text = "\(localizable("account")):\(userFriend.user?.accountId ?? "")"
    }
  }
}
