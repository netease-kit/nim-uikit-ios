//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import NIMSDK
import UIKit

protocol TeamMembersViewModelDelegate: NSObject {
  func didNeedRefreshUI()
}

class TeamMembersViewModel: NSObject, NETeamListener, NEConversationListener, NETeamMemberCacheListener, NEEventListener {
  /// 是否正在请求数据
  public var isRequest = false
  /// 群id
  var teamId: String?

  weak var delegate: TeamMembersViewModelDelegate?

  var datas = [NETeamMemberInfoModel]()

  /// 搜索结果数据
  public var searchDatas = [NETeamMemberInfoModel]()

  let teamRepo = TeamRepo.shared

  public var currentMember: V2NIMTeamMember?

  /// 在线状态记录
  var onLineEventDic = [String: NIMSubscribeEvent]()

  override init() {
    super.init()
    teamRepo.addTeamListener(self)
    ConversationRepo.shared.addConversationListener(self)
    NETeamMemberCache.shared.addTeamCacheListener(self)
    if IMKitConfigCenter.shared.onlineStatusEnable {
      EventSubscribeRepo.shared.addListener(self)
    }
  }

  deinit {
    teamRepo.removeTeamListener(self)
    ConversationRepo.shared.removeConversationListener(self)
    NETeamMemberCache.shared.removeTeamCacheListener(self)
    if IMKitConfigCenter.shared.onlineStatusEnable {
      EventSubscribeRepo.shared.removeListener(self)
    }
  }

  /// 获取群成员信息
  /// - Parameter teamId: 群id
  /// - Parameter completion: 完成回调
  func getMemberInfo(_ teamId: String, _ completion: @escaping (NSError?) -> Void) {
    weak var weakSelf = self
    teamRepo.getTeamMember(teamId, .TEAM_TYPE_NORMAL, IMKitClient.instance.account()) { member, error in
      weakSelf?.currentMember = member
      completion(error)
    }
  }

  /// 移除群成员
  /// - Parameter teamdId: 群id
  /// - Parameter uids: 用户id
  func removeTeamMember(_ teamdId: String, _ uids: [String], _ completion: @escaping (NSError?) -> Void) {
    teamRepo.removeTeamMembers(teamdId, .TEAM_TYPE_NORMAL, uids) { error in
      completion(error as NSError?)
    }
  }

  /// 设置成员数据
  /// - Parameter memberDatas: 成员数据
  func setShowDatas(_ memberDatas: [NETeamMemberInfoModel]?) {
    var owner: NETeamMemberInfoModel?
    var managers = [NETeamMemberInfoModel]()
    var normalMembers = [NETeamMemberInfoModel]()

    memberDatas?.forEach { model in
      if model.teamMember?.memberRole == .TEAM_MEMBER_ROLE_OWNER {
        owner = model
      } else if model.teamMember?.memberRole == .TEAM_MEMBER_ROLE_MANAGER {
        managers.append(model)
      } else {
        normalMembers.append(model)
      }
    }

    datas.removeAll()
    if let findOwner = owner {
      datas.append(findOwner)
    }
    // managers 根据 时间排序 排序
    managers.sort { model1, model2 in
      if let time1 = model1.teamMember?.joinTime, let time2 = model2.teamMember?.joinTime {
        return time2 > time1
      }
      return false
    }
    // normalMembers 根据 时间排序 排序
    normalMembers.sort { model1, model2 in
      if let time1 = model1.teamMember?.joinTime, let time2 = model2.teamMember?.joinTime {
        return time2 > time1
      }
      return false
    }
    datas.append(contentsOf: managers)
    datas.append(contentsOf: normalMembers)
    delegate?.didNeedRefreshUI()
  }

  /// 移除成员数据(UI数据源)
  /// - Parameter model: 成员数据
  func removeModel(_ model: NETeamMemberInfoModel?) {
    guard let rmModel = model else {
      return
    }
    datas.removeAll(where: { model in
      if let rmUid = rmModel.nimUser?.user?.accountId, let uid = model.nimUser?.user?.accountId {
        if rmUid == uid {
          return true
        }
      }
      return false
    })
  }

  /// 群成员信息更新
  /// - Parameter teamMembers: 群成员信息
  func onTeamMemberInfoUpdated(_ teamMembers: [V2NIMTeamMember]) {}

  /// 群成员离开
  /// - Parameter teamMembers: 群成员信息
  func onTeamMemberLeft(_ teamMembers: [V2NIMTeamMember]) {
    removeSearchData(teamMembers)
  }

  /// 判断离开用户是不是当前搜索展示用户
  /// - Parameter teamMembers: 群成员信息
  public func removeSearchData(_ teamMembers: [V2NIMTeamMember]) {
    if searchDatas.count <= 0 {
      return
    }
    var memberSet = Set<String>()
    for member in teamMembers {
      if let tid = teamId, tid == member.teamId {
        memberSet.insert(member.accountId)
      }
    }

    if memberSet.count <= 0 {
      return
    }
    searchDatas.removeAll { model in
      if let accid = model.teamMember?.accountId, memberSet.contains(accid) {
        return true
      }
      return false
    }
  }

  /// 群成员加入
  /// - Parameter teamMembers: 群成员信息
  func onTeamMemberJoined(_ teamMembers: [V2NIMTeamMember]) {}

  /// 群成员被踢
  /// - Parameter operatorAccountId: 操作者id
  /// - Parameter teamMembers: 群成员信息
  func onTeamMemberKicked(_ operatorAccountId: String, teamMembers: [V2NIMTeamMember]) {
    removeSearchData(teamMembers)
  }

