
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

  override public init(user: NEUserWithFriend?) {
    super.init(user: user)
    initNormal()
  }

  override public init(uid: String) {
    super.init(uid: uid)
    initNormal()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func commonUI() {
    super.commonUI()
    tableView.rowHeight = 62
  }

  override open func getContactRemakNameViewController() -> NEBaseContactRemakNameViewController {
    ContactRemakNameViewController()
  }
}
