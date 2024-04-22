// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIM2Kit
import NIMSDK

public class ChatTeamCache: NSObject {
  public static let shared = ChatTeamCache()
  private var teamInfo: V2NIMTeam?
  private var cacheTeamMemberInfoDic = [String: NETeamMemberInfoModel]()

  override private init() {
    super.init()
  }

  public func updateTeamInfo(_ team: V2NIMTeam?) {
    guard let teamId = team?.teamId else { return }
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamId: \(teamId)")
    teamInfo = team
  }

  public func updateTeamMemberInfo(_ userFriend: NEUserWithFriend?) {
    guard let userId = userFriend?.user?.accountId, !NEFriendUserCache.shared.isFriend(userId) else {
      return
    }

    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", userId:\(userId)")

    if let teamMemberInfo = cacheTeamMemberInfoDic[userId] {
      teamMemberInfo.nimUser = userFriend
    } else {
      let teamMemberInfo = NETeamMemberInfoModel()
      teamMemberInfo.nimUser = userFriend
      cacheTeamMemberInfoDic[userId] = teamMemberInfo
    }
  }

  public func updateTeamMemberInfo(_ teamMember: V2NIMTeamMember?) {
    guard let teamMember = teamMember else {
      return
    }

    let accountId = teamMember.accountId
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", accountId:\(accountId)")

    if let teamMemberInfo = cacheTeamMemberInfoDic[accountId] {
      teamMemberInfo.teamMember = teamMember
      teamMemberInfo.nimUser = teamMemberInfo.nimUser ?? NEFriendUserCache.shared.getFriendInfo(accountId)
    } else {
      let teamMemberInfo = NETeamMemberInfoModel()
      teamMemberInfo.teamMember = teamMember
      teamMemberInfo.nimUser = teamMemberInfo.nimUser ?? NEFriendUserCache.shared.getFriendInfo(accountId)
      cacheTeamMemberInfoDic[accountId] = teamMemberInfo
    }
  }

  public func updateTeamMemberInfo(_ teamMember: NETeamMemberInfoModel?) {
    guard let teamMember = teamMember,
          let accountId = teamMember.teamMember?.accountId else {
      return
    }
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", accountId:\(accountId)")
    cacheTeamMemberInfoDic[accountId] = teamMember
  }

  /// 获取缓存的群聊信息
  public func getTeamInfo() -> V2NIMTeam? {
    teamInfo
  }

  /// 获取缓存的群成员信息
  public func getTeamMemberInfo(accountId: String) -> NETeamMemberInfoModel? {
    cacheTeamMemberInfoDic[accountId]
  }

  /// 删除群成员信息缓存
  public func removeTeamMemberInfo(_ accountId: String) {
    if let _ = cacheTeamMemberInfoDic[accountId] {
      cacheTeamMemberInfoDic.removeValue(forKey: accountId)
    }
  }

  /// 删除所有信息缓存
  public func removeAllTeamInfo() {
    teamInfo = nil
    cacheTeamMemberInfoDic.removeAll()
  }

  /// 获取缓存群成员名字，team: 备注 > 群昵称 > 昵称 > ID
  public func getShowName(_ accountId: String,
                          _ showAlias: Bool = true) -> (name: String, user: NEUserWithFriend?) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", userId: " + accountId)
    // 好友缓存
    var (fullName, user) = NEFriendUserCache.shared.getShowName(accountId, showAlias)

    // 非好友缓存
    if user == nil {
      (fullName, user) = ChatUserCache.shared.getShowName(accountId, showAlias)
    }

    // 群成员缓存
    if let teamMember = cacheTeamMemberInfoDic[accountId] {
      if teamMember.nimUser?.user?.accountId == accountId ||
        teamMember.teamMember?.accountId == accountId {
        if let teamNick = teamMember.teamMember?.teamNick, !teamNick.isEmpty {
          fullName = teamNick
        }

        if showAlias, let alias = user?.friend?.alias, !alias.isEmpty {
          fullName = alias
        }

        return (fullName, user)
      }
    }
    return (fullName, user)
  }

  //    获取展示的群成员名字, 备注 > 群昵称 > 昵称 > ID
  public func loadShowName(userIds: [String], teamId: String, _ completion: @escaping () -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamId: \(teamId)")
    var loadUserIds = Set<String>() // 需要查询用户信息的ID
    var loadMemberIds = Set<String>() // 需要查询群成员信息的ID
    let group = DispatchGroup()

    for userId in userIds {
      if !NEFriendUserCache.shared.isFriend(userId) {
        loadUserIds.insert(userId)
      }

      if cacheTeamMemberInfoDic[userId] == nil {
        loadMemberIds.insert(userId)
      }
    }

    // 先查询用户信息
    group.enter()
    ContactRepo.shared.getFriendInfoList(accountIds: Array(loadUserIds)) { users, error in
      users?.forEach { ChatUserCache.shared.updateUserInfo($0) }
      group.leave()
    }

    // 再查询群成员信息
    if !loadMemberIds.isEmpty {
      group.enter()
      TeamRepo.shared.getTeamMemberList(teamId, Array(loadMemberIds)) { [weak self] teamMember, error in
        teamMember?.forEach { self?.updateTeamMemberInfo($0) }
        group.leave()
      }
    }

    group.notify(queue: .main) {
      completion()
    }
  }
}
