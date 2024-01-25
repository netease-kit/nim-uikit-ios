//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

public protocol TeamManagerListViewModelDelegate: NSObject {
  func didNeedReloadData()
}

open class TeamManagerListViewModel: NSObject, NIMTeamManagerDelegate {
  let repo = TeamRepo.shared

  public var currentMember: NIMTeamMember?

  public var managers = [TeamMemberInfoModel]()

  weak var delegate: TeamManagerListViewModelDelegate?

  public var teamId: String?

  override public init() {
    super.init()
    NIMSDK.shared().teamManager.add(self)
    NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: NENotificationName.updateFriendInfo, object: nil)
  }

  deinit {
    NIMSDK.shared().teamManager.remove(self)
  }

  open func getManagerDatas(_ tid: String, _ completion: @escaping (Error?) -> Void) {
    repo.fetchTeamInfo(tid) { [weak self] error, teamInfo in
      if error == nil {
        self?.managers.removeAll()
        teamInfo?.users.forEach { model in
          if model.teamMember?.type == .manager {
            self?.managers.append(model)
          }
        }
        completion(nil)
      } else {
        completion(error)
      }
    }
  }

  open func addTeamManager(_ teamId: String, _ uids: [String], _ completion: @escaping (Error?) -> Void) {
    repo.addTeamManagers(teamId, uids) { error in
      completion(error)
    }
  }

  open func removeTeamManager(_ teamId: String, _ uids: [String], _ completion: @escaping (Error?) -> Void) {
    repo.removeTeamManagers(teamId, uids) { error in
      completion(error)
    }
  }

  open func getCurrentMember(_ teamId: String) {
    currentMember = repo.getMemberInfo(IMKitClient.instance.imAccid(), teamId)
  }

  @objc func refreshData() {
    guard let tid = teamId else {
      return
    }
    getManagerDatas(tid) { [weak self] error in
      if error == nil {
        self?.delegate?.didNeedReloadData()
      }
    }
  }

  public func onTeamMemberChanged(_ team: NIMTeam) {
    guard let tid = teamId else {
      return
    }
    if tid != team.teamId {
      return
    }
    getManagerDatas(tid) { [weak self] error in
      if error != nil {
        self?.delegate?.didNeedReloadData()
      }
    }
  }
}