  /// 群成员信息更新统一处理方法
  /// - Parameter teamMembers: 群成员信息
  func changeMembers(_ teamMembers: [V2NIMTeamMember]) {
    guard let tid = teamId else {
      return
    }
    var isNeedRefresh = false

    for member in teamMembers {
      if member.teamId == tid {
        isNeedRefresh = true
        break
      }
    }

    if isNeedRefresh == true {
      getTeamInfo(tid) { model, error in
        if error == nil {
          self.delegate?.didNeedRefreshUI()
        }
      }
    }
  }

  /// 获取群信息(包含群成员)
  /// - Parameter teamId: 群id
  /// - Parameter completion: 完成回调
  func getTeamInfo(_ teamId: String, _ completion: @escaping (NETeamInfoModel?, NSError?) -> Void) {
    weak var weakSelf = self
    if isRequest == true {
      return
    }
    isRequest = true

    getMemberInfo(teamId) { error in
      if let err = error {
        weakSelf?.isRequest = false
        completion(nil, err)
      } else {
        weakSelf?.teamRepo.getTeamInfo(teamId) { team, error in
          if let err = error {
            weakSelf?.isRequest = false
            completion(nil, err)
          } else {
            let model = NETeamInfoModel()
            model.team = team
            weakSelf?.getTeamMembers(model, .TEAM_MEMBER_ROLE_QUERY_TYPE_ALL) { error, teamInfo in
              weakSelf?.isRequest = false
              if let err = error {
                completion(nil, err)
              } else {
                if let datas = teamInfo?.users {
                  weakSelf?.setShowDatas(datas)
                }
                completion(teamInfo, error)
              }
            }
          }
        }
      }
    }
  }

  /// 获取群成员
  /// - Parameter queryType:  查询类型
  /// - Parameter teamModel：群信息对象
  /// - Parameter completion:  完成后的回调
  private func getTeamMembers(_ teamInfo: NETeamInfoModel,
                              _ queryType: V2NIMTeamMemberRoleQueryType,
                              _ completion: @escaping (NSError?, NETeamInfoModel?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamid:\(teamInfo.team?.teamId ?? "")")
    guard let teamId = teamInfo.team?.teamId else {
      return
    }

    weak var weakSelf = self

    if let members = NETeamMemberCache.shared.getTeamMemberCache(teamId), teamInfo.team?.memberCount == members.count {
      teamInfo.users = members
      completion(nil, teamInfo)
      NEALog.infoLog(weakSelf?.className() ?? "", desc: "load team member from cache success.")
      return
    }

    NETeamMemberCache.shared.getAllTeamMemberInfos(teamId, queryType) { error, teamInfo in
      if let err = error {
        NEALog.infoLog(ModuleName + " " + (weakSelf?.className() ?? ""), desc: "CALLBACK fetchTeamMember \(String(describing: error))")
        completion(err, nil)
      } else {
        if let members = teamInfo?.users, members.count > 0 {
          NEALog.infoLog(weakSelf?.className() ?? "", desc: "set team member cache success.")
          NETeamMemberCache.shared.setCacheMembers(teamId, members)
        }
        completion(error, teamInfo)
      }
    }
  }

  /// 订阅群成员在线状态
  ///  - Parameter members:  成员列表
  func subcribeMembers(_ members: [NETeamMemberInfoModel], _ completion: @escaping (NSError?) -> Void) {
    var accounts = [String]()
    for model in members {
      if let accountId = model.teamMember?.accountId {
        accounts.append(accountId)
      }
    }
    NEEventSubscribeManager.shared.subscribeUsersOnlineState(accounts) { error in
      completion(error)
    }
  }

  /// 取消订阅群成员
  func unSubcribeMembers(_ members: [NETeamMemberInfoModel], _ completion: @escaping (NSError?) -> Void) {
    var accounts = [String]()
    for model in members {
      if let accountId = model.teamMember?.accountId {
        accounts.append(accountId)
      }
    }
    NEEventSubscribeManager.shared.unSubscribeUsersOnlineState(accounts) { error in
      completion(error)
    }
  }

  /// 订阅状态变更回调
  /// - Parameter event: 订阅事件
  func onRecvSubscribeEvents(_ event: [NIMSubscribeEvent]) {
    NEALog.infoLog(className(), desc: #function + " event count : \(event.count)")
    for e in event {
      print("event from : \(e.from ?? "") event value : \(e.value) event type : \(e.type)")
      if e.type == NIMSubscribeSystemEventType.online.rawValue, let acountId = e.from {
        onLineEventDic[acountId] = e
      }
    }
    delegate?.didNeedRefreshUI()
  }

  /// 缓存数据变更回调
  func memberCacheDidChange() {
    NEALog.infoLog(className(), desc: #function + " memberCacheDidChange")
    guard let tid = teamId else {
      return
    }

    weak var weakSelf = self
    if let members = NETeamMemberCache.shared.getTeamMemberCache(tid) {
      getMemberInfo(tid) { error in
        if error == nil {
          weakSelf?.setShowDatas(members)
          weakSelf?.delegate?.didNeedRefreshUI()
        } else {
          NEALog.infoLog(weakSelf?.className() ?? "", desc: #function + " getMemberInfo error:\(String(describing: error))")
        }
      }
    } else {
      getTeamInfo(tid) { teamInfo, error in
        weakSelf?.delegate?.didNeedRefreshUI()
      }
    }
  }
}
