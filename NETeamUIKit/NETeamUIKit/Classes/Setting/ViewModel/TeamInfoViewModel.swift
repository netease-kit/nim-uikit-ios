// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIM2Kit
import NIMSDK

/// 群信息变更回调协议
@objc public protocol NETeamInfoDelegate: NSObjectProtocol {
  /// 群信息变更
  func teamInfoDidUpdate(_ team: V2NIMTeam)
}

@objcMembers
open class TeamInfoViewModel: NSObject, NETeamListener {
  /// UI 列表数据源
  var cellDatas = [SettingCellModel]()

  /// chat kit 群 api 单例
  public let teamRepo = TeamRepo.shared

  /// 群
  public var v2Team: V2NIMTeam?

  /// 代理
  public weak var delegate: NETeamInfoDelegate?

  override public init() {
    super.init()
    teamRepo.addTeamListener(self)
  }

  /// 获取群信息
  /// - Parameter team: 群
  func getData(_ team: V2NIMTeam?) {
    v2Team = team
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamId:\(team?.teamId ?? "nil")")
    cellDatas.removeAll()

    let headerCell = SettingCellModel()
    headerCell.cornerType = .topLeft.union(.topRight)
    headerCell.type = SettingCellType.SettingHeaderCell.rawValue
    headerCell.headerUrl = team?.avatar
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

  /// 群信息更新
  /// - Parameter team: 群
  public func onTeamInfoUpdated(_ team: V2NIMTeam) {
    if let teamId = v2Team?.teamId, teamId == team.teamId {
      getData(team)
      delegate?.teamInfoDidUpdate(team)
    }
  }
}
