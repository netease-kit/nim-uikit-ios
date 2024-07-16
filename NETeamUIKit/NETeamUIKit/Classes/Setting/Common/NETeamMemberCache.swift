//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import NIMSDK
import UIKit

@objc public protocol NETeamMemberCacheListener: NSObjectProtocol {
  /// 缓存变更回调协议
  @objc optional func memberCacheDidChange()
}

@objc
@objcMembers
open class NETeamMemberCache: NSObject, NETeamListener, NEIMKitClientListener, NEContactListener {
  private let teamMemberCacheMultiDelegate = MultiDelegate<NETeamMemberCacheListener>(strongReferences: false)

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
    NotificationCenter.default.addObserver(self, selector: #selector(didTapHeader), name: NENotificationName.didTapHeader, object: nil)
  }

  deinit {
    teamRepo.removeTeamListener(self)
    client.removeLoginListener(self)
    contactRepo.removeContactListener(self)

    NotificationCenter.default.removeObserver(self)
  }

  /// 添加缓存监听
  /// - Parameter listener: 缓存监听
  public func addTeamCacheListener(_ listener: NETeamMemberCacheListener) {
    teamMemberCacheMultiDelegate.addDelegate(listener)
  }

  /// 移除缓存监听
  /// - Parameter listener: 缓存监听
  public func removeTeamCacheListener(_ listener: NETeamMemberCacheListener) {
    teamMemberCacheMultiDelegate.removeDelegate(listener)
  }

  /// 应用进入后台时执行的操作
  func appDidEnterBackground() {
    clearCache()
  }

  /// 应用即将进入后台（包括锁屏）
  func appWillResignActive() {
    clearCache()
  }

  /// 点击消息发送者头像
  /// 拉取最新用户信息后刷新消息发送者信息
  /// - Parameter noti: 通知对象
  func didTapHeader(_ noti: Notification) {
    if let user = noti.object as? NEUserWithFriend,
       let accid = user.user?.accountId {
      cacheDic[accid]?.nimUser = user
      updateFinish()
    }
  }

