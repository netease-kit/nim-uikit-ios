//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunTeamManagerController: NEBaseTeamManagerController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    cellClassDic = [
      SettingCellType.SettingArrowCell.rawValue: FunTeamSettingLabelArrowCell.self,
      SettingCellType.SettingSwitchCell.rawValue: FunTeamSettingSwitchCell.self,
      SettingCellType.SettingSelectCell.rawValue: FunTeamSettingSelectCell.self,
    ]
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .ne_lightBackgroundColor
    navigationController?.navigationBar.backgroundColor = .ne_lightBackgroundColor
    navigationView.backgroundColor = .ne_lightBackgroundColor
  }

  /// 加载数据，在子类中重新设置样式
  override open func reloadSectionData() {
    for setionModel in viewModel.sectionData {
      for cellModel in setionModel.cellModels {
        cellModel.cornerType = .none
        if cellModel.rowHeight > 70 {
          cellModel.rowHeight = 78
        } else {
          cellModel.rowHeight = 56
        }
      }
    }
  }

  override open func didManagerClick() {
    let controller = FunTeamManagerListController()
    controller.teamId = viewModel.teamInfoModel?.team?.teamId
    navigationController?.pushViewController(controller, animated: true)
  }
}
