// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIM2Kit
import NECoreKit

@objcMembers
open class TeamListViewModel: NSObject, NETeamListener {
  var teamRepo = TeamRepo.shared
  var refresh: () -> Void = {}
  public var teamList = [NETeam]()

  override public init() {
    super.init()
    teamRepo.addTeamListener(self)
  }

  deinit {
    teamRepo.removeTeamListener(self)
  }

  func getTeamList(_ completion: @escaping ([NETeam]?, Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    teamRepo.getTeamList { [weak self] teams, error in
      if let error = error {
        NEALog.errorLog(ModuleName + " " + (self?.className() ?? ""), desc: #function + ", error: " + error.localizedDescription)
      } else if let teams = teams {
        self?.teamList = teams
        self?.teamList.sort(by: { team1, team2 in
          (team1.createTime ?? 0) > (team2.createTime ?? 0)
        })
        completion(teams, nil)
      }
    }
  }

  // MARK: NIMTeamManagerDelegate

  public func onTeamAdded(_ team: V2NIMTeam) {
    teamList.insert(NETeam(v2teamInfo: team), at: 0)
    refresh()
  }

  public func onTeamUpdated(_ team: V2NIMTeam) {
    for (i, t) in teamList.enumerated() {
      if t.teamId == team.teamId {
        teamList[i] = NETeam(v2teamInfo: team)
        refresh()
        break
      }
    }
  }

  public func onTeamRemoved(_ team: V2NIMTeam) {
    for (i, t) in teamList.enumerated() {
      if t.teamId == team.teamId {
        teamList.remove(at: i)
        refresh()
        break
      }
    }
  }

  // MARK: - V2NIMTeamListener

  public func onTeamCreated(_ team: V2NIMTeam) {
    onTeamAdded(team)
  }

  public func onTeamJoined(_ team: V2NIMTeam) {
    onTeamAdded(team)
  }

  public func onTeamInfoUpdated(_ team: V2NIMTeam) {
    onTeamUpdated(team)
  }

  public func onTeamLeft(_ team: V2NIMTeam, isKicked: Bool) {
    onTeamRemoved(team)
  }

  public func onTeamDismissed(_ team: V2NIMTeam) {
    onTeamRemoved(team)
  }
}
