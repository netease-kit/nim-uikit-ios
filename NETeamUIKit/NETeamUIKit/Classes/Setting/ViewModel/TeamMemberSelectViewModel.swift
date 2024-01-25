//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIMKit
import NIMSDK
import UIKit

public protocol TeamMemberSelectViewModelDelegate: NSObject {
  func didNeedRefresh()
}

class TeamMemberSelectViewModel: NSObject, NIMTeamManagerDelegate {
  let repo = TeamRepo.shared

  var datas = [NESelectTeamMember]()

  var showDatas = [NESelectTeamMember]()

  var teamInfoModel: TeamInfoModel?

  weak var delegate: TeamMemberSelectViewModelDelegate?

  var selectDic = [String: TeamMemberInfoModel]() // key 值为用户 id

  var isRequest = false

  var managerSet = Set<String>()

  override init() {
    super.init()
    NIMSDK.shared().teamManager.add(self)
  }

  deinit {
    NIMSDK.shared().teamManager.remove(self)
  }

  func getTeamInfo(_ teamId: String, _ completion: @escaping (Error?) -> Void) {
    if isRequest == true {
      return
    }
    weak var weakSelf = self
    isRequest = true
    repo.fetchTeamInfo(teamId) { error, teamInfo in
      weakSelf?.isRequest = false
      if error == nil {
        weakSelf?.datas.removeAll()
        weakSelf?.showDatas.removeAll()
      }
      weakSelf?.teamInfoModel = teamInfo
      weakSelf?.getData()
      completion(error)
    }
  }

  func getData() {
    var temFilters = Set<String>()
    selectDic.forEach { (key: String, value: TeamMemberInfoModel) in
      temFilters.insert(key)
    }
    managerSet.removeAll()

    teamInfoModel?.users.forEach { [weak self] userModel in
      if let uid = userModel.nimUser?.userId {
        temFilters.remove(uid)
        if uid == IMKitClient.instance.imAccid() {
          return
        }
        if uid == self?.teamInfoModel?.team?.owner {
          return
        }
        if userModel.teamMember?.type == .manager {
          self?.managerSet.insert(uid)
          self?.selectDic.removeValue(forKey: uid)
          return
        }
      }
      let selectMember = NESelectTeamMember()
      selectMember.member = userModel
      self?.datas.append(selectMember)
      self?.showDatas.append(selectMember)
    }
    temFilters.forEach { uid in
      selectDic.removeValue(forKey: uid)
    }
    datas.forEach { member in
      if let accid = member.member?.nimUser?.userId {
        if selectDic.contains(where: { (key: String, value: TeamMemberInfoModel) in
          key == accid
        }) {
          member.isSelected = true
        }
      }
    }
  }

  func searchAllData(_ searchText: String) -> [NESelectTeamMember] {
    let result = datas.filter { findContainStr(searchText, $0) }
    return result
  }

  func searchShowData(_ searchText: String) -> [NESelectTeamMember] {
    let result = showDatas.filter { findContainStr(searchText, $0) }
    return result
  }

  func findContainStr(_ text: String, _ selectModel: NESelectTeamMember) -> Bool {
    if let uid = selectModel.member?.nimUser?.userId, uid.contains(text) {
      return true
    } else if let nick = selectModel.member?.nimUser?.userInfo?.nickName, nick.contains(text) {
      return true
    } else if let alias = selectModel.member?.nimUser?.alias, alias.contains(text) {
      return true
    } else if let tNick = selectModel.member?.teamMember?.nickname, tNick.contains(text) {
      return true
    }
    return false
  }

  func onTeamMemberChanged(_ team: NIMTeam) {
    guard let tid = teamInfoModel?.team?.teamId else {
      return
    }
    if tid != team.teamId {
      return
    }
    getTeamInfo(tid) { [weak self] error in
      if error == nil {
        self?.delegate?.didNeedRefresh()
      }
    }
  }
}
