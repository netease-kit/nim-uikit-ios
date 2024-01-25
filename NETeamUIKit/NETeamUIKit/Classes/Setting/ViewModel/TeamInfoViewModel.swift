// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIMKit
import NIMSDK

@objcMembers
open class TeamInfoViewModel: NSObject {
  var cellDatas = [SettingCellModel]()

  func getData(_ team: NIMTeam?) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", teamId:\(team?.teamId ?? "nil")")
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

    if team?.isDisscuss() == true {
      headerCell.cellName = localizable("discuss_avatar")
      nameCell.cellName = localizable("discuss_name")
      intrCell.cellName = localizable("discuss_intro")
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
