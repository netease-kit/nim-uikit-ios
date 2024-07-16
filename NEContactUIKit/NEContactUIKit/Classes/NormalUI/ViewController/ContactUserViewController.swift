
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class ContactUserViewController: NEBaseContactUserViewController {
  func initNormal() {
    className = "ContactUserViewController"
    headerView = UserInfoHeaderView()
  }

  override public init(uid: String) {
    super.init(uid: uid)
    initNormal()
  }

  override public init(nim_user: V2NIMUser) {
    super.init(nim_user: nim_user)
    initNormal()
  }

  override public init(user: NEUserWithFriend?) {
    super.init(user: user)
    initNormal()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func commonUI() {
    super.commonUI()
    tableView.rowHeight = 62
  }

  override open func getContactAliasViewController() -> NEBaseContactAliasViewController {
    ContactAliasViewController()
  }
}
