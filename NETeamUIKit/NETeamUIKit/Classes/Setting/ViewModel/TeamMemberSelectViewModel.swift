//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import NIMSDK
import UIKit

public protocol TeamMemberSelectViewModelDelegate: NSObject {
  func didNeedRefresh()
}

class TeamMemberSelectViewModel: NSObject, NIMTeamManagerDelegate {
  /// 群API单例
  let teamRepo = TeamRepo.shared
  /// 选中成员数据
  var datas = [NESelectTeamMember]()

  var showDatas = [NESelectTeamMember]()
  /// 群信息
  var teamInfoModel: NETeamInfoModel?
  /// 代理
  weak var delegate: TeamMemberSelectViewModelDelegate?
  /// 当前选中的数据
  var selectDic = [String: NETeamMemberInfoModel]() // key 值为用户 id
  /// 是否正在发送请求
  var isRequest = false
  /// 管理员account id 存放
  var managerSet = Set<String>()

  override init() {
    super.init()
    NIMSDK.shared().teamManager.add(self)
  }

  deinit {
    NIMSDK.shared().teamManager.remove(self)
  }

  /// 群信息(包含群成员)
  /// - Parameter teamId: 群id
  /// - Parameter completion: 完成回调
  func getTeamInfo(_ teamId: String, _ completion: @escaping (Error?) -> Void) {
    if isRequest == true {
      return
    }
    weak var weakSelf = self
    isRequest = true
    teamRepo.getTeamWithMembers(teamId, .TEAM_MEMBER_ROLE_QUERY_TYPE_ALL) { error, teamInfo in
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

  /// 获取选择器数据
  func getData() {
    var temFilters = Set<String>()
    for (key, _) in selectDic {
      temFilters.insert(key)
    }
    managerSet.removeAll()

    teamInfoModel?.users.forEach { [weak self] userModel in
      if let uid = userModel.nimUser?.user?.accountId {
        temFilters.remove(uid)
        if uid == IMKitClient.instance.account() {
          return
        }
        if uid == self?.teamInfoModel?.team?.ownerAccountId {
          return
        }
        if userModel.teamMember?.memberRole == .TEAM_MEMBER_ROLE_MANAGER {
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
    for uid in temFilters {
      selectDic.removeValue(forKey: uid)
    }
    for member in datas {
      if let accid = member.member?.nimUser?.user?.accountId {
        if selectDic.contains(where: { (key: String, value: NETeamMemberInfoModel) in
          key == accid
        }) {
          member.isSelected = true
        }
      }
    }
  }

  /// 搜索所有数据
  /// - Parameter searchText: 搜索关键字
  func searchAllData(_ searchText: String) -> [NESelectTeamMember] {
    let result = datas.filter { findContainStr(searchText, $0) }
    return result
  }

  /// 所有展示数据
  /// - Parameter searchText: 搜索关键字
  func searchShowData(_ searchText: String) -> [NESelectTeamMember] {
    let result = showDatas.filter { findContainStr(searchText, $0) }
    return result
  }

  /// 判断选择器对象是否包含搜索字段
  func findContainStr(_ text: String, _ selectModel: NESelectTeamMember) -> Bool {
    if let uid = selectModel.member?.nimUser?.user?.accountId, uid.contains(text) {
      return true
    } else if let nick = selectModel.member?.nimUser?.user?.name, nick.contains(text) {
      return true
    } else if let alias = selectModel.member?.nimUser?.friend?.alias, alias.contains(text) {
      return true
    } else if let tNick = selectModel.member?.teamMember?.teamNick, tNick.contains(text) {
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