  /// 设置缓存(对一个新群设置缓存会移除之前群的缓存，单例只保存一个群的成员缓存)
  /// - Parameter teamId: 群id
  /// - Parameter members: 群成员数据对象列表
  public func setCacheMembers(_ teamId: String, _ members: [NETeamMemberInfoModel]) {
    cacheDic.removeAll()
    currentTeamId = teamId
    endTimer()
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

  /// 判断是否是当前群成员
  public func isCurrentMember(_ accountId: String) -> Bool {
    if cacheDic[accountId] != nil {
      return true
    } else {
      return false
    }
  }

  /// 好友信息更新
  /// - Parameter friendInfo： 好友信息
  public func onFriendInfoChanged(_ friendInfo: V2NIMFriend) {
    if let account = friendInfo.accountId, let model = cacheDic[account] {
      model.nimUser = NEUserWithFriend(friend: friendInfo)
      updateFinish()
    }
  }

  /// 用户信息变更
  ///  - Parameter users: 变更用户
  public func onUserProfileChanged(_ users: [V2NIMUser]) {
    NEALog.infoLog(className(), desc: #function + " onUserProfileChanged count : \(users.count)")
    var needUpdate = false
    for user in users {
      if let accout = user.accountId, let model = cacheDic[accout] {
        model.nimUser = NEUserWithFriend(user: user)
        needUpdate = true
      }
    }
    if needUpdate == true {
      updateFinish()
    }
  }

  /// 好友删除
  /// - parameter accountId: 账号id
  /// - parameter deletionType: 删除类型
  public func onFriendDeleted(_ accountId: String, deletionType: V2NIMFriendDeletionType) {
    if let model = cacheDic[accountId] {
      model.nimUser?.friend = nil
    }
  }

  /// 登录状态改变
  /// - Parameter status: 登录状态枚举
  public func onLoginStatus(_ status: V2NIMLoginStatus) {
    if status == .LOGIN_STATUS_LOGOUT {
      clearCache()
    }
  }

  /// 加入回调
  public func onTeamJoined(_ team: V2NIMTeam) {
    if team.teamId == currentTeamId {
      clearCache()
      updateFinish()
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
      clearCache()
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
    updateFinish()
  }

  /// 群成员减少统一处理处理
  /// - Parameter teamMembers: 群成员
  private func onMemberDidRemove(_ members: [V2NIMTeamMember]) {
    for member in members {
      if currentTeamId != member.teamId {
        continue
      }
      cacheDic.removeValue(forKey: member.accountId)
      updateFinish()
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
      contactRepo.getUserWithFriend(accountIds: accids) { [weak self] users, error in
        users?.forEach { user in
          if let accountId = user.user?.accountId {
            self?.cacheDic[accountId]?.nimUser = user
          }
        }
        self?.updateFinish()
      }
    }
  }

  /// 清除缓存
  public func clearCache() {
    currentTeamId = ""
    cacheDic.removeAll()
    endTimer()
  }

  /// 定时移除缓存
  public func triggerClearCache() {
    NEALog.infoLog(className(), desc: "triggerClearCache")
    clearCache()
  }

  /// 启动定时器
  func trigerTimer() {
    timer = Timer.scheduledTimer(timeInterval: 300, target: self, selector: #selector(triggerClearCache), userInfo: nil, repeats: false)
  }

  /// 停止定时器
  func endTimer() {
    timer?.invalidate()
    timer = nil
  }

  public func updateFinish() {
    teamMemberCacheMultiDelegate |> { delegate in
      delegate.memberCacheDidChange?()
    }
  }

  /// 获取所有群成员信息
  /// - Parameter teamId:  群id
  /// - Parameter queryType:  查询类型
  /// - Parameter completion:  完成后的回调
  public func getAllTeamMemberInfos(_ teamId: String,
                                    _ queryType: V2NIMTeamMemberRoleQueryType,
                                    _ completion: @escaping (NSError?, NETeamInfoModel?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamid:\(teamId)")
    var memberLists = [V2NIMTeamMember]()
    weak var weakSelf = self
    getAllTeamMemberWithMaxLimit(teamId, nil, &memberLists, queryType) { members, error in
      if let err = error {
        completion(err, nil)
      } else {
        if let teamMembers = members {
          let teamInfo = NETeamInfoModel()
          weakSelf?.splitMembers(teamMembers, teamInfo) { error, retTeamInfo in
            completion(error, retTeamInfo)
          }
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
  private func splitMembers(_ members: [V2NIMTeamMember],
                            _ model: NETeamInfoModel,
                            _ maxSizeByPage: Int = 150,
                            _ completion: @escaping (NSError?, NETeamInfoModel?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", members.count:\(members.count)")
    var remaind = [[V2NIMTeamMember]]()
    remaind.append(contentsOf: members.chunk(maxSizeByPage))
    fetchTeamMemberUserInfos(&remaind, model, completion)
  }

  /// 从云信服务器批量获取用户资料
  ///   - Parameter remainUserIds:  用户集合
  ///   - Parameter completion:    成功回调
  private func fetchTeamMemberUserInfos(_ remainUserIds: inout [[V2NIMTeamMember]],
                                        _ model: NETeamInfoModel,
                                        _ completion: @escaping (NSError?, NETeamInfoModel?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", remainUserIds.count:\(remainUserIds.count)")
    guard let members = remainUserIds.first else {
      completion(nil, model)
      return
    }

    let accids = members.map(\.accountId)
    var temArray = remainUserIds
    weak var weakSelf = self

    contactRepo.getUserWithFriend(accountIds: accids) { infos, v2Error in
      if let err = v2Error {
        completion(err as NSError, model)
      } else {
        if let users = infos {
          for index in 0 ..< members.count {
            let memberInfoModel = NETeamMemberInfoModel()
            memberInfoModel.teamMember = members[index]
            if users.count > index {
              let user = users[index]
              memberInfoModel.nimUser = user
            }
            model.users.append(memberInfoModel)
          }
        }
        temArray.removeFirst()
        weakSelf?.fetchTeamMemberUserInfos(&temArray, model, completion)
      }
    }
  }

  /// 群信息同步完成回调
  public func onTeamSyncFinished() {
    NEALog.infoLog(className(), desc: #function + " onTeamSyncFinished call back happen")
    clearCache()
    updateFinish()
  }
}
