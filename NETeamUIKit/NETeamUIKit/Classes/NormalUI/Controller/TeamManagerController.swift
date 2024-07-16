//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class TeamManagerController: NEBaseTeamManagerController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    cellClassDic = [
      SettingCellType.SettingArrowCell.rawValue: TeamSettingLabelArrowCell.self,
      SettingCellType.SettingSwitchCell.rawValue: TeamSettingSwitchCell.self,
      SettingCellType.SettingSelectCell.rawValue: TeamSettingSelectCell.self,
    ]
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    navigationView.backgroundColor = .ne_lightBackgroundColor
    navigationController?.navigationBar.backgroundColor = .ne_lightBackgroundColor
  }

  override open func didManagerClick() {
    let controller = TeamManagerListController()
    controller.teamId = viewModel.teamInfoModel?.team?.teamId
    navigationController?.pushViewController(controller, animated: true)
  }
}
