// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIM2Kit
import NIMSDK

/// 群聊缓存代理，包含群信息更新和群成员更新
/// 群成员更新包含自己
@objc
public protocol NETeamChatUserCacheListener: NETeamListener {
  /// 群信息更新
  /// - Parameter teamId: 群 id
  @objc optional func onTeamInfoUpdate(_ teamId: String)

  /// 群成员更新
  /// - Parameter accountId: 用户 id
  @objc optional func onTeamMemberUpdate(_ accountId: String)
}

/// 群聊缓存类，缓存群成员信息和非好友用户信息
@objcMembers
public class NETeamUserManager: NSObject {
  public static let shared = NETeamUserManager()
  let teamRepo = TeamRepo.shared
  let contactRepo = ContactRepo.shared

  /// 多代理容器
  private let multiDelegate = MultiDelegate<NETeamChatUserCacheListener>(strongReferences: false)

  // 群ID
  private var tid: String?

  // 当前群信息,可空
  private var currentTeam: V2NIMTeam?

  // 群成员信息
  private var teamMemberCache = [String: V2NIMTeamMember]()

  // 非好友的用户信息
  private var userInfoCache = [String: NEUserWithFriend]()

  // 是否已经拉取了所有群成员
  private var haveLoadAllMembers = false

  override private init() {
    super.init()
    IMKitClient.instance.addLoginListener(self)
    teamRepo.addTeamListener(self)
    contactRepo.addContactListener(self)
  }

  deinit {
    IMKitClient.instance.removeLoginListener(self)
    teamRepo.removeTeamListener(self)
    contactRepo.removeContactListener(self)
  }

  /// 添加代理
  /// - Parameter listener: 代理
  public func addListener(_ listener: NETeamChatUserCacheListener) {
    multiDelegate.addDelegate(listener)
  }

  /// 移除代理
  /// - Parameter listener: 代理
  public func removeListener(_ listener: NETeamChatUserCacheListener) {
    multiDelegate.removeDelegate(listener)
  }

  /// 加载缓存
  /// - Parameter teamId: 群 id
  public func loadData(_ teamId: String) {
    removeAllTeamInfo()
    tid = teamId

    // 获取群信息
    teamRepo.getTeamInfo(teamId) { [weak self] team, error in
      self?.updateTeamInfo(team)
    }

    // 获取自己的群成员信息
    teamRepo.getTeamMember(teamId, .TEAM_TYPE_NORMAL, IMKitClient.instance.account()) { [weak self] teamMember, error in
      self?.updateTeamMemberInfo(teamMember)
    }
  }

  /// 更新当前群信息
  /// - Parameter team: 群信息
  public func updateTeamInfo(_ team: V2NIMTeam?) {
    guard let teamId = team?.teamId, teamId == tid else { return }
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamId: \(teamId)")
    currentTeam = team

    multiDelegate |> { delegate in
      delegate.onTeamInfoUpdate?(teamId)
    }
  }

  /// 更新群成员信息
  /// - Parameter teamMember: 群成员信息
  public func updateTeamMemberInfo(_ teamMember: V2NIMTeamMember?) {
    guard let teamMember = teamMember, teamMember.teamId == tid else {
      return
    }

    let accid = teamMember.accountId
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", accountId:\(accid)")
    teamMemberCache[accid] = teamMember

