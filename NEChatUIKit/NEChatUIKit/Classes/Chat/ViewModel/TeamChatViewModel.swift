// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreText
import Foundation
import NEChatKit
import NECoreIMKit
import NIMSDK

@objc
public protocol TeamChatViewModelDelegate: ChatViewModelDelegate {
  func onTeamRemoved(team: NIMTeam)
  func onTeamUpdate(team: NIMTeam)
  func onTeamMemberUpdate(team: NIMTeam)
}

@objcMembers
open class TeamChatViewModel: ChatViewModel {
  private let className = "TeamChatViewModel"

  override init(session: NIMSession, anchor: NIMMessage?) {
    super.init(session: session, anchor: anchor)
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", sessionId: " + session.sessionId)
    repo.addTeamDelegate(delegate: self)
    getTeamMember()
  }

  open func getTeam(teamId: String) -> NIMTeam? {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", teamId: " + teamId)
    return repo.getTeamInfo(teamId: teamId)
  }

  open func fetchTeamInfo(teamId: String,
                          _ completion: @escaping (NSError?, NIMTeam?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", teamId: " + teamId)
    repo.getTeamInfo(teamId: teamId) { [weak self] error, team in
      if error == nil {
        self?.team = team
      }
      completion(error, team)
    }
  }

//    MARK: NIMTeamManagerDelegate

  open func onTeamRemoved(_ team: NIMTeam) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", teamId: " + (team.teamId ?? "nil"))
    if session.sessionId == team.teamId {
      if let delegate = delegate as? TeamChatViewModelDelegate {
        delegate.onTeamRemoved(team: team)
      }
    }
  }

  open func onTeamUpdated(_ team: NIMTeam) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", teamId: " + (team.teamId ?? "nil"))
    if session.sessionId == team.teamId {
      self.team = team
      if let delegate = delegate as? TeamChatViewModelDelegate {
        delegate.onTeamUpdate(team: team)
      }
    }
  }

  open func onTeamMemberUpdated(_ team: NIMTeam, withMembers memberIDs: [String]?) {
    guard let membersIds = memberIDs else {
      return
    }
    for memberId in membersIds {
      if let user = UserInfoProvider.shared.getUserInfo(userId: memberId) {
        ChatUserCache.updateUserInfo(user)
      }
    }
    if let delegate = delegate as? TeamChatViewModelDelegate {
      delegate.onTeamMemberUpdate(team: team)
    }
  }

  public func getTeamMember() {
    teamMember = getTeamMember(userId: IMKitClient.instance.imAccid(), teamId: session.sessionId)
  }
}
