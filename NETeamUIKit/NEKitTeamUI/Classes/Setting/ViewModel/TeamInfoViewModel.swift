
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEKitTeam
import NIMSDK
class TeamInfoViewModel {
  var cellDatas = [SettingCellModel]()

  func getData(_ team: NIMTeam?) {
    cellDatas.removeAll()

    let headerCell = SettingCellModel()
    headerCell.cornerType = .topLeft.union(.topRight)
    headerCell.type = SettingCellType.SettingHeaderCell.rawValue
    headerCell.headerUrl = team?.avatarUrl
    headerCell.rowHeight = 74.0

    let nameCell = SettingCellModel()
    nameCell.type = SettingCellType.SettingArrowCell.rawValue

    let intrCell = SettingCellModel()
    intrCell.type = SettingCellType.SettingArrowCell.rawValue
    intrCell.cornerType = .bottomLeft.union(.bottomRight)

    if let type = team?.type, type == .normal {
      headerCell.cellName = "讨论组头像"
      nameCell.cellName = "讨论组名称"
      intrCell.cellName = "讨论组介绍"
      cellDatas.append(contentsOf: [headerCell, nameCell])
      nameCell.cornerType = .bottomLeft.union(.bottomRight)
    } else {
      cellDatas.append(contentsOf: [headerCell, nameCell, intrCell])
      headerCell.cellName = localizable("team_header")
      nameCell.cellName = localizable("team_name")
      intrCell.cellName = localizable("team_intr")
    }
  }
}
