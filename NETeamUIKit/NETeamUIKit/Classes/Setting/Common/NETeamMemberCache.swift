//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objc
@objcMembers
open class NETeamMemberCache: NSObject, NETeamListener, NEIMKitClientListener, NEContactListener {
  public static let shared = NETeamMemberCache()
  /// 当前缓存的群id
  var currentTeamId = ""

  /// 群模块API单例
  let teamRepo = TeamRepo.shared

  /// 通讯录API单例
  let contactRepo = ContactRepo.shared

  /// kit client 单例
  let client = IMKitClient.instance

  /// 缓存
  private var cacheDic = [String: NETeamMemberInfoModel]()

  /// 清理缓存定时器
  var timer: Timer?

  /// 初始化
  override private init() {
    super.init()
    teamRepo.addTeamListener(self)
    client.addLoginListener(self)
    contactRepo.addContactListener(self)

    NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
  }

  deinit {
    teamRepo.removeTeamListener(self)
    client.removeLoginListener(self)
    contactRepo.removeContactListener(self)

    NotificationCenter.default.removeObserver(self)
  }

  /// 应用进入后台时执行的操作
  func appDidEnterBackground() {
    clearCache()
  }

  /// 应用即将进入后台（包括锁屏）
  func appWillResignActive() {
    clearCache()
  }

  /// 设置缓存(对一个新群设置缓存会移除之前群的缓存，单例只保存一个群的成员缓存)
  /// - Parameter teamId: 群id
  /// - Parameter members: 群成员数据对象列表
  public func setCacheMembers(_ teamId: String, _ members: [NETeamMemberInfoModel]) {
    cacheDic.removeAll()
    currentTeamId = teamId

    // 启动新的定时器确保前面开启的停止
    endTimer()

    startTimer()
    for model in members {
      if let accountId = model.teamMember?.accountId {
        cacheDic[accountId] = model
      }
    }
  }

  /// 获取缓存
  /// - Parameter teamId: 群id
  /// - returns 群成员缓存数据(可能为空)
  public func getTeamMemberCache(_ teamId: String) -> [NETeamMemberInfoModel]? {
    if currentTeamId == teamId {
      var allCacheMembers = Array(cacheDic.values)
      allCacheMembers.sort { model1, model2 in
        if let time1 = model1.teamMember?.joinTime, let time2 = model2.teamMember?.joinTime {
          return time2 > time1
        }
        return false
      }
      if allCacheMembers.count > 0 {
        return allCacheMembers
      }
    }
    return nil
  }

  /// 好友信息更新
  /// - Parameter friendInfo： 好友信息
  public func onFriendInfoChanged(_ friendInfo: V2NIMFriend) {
    if let account = friendInfo.accountId, let model = cacheDic[account] {
      model.nimUser = NEUserWithFriend(friend: friendInfo)
    }
  }

  /// 好友删除
  /// - parameter accountId: 账号id
  /// - parameter deletionType: 删除类型
  public func onFriendDeleted(_ accountId: String, deletionType: V2NIMFriendDeletionType) {
    if let model = cacheDic[accountId] {
      model.nimUser = nil
    }
  }

  /// 登录状态改变
  /// - Parameter status: 登录状态枚举
  public func onLoginStatus(_ status: V2NIMLoginStatus) {
    if status == .LOGIN_STATUS_LOGOUT {
      cacheDic.removeAll()
    }
  }

  /// 群成员离开回调
  /// - Parameter teamMembers: 群成员
  public func onTeamMemberLeft(_ teamMembers: [V2NIMTeamMember]) {
    onMemberDidRemove(teamMembers)
  }

  /// 群成员被踢回调
  /// - Parameter operatorAccountId: 操作者id
  /// - Parameter teamMembers: 群成员
  public func onTeamMemberKicked(_ operatorAccountId: String, teamMembers: [V2NIMTeamMember]) {
    onMemberDidRemove(teamMembers)
  }

  /// 群成员加入回调
  /// - Parameter teamMembers: 群成员
  public func onTeamMemberJoined(_ teamMembers: [V2NIMTeamMember]) {
    onMemberDidAdd(teamMembers)
  }

  /// 群成员更新回调
  /// - Parameter teamMembers: 群成员列表
  public func onTeamMemberInfoUpdated(_ teamMembers: [V2NIMTeamMember]) {
    onMemberDidChanged(teamMembers)
  }

  /// 群聊解散回调
  /// - Parameter team: 群对象
  public func onTeamDismissed(_ team: V2NIMTeam) {
    if team.teamId == currentTeamId {
      cacheDic.removeAll()
    }
  }

  /// 群成员变更统一处理
  /// - Parameter teamMembers: 群成员
  private func onMemberDidChanged(_ members: [V2NIMTeamMember]) {
    for member in members {
      if currentTeamId != member.teamId {
        continue
      }
      if let model = cacheDic[member.accountId] {
        model.teamMember = member
      }
    }
  }

  /// 群成员减少统一处理处理
  /// - Parameter teamMembers: 群成员
  private func onMemberDidRemove(_ members: [V2NIMTeamMember]) {
    for member in members {
      if currentTeamId != member.teamId {
        continue
      }
      cacheDic.removeValue(forKey: member.accountId)
    }
  }

  /// 群成员增加统一处理
  /// - Parameter teamMembers: 群成员
  private func onMemberDidAdd(_ members: [V2NIMTeamMember]) {
    var allMembmers = [V2NIMTeamMember]()
    for member in members {
      if currentTeamId != member.teamId {
        continue
      }
      NEALog.infoLog(className(), desc: "team cache did add member \(member.teamNick ?? ""))")
      let model = NETeamMemberInfoModel()
      model.teamMember = member
      cacheDic[member.accountId] = model
      allMembmers.append(member)
    }
    if allMembmers.count > 0 {
      let accids = allMembmers.map(\.accountId)
      contactRepo.getFriendInfoList(accountIds: accids) { [weak self] users, error in
        users?.forEach { user in
          if let accountId = user.friend?.accountId {
            self?.cacheDic[accountId]?.nimUser = user
          }
        }
      }
    }
  }

  /// 清除缓存
  public func clearCache() {
    currentTeamId = ""
    cacheDic.removeAll()
    endTimer()
  }

  /// 启动定时器
  func startTimer() {
    timer = Timer.scheduledTimer(timeInterval: 300, target: self, selector: #selector(clearCache), userInfo: nil, repeats: true)
  }

  /// 停止定时器
  func endTimer() {
    timer?.invalidate()
    timer = nil
  }
}
