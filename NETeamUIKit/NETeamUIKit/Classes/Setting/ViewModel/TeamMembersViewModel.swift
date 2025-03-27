//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NEChatUIKit
import NECoreIM2Kit
import NIMSDK
import UIKit

@objc
public protocol TeamMembersViewModelDelegate: NSObjectProtocol {
  func didNeedRefreshUI()
}

class TeamMembersViewModel: NSObject, NETeamListener, NETeamChatUserCacheListener, NEEventListener {
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

  override public init() {
    super.init()
    teamRepo.addTeamListener(self)
    NETeamUserManager.shared.addListener(self)
    if IMKitConfigCenter.shared.onlineStatusEnable {
      EventSubscribeRepo.shared.addListener(self)
    }
    NotificationCenter.default.addObserver(self, selector: #selector(didTapHeader), name: NENotificationName.didTapHeader, object: nil)
  }

  deinit {
    teamRepo.removeTeamListener(self)
    NETeamUserManager.shared.removeListener(self)
    if IMKitConfigCenter.shared.onlineStatusEnable {
      EventSubscribeRepo.shared.removeListener(self)
    }
  }

  /// 点击群成员头像
  /// 拉取最新用户信息后刷新群成员信息
  /// - Parameter noti: 通知对象
  @objc open func didTapHeader(_ noti: Notification) {
    if let user = noti.object as? NEUserWithFriend,
       let accid = user.user?.accountId {
      if NETeamUserManager.shared.isCurrentMember(accid) {
        var isDidFind = false
        for model in datas {
          if let accountId = model.nimUser?.user?.accountId, accountId == accid {
            model.nimUser = user
            isDidFind = true
          }
        }
        for model in searchDatas {
          if let accountId = model.nimUser?.user?.accountId, accountId == accid {
            model.nimUser = user
            isDidFind = true
          }
        }
        if isDidFind == true {
          delegate?.didNeedRefreshUI()
        }
      }
    }
  }

  /// 获取群成员信息
  /// - Parameter teamId: 群id
  /// - Parameter completion: 完成回调
  open func getMemberInfo(_ teamId: String, _ completion: @escaping (NSError?) -> Void) {
    weak var weakSelf = self
    teamRepo.getTeamMember(teamId, .TEAM_TYPE_NORMAL, IMKitClient.instance.account()) { member, error in
      weakSelf?.currentMember = member
      completion(error)
    }
  }

  /// 移除群成员
  /// - Parameter teamdId: 群id
  /// - Parameter uids: 用户id
  open func removeTeamMember(_ teamdId: String, _ uids: [String], _ completion: @escaping (NSError?) -> Void) {
    teamRepo.removeTeamMembers(teamdId, .TEAM_TYPE_NORMAL, uids) { error in
      completion(error as NSError?)
    }
  }

  /// 设置成员数据
  /// - Parameter memberDatas: 成员数据
  open func setShowDatas(_ memberDatas: [NETeamMemberInfoModel]?) {
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
  open func removeModel(_ rmUids: [String]) {
    datas.removeAll(where: { model in
      if let uid = model.nimUser?.user?.accountId {
        if rmUids.contains(uid) {
          return true
        }
      }
      return false
    })
    delegate?.didNeedRefreshUI()
  }

  /// 群成员信息更新
  /// - Parameter teamMembers: 群成员信息
  func onTeamMemberInfoUpdated(_ teamMembers: [V2NIMTeamMember]) {}

  /// 群成员离开
  /// - Parameter teamMembers: 群成员信息
  func onTeamMemberLeft(_ teamMembers: [V2NIMTeamMember]) {
    removeSearchData(teamMembers)
    let uids = teamMembers.map(\.accountId)
    removeModel(uids)
  }

  /// 判断离开用户是不是当前搜索展示用户
  /// - Parameter teamMembers: 群成员信息
  open func removeSearchData(_ teamMembers: [V2NIMTeamMember]) {
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
    delegate?.didNeedRefreshUI()
  }

  /// 群成员加入
  /// - Parameter teamMembers: 群成员信息
  func onTeamMemberJoined(_ teamMembers: [V2NIMTeamMember]) {}

  /// 群成员被踢
  /// - Parameter operatorAccountId: 操作者id
  /// - Parameter teamMembers: 群成员信息
  func onTeamMemberKicked(_ operatorAccountId: String, teamMembers: [V2NIMTeamMember]) {
    removeSearchData(teamMembers)
    let uids = teamMembers.map(\.accountId)
    removeModel(uids)
  }

  /// 群成员信息更新统一处理方法
  /// - Parameter teamMembers: 群成员信息
  open func changeMembers(_ teamMembers: [V2NIMTeamMember]) {
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
  open func getTeamInfo(_ teamId: String, _ completion: @escaping (NETeamInfoModel?, NSError?) -> Void) {
    weak var weakSelf = self

    if let team = NETeamUserManager.shared.getTeamInfo(),
       let teamMembers = NETeamUserManager.shared.getAllTeamMemberModels() {
      let model = NETeamInfoModel()
      model.team = team
      model.users = teamMembers
      weakSelf?.setShowDatas(model.users)
      weakSelf?.currentMember = NETeamUserManager.shared.getTeamMemberInfo(IMKitClient.instance.account())
      completion(model, nil)
      return
    }

    if isRequest == true {
      return
    }
    isRequest = true

    NETeamUserManager.shared.getAllTeamMembers(teamId, .TEAM_MEMBER_ROLE_QUERY_TYPE_ALL) { _ in
      weakSelf?.isRequest = false
      let team = NETeamUserManager.shared.getTeamInfo()
      if let teamMembers = NETeamUserManager.shared.getAllTeamMemberModels() {
        let model = NETeamInfoModel()
        model.team = team
        model.users = teamMembers
        weakSelf?.setShowDatas(model.users)
        weakSelf?.currentMember = NETeamUserManager.shared.getTeamMemberInfo(IMKitClient.instance.account())
        completion(model, nil)
      } else {
        completion(nil, nil)
      }
    }
  }

  /// 获取群成员
  /// - Parameter queryType:  查询类型
  /// - Parameter teamModel：群信息对象
  /// - Parameter completion:  完成后的回调
  open func getTeamMembers(_ teamInfo: NETeamInfoModel,
                           _ queryType: V2NIMTeamMemberRoleQueryType,
                           _ completion: @escaping (NSError?, NETeamInfoModel?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamid:\(teamInfo.team?.teamId ?? "")")
    if let members = NETeamUserManager.shared.getAllTeamMemberModels(), teamInfo.team?.memberCount == members.count {
      teamInfo.users = members
      completion(nil, teamInfo)
      NEALog.infoLog(className(), desc: "load team member from cache success.")
    }
  }

  /// 订阅群成员在线状态
  ///  - Parameter members:  成员列表
  open func subcribeMembers(_ members: [NETeamMemberInfoModel], _ completion: @escaping (NSError?) -> Void) {
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
  open func unSubcribeMembers(_ members: [NETeamMemberInfoModel], _ completion: @escaping (NSError?) -> Void) {
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
  open func onRecvSubscribeEvents(_ event: [NIMSubscribeEvent]) {
    NEALog.infoLog(className(), desc: #function + " event count : \(event.count)")
    for e in event {
      print("event from : \(e.from ?? "") event value : \(e.value) event type : \(e.type)")
      if e.type == NIMSubscribeSystemEventType.online.rawValue, let acountId = e.from {
        onLineEventDic[acountId] = e
      }
    }
    delegate?.didNeedRefreshUI()
  }

  open func onTeamMemberUpdate(_ accountId: String) {
    NEALog.infoLog(className(), desc: #function + " memberCacheDidChange")
    guard let tid = teamId else {
      return
    }

    weak var weakSelf = self
    if let members = NETeamUserManager.shared.getAllTeamMemberModels() {
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
