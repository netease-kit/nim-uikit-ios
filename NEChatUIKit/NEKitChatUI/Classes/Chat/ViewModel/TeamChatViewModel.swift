
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
import CoreText

public protocol TeamChatViewModelDelegate: ChatViewModelDelegate {
  func onTeamRemoved(team: NIMTeam)
  func onTeamUpdate(team: NIMTeam)
}

public class TeamChatViewModel: ChatViewModel, NIMTeamManagerDelegate {
  public var team: NIMTeam?
//    override init(session: NIMSession) {
//        super.init(session: session)
//        repo.addTeamDelegate(delegate: self)
//
//    }

  override init(session: NIMSession, anchor: NIMMessage?) {
    super.init(session: session, anchor: anchor)
    repo.addTeamDelegate(delegate: self)
//        self.session = session
//        self.anchor = anchor
//        super.init()
//        if anchor != nil {
//            isHistoryChat = true
//        }
//        repo.addChatDelegate(delegate: self)
//        repo.addConversationDelegate(delegate: self)
//        repo.addSystemNotiDelegate(delegate: self)
//        repo.addChatExtDelegate(delegate: self)
  }

  public func getTeam(teamId: String) -> NIMTeam? {
    repo.getTeamInfo(teamId: teamId)
  }

  public func fetchTeamInfo(teamId: String,
                            _ completion: @escaping (NSError?, NIMTeam?) -> Void) {
    repo.getTeamInfo(teamId: teamId) { [weak self] error, team in
      if error == nil {
        self?.team = team
      }
      completion(error, team)
    }
  }

//    MARK: NIMTeamManagerDelegate

  public func onTeamRemoved(_ team: NIMTeam) {
    if session.sessionId == team.teamId {
      if let delegate = delegate as? TeamChatViewModelDelegate {
        delegate.onTeamRemoved(team: team)
      }
    }
  }

  public func onTeamUpdated(_ team: NIMTeam) {
    if session.sessionId == team.teamId {
      self.team = team
      if let delegate = delegate as? TeamChatViewModelDelegate {
        delegate.onTeamUpdate(team: team)
      }
    }
  }
}