    multiDelegate |> { delegate in
      delegate.onTeamMemberUpdate?(accid)
    }
  }

  // 添加（更新）非好友信息
  public func updateUserInfo(user: V2NIMUser?) {
    guard let accid = user?.accountId else { return }
    userInfoCache[accid]?.user = user

    multiDelegate |> { delegate in
      delegate.onTeamMemberUpdate?(accid)
    }
  }

  // 添加（更新）非好友信息
  public func updateUserInfo(userWithFriend: NEUserWithFriend?) {
    guard let accid = userWithFriend?.user?.accountId else { return }
    userInfoCache[accid] = userWithFriend

    multiDelegate |> { delegate in
      delegate.onTeamMemberUpdate?(accid)
    }
  }

  /// 获取缓存的群聊信息
  public func getTeamInfo() -> V2NIMTeam? {
    currentTeam
  }

  /// 获取缓存的群成员信息
  public func getTeamMemberInfo(_ accountId: String) -> V2NIMTeamMember? {
    teamMemberCache[accountId]
  }

  /// 获取缓存的所有群成员信息
  public func getAllTeamMembers() -> [V2NIMTeamMember]? {
    if haveLoadAllMembers {
      var teamMemberInfoModels = [NETeamMemberInfoModel]()
      for (accid, member) in teamMemberCache {
        let model = NETeamMemberInfoModel()
        model.teamMember = member
        model.nimUser = NEFriendUserCache.shared.getFriendInfo(accid) ?? userInfoCache[accid]
        teamMemberInfoModels.append(model)
      }

      return teamMemberCache.values.map { $0 }
    }
    return nil
  }

  /// 获取缓存的所有群成员信息
  public func getAllTeamMemberModels() -> [NETeamMemberInfoModel]? {
    if haveLoadAllMembers {
      var teamMemberInfoModels = [NETeamMemberInfoModel]()
      for (accid, member) in teamMemberCache {
        let model = NETeamMemberInfoModel()
        model.teamMember = member
        model.nimUser = NEFriendUserCache.shared.getFriendInfo(accid) ?? userInfoCache[accid]
        teamMemberInfoModels.append(model)
      }

      return teamMemberInfoModels.isEmpty ? nil : teamMemberInfoModels
    }
    return nil
  }

  /// 获取缓存的非好友用户信息
  public func getUserInfo(_ accountId: String) -> NEUserWithFriend? {
    userInfoCache[accountId]
  }

  /// 删除群成员信息缓存
  public func removeTeamMemberInfo(_ accountId: String) {
    if let _ = teamMemberCache[accountId] {
      teamMemberCache.removeValue(forKey: accountId)
    }
  }

  /// 删除所有信息缓存
  public func removeAllTeamInfo() {
    tid = nil
    currentTeam = nil
    userInfoCache.removeAll()
    teamMemberCache.removeAll()
    haveLoadAllMembers = false
  }

  /// 获取缓存群成员名字，team: 备注 > 群昵称 > 昵称 > ID
  public func getShowName(_ accountId: String,
                          _ showAlias: Bool = true) -> String {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", userId: " + accountId)

    // 数字人直接返回
    if let aiUser: NEUserWithFriend = NEAIUserManager.shared.getAIUserById(accountId) {
      return aiUser.showName() ?? accountId
    }

    // 非好友缓存
    var fullName = userInfoCache[accountId]?.showName() ?? NEP2PChatUserCache.shared.getShowName(accountId)

    // 好友缓存
    if NEFriendUserCache.shared.isFriend(accountId) {
      fullName = NEFriendUserCache.shared.getShowName(accountId, showAlias)
    }

    // 群成员缓存
    if let teamMember = teamMemberCache[accountId] {
      if teamMember.accountId == accountId {
        if let teamNick = teamMember.teamNick, !teamNick.isEmpty {
          fullName = teamNick
        }

        if showAlias,
           let friend = NEFriendUserCache.shared.getFriendInfo(accountId),
           let alias = friend.friend?.alias,
           !alias.isEmpty {
          fullName = alias
        }

        return fullName
      }
    }
    return fullName
  }

  //    获取群成员信息和用户信息
  public func getTeamMembers(accountIds: [String], _ completion: @escaping () -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamId: \(String(describing: tid))")

    var loadUserIds = Set<String>() // 需要查询用户信息的ID
    var loadMemberIds = Set<String>() // 需要查询群成员信息的ID
    let group = DispatchGroup()

    for userId in accountIds {
      if !NEAIUserManager.shared.isAIUser(userId),
         !NEFriendUserCache.shared.isFriend(userId),
         userInfoCache[userId] == nil {
        loadUserIds.insert(userId)
      }

      if teamMemberCache[userId] == nil, !NEAIUserManager.shared.isAIUser(userId) {
        loadMemberIds.insert(userId)
      }
    }

    // 先查询用户信息(陌生人)
    if !loadUserIds.isEmpty {
      group.enter()
      ContactRepo.shared.getUserListFromCloud(accountIds: Array(loadUserIds)) { [weak self] users, error in
        users?.forEach { self?.updateUserInfo(userWithFriend: $0) }
        group.leave()
      }
    }

    guard let tid = tid else {
      NEALog.errorLog(ModuleName + " " + className(), desc: #function + ", teamId is nil")
      completion()
      return
    }

    // 再查询群成员信息
    if !loadMemberIds.isEmpty {
      group.enter()
      TeamRepo.shared.getTeamMemberListByIds(tid, .TEAM_TYPE_NORMAL, Array(loadMemberIds)) { [weak self] teamMembers, error in
        for teamMember in teamMembers ?? [] {
          if teamMember.inTeam {
            self?.updateTeamMemberInfo(teamMember)
          }
        }

        group.leave()
      }
    }

    group.notify(queue: .main) {
      completion()
    }
  }

  /// 获取所有群成员信息和用户信息
  /// - Parameter teamId:  群id
  /// - Parameter queryType:  查询类型
  /// - Parameter completion:  完成后的回调
  public func getAllTeamMembers(_ teamId: String,
                                _ queryType: V2NIMTeamMemberRoleQueryType = .TEAM_MEMBER_ROLE_QUERY_TYPE_ALL,
                                _ completion: @escaping ([NEUserWithFriend]) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamid:\(teamId)")
    var memberLists = [V2NIMTeamMember]()
    weak var weakSelf = self
    getAllTeamMemberWithMaxLimit(teamId, nil, &memberLists, queryType) { members, error in
      if let err = error {
        NEALog.errorLog(ModuleName + " " + NETeamUserManager.className(), desc: #function + ", err:\(err.localizedDescription)")
      } else {
        if let teamMembers = members {
          var notFriendMembers = [String]()
          for member in teamMembers {
            weakSelf?.teamMemberCache[member.accountId] = member
            if !NEFriendUserCache.shared.isFriend(member.accountId) {
              notFriendMembers.append(member.accountId)
            }
          }

          weakSelf?.splitMembers(notFriendMembers, 150, completion)
        }
      }
    }
  }

  /// 获取群成员(使用最大分页参数，防止触发频控)
  /// - Parameter teamId:  群ID
  /// - Parameter completion:  完成回调
  public func getAllTeamMemberWithMaxLimit(_ teamId: String, _ nextToken: String? = nil, _ memberList: inout [V2NIMTeamMember], _ queryType: V2NIMTeamMemberRoleQueryType, _ completion: @escaping ([V2NIMTeamMember]?, NSError?) -> Void) {
    NEALog.infoLog(className(), desc: #function + " teamId : \(teamId)")
    let option = V2NIMTeamMemberQueryOption()
    option.direction = .QUERY_DIRECTION_ASC
    option.limit = 1000
    option.onlyChatBanned = false
    option.roleQueryType = queryType
    if let token = nextToken {
      option.nextToken = token
    } else {
      option.nextToken = ""
    }
    var temMemberLists = memberList
    teamRepo.getTeamMemberList(teamId, .TEAM_TYPE_NORMAL, option) { [weak self] result, error in
      if let err = error {
        completion(nil, err)
      } else {
        if let members = result?.memberList {
          temMemberLists.append(contentsOf: members)
        }
        if let finished = result?.finished {
          if finished == true {
            completion(temMemberLists, nil)
          } else {
            self?.getAllTeamMemberWithMaxLimit(teamId, result?.nextToken, &temMemberLists, queryType, completion)
          }
        }
      }
    }
  }

  /// 分页查询群成员信息
  /// - Parameter members:          要查询的群成员列表
  /// - Parameter model :           群信息
  /// - Parameter maxSizeByPage:    单页最大查询数量
  /// - Parameter completion:       完成后的回调
  private func splitMembers(_ members: [String],
                            _ maxSizeByPage: Int = 150,
                            _ completion: @escaping ([NEUserWithFriend]) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", members.count:\(members.count)")
    var remaind = [[String]]()
    remaind.append(contentsOf: members.chunk(maxSizeByPage))
    let memberUsers = [NEUserWithFriend]()
    fetchTeamMemberUserInfos(&remaind, memberUsers, completion)
  }

  /// 从云信服务器批量获取用户资料
  ///   - Parameter remainUserIds:  用户集合
  ///   - Parameter completion:    成功回调
  private func fetchTeamMemberUserInfos(_ remainUserIds: inout [[String]],
                                        _ memberUsers: [NEUserWithFriend],
                                        _ completion: @escaping ([NEUserWithFriend]) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", remainUserIds.count:\(remainUserIds.count)")
    guard let members = remainUserIds.first else {
      haveLoadAllMembers = true
      completion(memberUsers)
      return
    }

    var temArray = remainUserIds
    var memberUsers = memberUsers
    weak var weakSelf = self

    contactRepo.getUserListFromCloud(accountIds: members) { [weak self] users, v2Error in
      if let err = v2Error {
        NEALog.errorLog(ModuleName + " " + NETeamUserManager.className(), desc: #function + "err:\(err.localizedDescription)")
      } else {
        if let users = users {
          for user in users {
            if let accid = user.user?.accountId {
              self?.userInfoCache[accid] = user
              memberUsers.append(user)
            }
          }
        }
        temArray.removeFirst()
        weakSelf?.fetchTeamMemberUserInfos(&temArray, memberUsers, completion)
      }
    }
  }
}

// MARK: - NEContactListener

extension NETeamUserManager: NEContactListener {
  /// 好友信息缓存更新
  /// - Parameter accountId: 用户 id
  public func onContactChange(_ changeType: NEContactChangeType, _ contacts: [NEUserWithFriend]) {
    for contact in contacts {
      if let accid = contact.user?.accountId {
        // 好友被删除，则信息缓存移至 userInfoCache
        if changeType == .deleteFriend, teamMemberCache[accid] != nil {
          contact.friend = nil
          updateUserInfo(userWithFriend: contact)
          continue
        }

        if userInfoCache[accid] != nil {
          updateUserInfo(user: contact.user)
        } else if teamMemberCache[accid] != nil,
                  NEFriendUserCache.shared.isFriend(accid) {
          multiDelegate |> { delegate in
            delegate.onTeamMemberUpdate?(accid)
          }
        }
      }
    }
  }
}

// MARK: - NETeamListener

extension NETeamUserManager: NETeamListener {
  /// 群组信息更新回调
  /// - Parameter team: 群组对象
  public func onTeamInfoUpdated(_ team: V2NIMTeam) {
    if team.teamId == tid {
      updateTeamInfo(team)
    }
  }

  /// 群组成员加入回调
  /// - Parameter teamMembers: 群成员
  public func onTeamMemberJoined(_ teamMembers: [V2NIMTeamMember]) {
    var notFriendMembers = [String]()
    for member in teamMembers {
      if member.teamId == tid {
        updateTeamMemberInfo(member)
        if !NEFriendUserCache.shared.isFriend(member.accountId) {
          notFriendMembers.append(member.accountId)
        }
      }
    }

    splitMembers(notFriendMembers) { [weak self] userFirends in
      for userFirend in userFirends {
        self?.updateUserInfo(userWithFriend: userFirend)
      }
    }
  }

  /// 群组成员信息变更回调
  /// - Parameter teamMembers: 群成员
  public func onTeamMemberInfoUpdated(_ teamMembers: [V2NIMTeamMember]) {
    for member in teamMembers {
      if member.teamId == tid {
        updateTeamMemberInfo(member)
      }
    }
  }

  /// 群组成员退出回调
  /// - Parameter teamMembers： 群成员列表
  public func onTeamMemberLeft(_ teamMembers: [V2NIMTeamMember]) {
    for member in teamMembers {
      if member.teamId == tid {
        removeTeamMemberInfo(member.accountId)
      }
    }
  }

  /// 群组成员被踢回调
  /// - Parameter operatorAccountId： 操作者用户id
  /// - Parameter teamMembers: 群成员列表
  public func onTeamMemberKicked(_ operatorAccountId: String, teamMembers: [V2NIMTeamMember]) {
    for member in teamMembers {
      if member.teamId == tid {
        removeTeamMemberInfo(member.accountId)
      }
    }
  }
}

// MARK: - NEIMKitClientListener

extension NETeamUserManager: NEIMKitClientListener {
  /// 登录连接状态回调
  /// - Parameter status: 连接状态
  public func onDataSync(_ type: V2NIMDataSyncType, state: V2NIMDataSyncState, error: V2NIMError?) {
    guard let tid = tid else { return }

    // 断网重连后，重新拉取群信息、自己的群成员信息
    if type == .DATA_SYNC_TYPE_TEAM_MEMBER, state == .DATA_SYNC_STATE_COMPLETED {
      // 获取群信息
      teamRepo.getTeamInfo(tid) { [weak self] team, error in
        self?.updateTeamInfo(team)
      }

      // 获取自己的群成员信息
      teamRepo.getTeamMember(tid, .TEAM_TYPE_NORMAL, IMKitClient.instance.account()) { [weak self] teamMember, error in
        self?.updateTeamMemberInfo(teamMember)
      }
    }
  }
}
