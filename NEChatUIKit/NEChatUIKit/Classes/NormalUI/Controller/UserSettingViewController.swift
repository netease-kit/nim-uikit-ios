
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonKit
import NIMSDK
import UIKit

@objcMembers
open class UserSettingViewController: NEBaseUserSettingViewController {
  override public init(userId: String) {
    super.init(userId: userId)
    navigationView.backgroundColor = .white
    navigationController?.navigationBar.backgroundColor = .white
    cellClassDic = [
      UserSettingType.SwitchType.rawValue: UserSettingSwitchCell.self,
      UserSettingType.SelectType.rawValue: UserSettingSelectCell.self,
    ]
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func setupUI() {
    super.setupUI()
    userHeaderView.layer.cornerRadius = IMKitConfigCenter.shared.teamEnable ? 21.0 : 30.0
  }

  override func getPinMessageViewController(conversationId: String) -> NEBasePinMessageViewController {
    PinMessageViewController(conversationId: conversationId)
  }
}
