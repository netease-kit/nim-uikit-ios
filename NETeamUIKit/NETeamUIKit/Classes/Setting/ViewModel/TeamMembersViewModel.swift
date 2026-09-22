//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NEChatUIKit
import NIMSDK
import UIKit

@objc
public protocol TeamMembersViewModelDelegate: NSObjectProtocol {
  func didNeedRefreshUI()
}

class TeamMembersViewModel: NSObject, NETeamListener, NETeamChatUserCacheListener, NESubscribeListener, AIUserChangeListener {
  /// 是否正在请求数据
  var isRequest = false
  /// 群id
  var teamId: String?

  weak var delegate: TeamMembersViewModelDelegate?

  var datas = [NETeamMemberInfoModel]()

  /// 搜索结果数据
  var searchDatas = [NETeamMemberInfoModel]()
  /// 当前搜索结果对应的主次名称和高亮范围
  private(set) var searchResults = [String: NETeamMemberSearchResult]()
  /// 成员资料是否仍在按批次补齐
  private(set) var isLoadingMembers = false
  private(set) var memberLoadError: NSError?
  private var currentSearchKeyword = ""

  let teamRepo = TeamRepo.shared

  var currentMember: V2NIMTeamMember?

  /// 在线状态记录
  var onLineEventDic = [String: Bool]()

