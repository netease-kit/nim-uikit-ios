// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIMKit
import NECoreKit

@objcMembers
open class TeamListViewModel: NSObject, NIMTeamManagerDelegate {
  var contactRepo = ContactRepo.shared
  var refresh: () -> Void = {}
  public var teamList = [NETeam]()
  private let className = "TeamListViewModel"

  override public init() {
    super.init()
    contactRepo.addTeamDelegate(delegate: self)
  }

  deinit {
    contactRepo.removeTeamDelegate(delegate: self)
  }

  func getTeamList() -> [NETeam]? {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    teamList = contactRepo.getTeamList()
    teamList.sort(by: { team1, team2 in
      (team1.createTime ?? 0) > (team2.createTime ?? 0)
    })
    return teamList
  }

  // MARK: NIMTeamManagerDelegate

  public func onTeamAdded(_ team: NIMTeam) {
    teamList.insert(NETeam(teamInfo: team), at: 0)
    refresh()
  }

  public func onTeamUpdated(_ team: NIMTeam) {
    for (i, t) in teamList.enumerated() {
      if t.teamId == team.teamId {
        teamList[i] = NETeam(teamInfo: team)
        refresh()
        break
      }
    }
  }

  public func onTeamRemoved(_ team: NIMTeam) {
    for (i, t) in teamList.enumerated() {
      if t.teamId == team.teamId {
        teamList.remove(at: i)
        refresh()
        break
      }
    }
  }
}
