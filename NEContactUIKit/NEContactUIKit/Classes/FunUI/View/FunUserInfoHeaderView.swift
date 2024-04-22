// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import UIKit

@objcMembers
open class FunUserInfoHeaderView: NEBaseUserInfoHeaderView {
  override open func commonUI() {
    super.commonUI()
    avatarImageView.layer.cornerRadius = 4

    NSLayoutConstraint.activate([
      lineView.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
      lineView.rightAnchor.constraint(equalTo: rightAnchor),
      lineView.bottomAnchor.constraint(equalTo: bottomAnchor),
      lineView.heightAnchor.constraint(equalToConstant: 1),
    ])
  }

  override open func setData(user: NEUserWithFriend?) {
    super.setData(user: user)
    guard let friendUser = user else {
      return
    }

    // title

    if let alias = friendUser.friend?.alias, !alias.isEmpty {
      commonUI(showDetail: true)
      titleLabel.text = alias
      let uid = friendUser.user?.accountId ?? ""
      detailLabel.text = "\(localizable("nick")):\(friendUser.user?.name ?? uid)"
      detailLabel2.text = "\(localizable("account")):\(uid)"
    } else {
      commonUI(showDetail: false)
      titleLabel.text = friendUser.showName()
      detailLabel.text = "\(localizable("account")):\(friendUser.user?.accountId ?? "")"
    }
  }
}