  override init() {
    super.init()
    teamRepo.addTeamListener(self)
    NETeamUserManager.shared.addListener(self)
    NEAIUserManager.shared.addAIUserChangeListener(listener: self)
//    if IMKitConfigCenter.shared.enableOnlineStatus {
//      SubscribeRepo.shared.addListener(self)
//    }
    NotificationCenter.default.addObserver(self, selector: #selector(didTapHeader), name: NENotificationName.didTapHeader, object: nil)
  }

  deinit {
    teamRepo.removeTeamListener(self)
    NETeamUserManager.shared.removeListener(self)
    NEAIUserManager.shared.removeAIUserChangeListener(listener: self)
//    if IMKitConfigCenter.shared.enableOnlineStatus {
//      SubscribeRepo.shared.removeListener(self)
//    }
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
    managers.sort(by: memberOrder)
    // normalMembers 根据 时间排序 排序
    normalMembers.sort(by: memberOrder)
    datas.append(contentsOf: managers)
    datas.append(contentsOf: normalMembers)
    searchData(currentSearchKeyword)
    delegate?.didNeedRefreshUI()
  }

  /// 移除成员数据(UI数据源)
  /// - Parameter model: 成员数据
  open func removeModel(_ rmUids: [String]) {
    datas.removeAll(where: { model in
      if let uid = model.teamMember?.accountId {
        return rmUids.contains(uid)
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
    var isCurrentTeam = false
    for member in teamMembers {
      if let currentTid = teamId, currentTid == member.teamId {
        isCurrentTeam = true
        break
      }
    }

    if isCurrentTeam {
      removeSearchData(teamMembers)
      let uids = teamMembers.map(\.accountId)
      removeModel(uids)
    }
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
    var isCurrentTeam = false
    for member in teamMembers {
      if let currentTid = teamId, currentTid == member.teamId {
        isCurrentTeam = true
        break
      }
    }

    if isCurrentTeam {
      removeSearchData(teamMembers)
      let uids = teamMembers.map(\.accountId)
      removeModel(uids)
    }
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
       team.teamId == teamId,
       let teamMembers = NETeamUserManager.shared.getAllTeamMemberModels() {
      let model = NETeamInfoModel()
      model.team = team
      model.users = teamMembers
      weakSelf?.setShowDatas(model.users)
      weakSelf?.currentMember = NETeamUserManager.shared.getTeamMemberInfo(IMKitClient.instance.account())
      weakSelf?.isLoadingMembers = false
      weakSelf?.memberLoadError = nil
      completion(model, nil)
      return
    }

    if isRequest == true {
      return
    }
    isRequest = true
    isLoadingMembers = true
    memberLoadError = nil

    NETeamUserManager.shared.getAllTeamMembers(
      teamId,
      .TEAM_MEMBER_ROLE_QUERY_TYPE_ALL,
      progress: { [weak self] progress in
        guard let self, progress.teamId == self.teamId else { return }
        self.isLoadingMembers = progress.phase == .loading
        self.memberLoadError = progress.error
        if progress.phase == .loading || progress.phase == .finished {
          self.setShowDatas(progress.members)
        }
        if progress.phase == .failed {
          self.delegate?.didNeedRefreshUI()
        }
      }
    ) { _ in
      weakSelf?.isRequest = false
      let team = NETeamUserManager.shared.getTeamInfo()
      if team?.teamId == teamId,
         let teamMembers = NETeamUserManager.shared.getAllTeamMemberModels() {
        let model = NETeamInfoModel()
        model.team = team
        model.users = teamMembers
        weakSelf?.setShowDatas(model.users)
        weakSelf?.currentMember = NETeamUserManager.shared.getTeamMemberInfo(IMKitClient.instance.account())
        completion(model, nil)
      } else {
        weakSelf?.isLoadingMembers = false
        completion(nil, weakSelf?.memberLoadError)
      }
    }
  }

  /// 使用共享 matcher 过滤成员，并保留基础排序。
  open func searchData(_ keyword: String) -> [NETeamMemberInfoModel] {
    currentSearchKeyword = keyword
    searchResults.removeAll()
    let normalized = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !normalized.isEmpty else {
      searchDatas.removeAll()
      return []
    }
    searchDatas = datas.filter { model in
      let result = NETeamMemberSearchMatcher.result(
        keyword: normalized,
        teamNick: model.teamMember?.teamNick,
        friendAlias: model.nimUser?.friend?.alias,
        userNickname: model.nimUser?.user?.name,
        accountId: model.teamMember?.accountId ?? model.nimUser?.user?.accountId
      )
      if let result, let accountId = model.teamMember?.accountId {
        searchResults[accountId] = result
        return true
      }
      return false
    }
    return searchDatas
  }

  open func searchResult(for model: NETeamMemberInfoModel) -> NETeamMemberSearchResult? {
    guard let accountId = model.teamMember?.accountId else { return nil }
    return searchResults[accountId]
  }

  private func memberOrder(_ left: NETeamMemberInfoModel, _ right: NETeamMemberInfoModel) -> Bool {
    let leftTime = left.teamMember?.joinTime ?? 0
    let rightTime = right.teamMember?.joinTime ?? 0
    if leftTime != rightTime {
      return leftTime < rightTime
    }
    return (left.teamMember?.accountId ?? "") < (right.teamMember?.accountId ?? "")
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
        if NEAIUserManager.shared.isAIUser(accountId) {
          continue
        }

        if let event = NESubscribeManager.shared.getSubscribeStatus(accountId) {
          onLineEventDic[accountId] = NESubscribeManager.isOnline(event)
        } else {
          accounts.append(accountId)
        }
      }
    }
    NESubscribeManager.shared.subscribeUsersOnlineState(accounts) { error in
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
    NESubscribeManager.shared.unSubscribeUsersOnlineState(accounts) { error in
      completion(error)
    }
  }

  /// 用户状态变更
  /// - Parameter data: 用户状态列表
  func onUserStatusChanged(_ data: [V2NIMUserStatus]) {
    NEALog.infoLog(className(), desc: #function + " event count : \(data.count)")
    for d in data {
      onLineEventDic[d.accountId] = NESubscribeManager.isOnline(d)
    }
    delegate?.didNeedRefreshUI()
  }

  func onAIUserChanged(aiUsers: [V2NIMAIUser]) {
    let usersById: [String: NEUserWithFriend] = Dictionary(uniqueKeysWithValues: aiUsers.compactMap { user in
      guard let accountId = user.accountId else { return nil }
      return (accountId, NEUserWithFriend(user: user))
    })
    var didUpdate = false
    for model in datas + searchDatas {
      guard let accountId = model.teamMember?.accountId ?? model.nimUser?.user?.accountId,
            let user = usersById[accountId] else { continue }
      model.nimUser = user
      didUpdate = true
    }
    if didUpdate {
      searchData(currentSearchKeyword)
      delegate?.didNeedRefreshUI()
    }
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
          NEALog.infoLog(TeamMembersViewModel.className(), desc: #function + " getMemberInfo error:\(String(describing: error))")
        }
      }
    } else {
      getTeamInfo(tid) { teamInfo, error in
        weakSelf?.delegate?.didNeedRefreshUI()
      }
    }
  }
}
