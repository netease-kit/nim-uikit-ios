
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECommonKit
import NIMSDK

@objcMembers
open class UserSettingViewController: NEBaseUserSettingViewController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    customNavigationView.backgroundColor = .white
    navigationController?.navigationBar.backgroundColor = .white
    cellClassDic = [
      UserSettingType.SwitchType.rawValue: UserSettingSwitchCell.self,
      UserSettingType.SelectType.rawValue: UserSettingSelectCell.self,
    ]
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func setupUI() {
    super.setupUI()
    userHeader.layer.cornerRadius = 21.0
  }

  override func getPinMessageViewController(session: NIMSession) -> NEBasePinMessageViewController {
    PinMessageViewController(session: session)
  }
}
