// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIM2Kit
import NIMSDK

/// 好友信息缓存，只缓存好友
public class NEFriendUserCache: NSObject {
  public static let shared = NEFriendUserCache()
  private let repo = ContactRepo.shared

  // 并发读写队列：读操作用 sync（允许并发），写操作用 sync(flags: .barrier)（独占），
  // 保证 _friendCache / _blockAccountSet 的线程安全，同时维持原有同步写语义。
  private let cacheQueue = DispatchQueue(label: "com.netease.im.NEFriendUserCache", attributes: .concurrent)

  // 黑名单账号集合（内部存储，外部通过线程安全方法访问）
  private var _blockAccountSet: Set<String>?
  public var blockAccountSet: Set<String>? {
    get { cacheQueue.sync { _blockAccountSet } }
    set { cacheQueue.sync(flags: .barrier) { self._blockAccountSet = newValue } }
  }

  // 好友列表，包括黑名单中好友（内部存储，外部通过线程安全方法访问）
  private var _friendCache: [String: NEUserWithFriend]?
  public var friendCache: [String: NEUserWithFriend]? {
    get { cacheQueue.sync { _friendCache } }
    set { cacheQueue.sync(flags: .barrier) { self._friendCache = newValue } }
  }

  override private init() {
    super.init()
    IMKitClient.instance.addLoginListener(self)
  }

  deinit {
    IMKitClient.instance.removeLoginListener(self)
  }

  /// 好友缓存是否为空
  open func isEmpty() -> Bool {
    cacheQueue.sync {
      guard let cache = _friendCache, !cache.isEmpty else { return true }
      // 缓存中只有本人也视为空
      if cache.count == 1, cache.keys.first == IMKitClient.instance.account() {
        return true
      }
      return false
    }
  }

  /// 是否是好友
  open func isFriend(_ accountId: String) -> Bool {
    if accountId == IMKitClient.instance.account() {
      return true
    }
    return cacheQueue.sync { _friendCache?.keys.contains(accountId) ?? false }
  }

  /// 添加（更新）好友信息（V2NIMUser）
  open func updateFriendInfo(_ user: V2NIMUser?) {
    guard let user = user, let accid = user.accountId else { return }
    // sync barrier：写完后方法才返回，保证调用方后续可立即读到最新值
    cacheQueue.sync(flags: .barrier) {
      if let friendUser = self._friendCache?[accid] {
        friendUser.user = user
      } else {
        if IMKitClient.instance.isMe(user.accountId), self._friendCache == nil {
          self._friendCache = [String: NEUserWithFriend]()
        }
        self._friendCache?[accid] = NEUserWithFriend(user: user)
      }
    }
  }

  /// 添加（更新）好友信息（V2NIMFriend）
  open func updateFriendInfo(_ friend: V2NIMFriend?) {
    guard let friend = friend, let accid = friend.accountId else { return }
    cacheQueue.sync(flags: .barrier) {
      if let friendUser = self._friendCache?[accid] {
        friendUser.friend = friend
        friendUser.user = friend.userProfile
      } else {
        self._friendCache?[accid] = NEUserWithFriend(friend: friend)
      }
    }
  }

  /// 添加（更新）好友信息（NEUserWithFriend）
  open func updateFriendInfo(_ friendUser: NEUserWithFriend?) {
    guard let accid = friendUser?.user?.accountId else { return }
    cacheQueue.sync(flags: .barrier) {
      self._friendCache?[accid] = friendUser
    }
  }

  /// 使用好友列表初始化缓存，写完后在主线程发通知
  open func initFriendCacheWithList(_ friendUsers: [NEUserWithFriend]?) {
    guard let friendUsers = friendUsers, !friendUsers.isEmpty else { return }
    // sync barrier：整批写入，写完后方法返回，再发通知保证接收方读到最新数据
    cacheQueue.sync(flags: .barrier) {
      if self._friendCache == nil {
        self._friendCache = [String: NEUserWithFriend]()
      }
      for friendUser in friendUsers {
        guard let accid = friendUser.user?.accountId else { continue }
        self._friendCache?[accid] = friendUser
      }
    }
    // 写入已完成（sync 保证），切主线程通知 UI
    DispatchQueue.main.async {
      NotificationCenter.default.post(name: NENotificationName.friendCacheInit, object: nil)
    }
  }

  /// 获取缓存的好友信息列表，包含黑名单中的好友
  open func getFriendList() -> [String: NEUserWithFriend] {
    cacheQueue.sync { _friendCache ?? [:] }
  }

  /// 获取缓存的好友信息列表，不包含黑名单中的好友
  open func getFriendListNotInBlocklist() -> [String: NEUserWithFriend] {
    cacheQueue.sync {
      guard let cache = _friendCache else { return [:] }
      let me = IMKitClient.instance.account()
      if let block = _blockAccountSet {
        return cache.filter { !block.contains($0.key) && $0.key != me }
      }
      return cache.filter { $0.key != me }
    }
  }

  /// 获取缓存的黑名单列表
  open func getBlocklist() -> [String]? {
    cacheQueue.sync {
      guard let set = _blockAccountSet else { return nil }
      return Array(set)
    }
  }

  /// 获取缓存的好友信息
  open func getFriendInfo(_ accountId: String) -> NEUserWithFriend? {
    cacheQueue.sync { _friendCache?[accountId] }
  }

  /// 删除好友信息缓存
  open func removeFriendInfo(_ accountId: String) {
    cacheQueue.sync(flags: .barrier) {
      self._friendCache?.removeValue(forKey: accountId)
    }
  }

  /// 删除所有好友信息缓存
  open func removeAllFriendInfo() {
    cacheQueue.sync(flags: .barrier) {
      self._friendCache?.removeAll()
      self._blockAccountSet?.removeAll()
    }
  }

  /// 初始化黑名单
  open func initBlockAccountSet(_ blockList: [String]) {
    cacheQueue.sync(flags: .barrier) {
      if self._blockAccountSet == nil {
        self._blockAccountSet = Set<String>()
      }
      blockList.forEach { self._blockAccountSet?.insert($0) }
    }
  }

  /// 黑名单是否初始化
  open func isBlockListInit() -> Bool {
    cacheQueue.sync { _blockAccountSet != nil }
  }

  /// 是否是黑名单账号
  open func isBlockAccount(_ accountId: String) -> Bool {
    cacheQueue.sync { _blockAccountSet?.contains(accountId) ?? false }
  }

  /// 更新黑名单
  open func addBlockAccount(_ accountId: String) {
    cacheQueue.sync(flags: .barrier) {
      if self._blockAccountSet == nil {
        self._blockAccountSet = Set<String>()
      }
      self._blockAccountSet?.insert(accountId)
    }
  }

  /// 移除黑名单账号
  open func removeBlockAccount(_ accountId: String) {
    cacheQueue.sync(flags: .barrier) {
      self._blockAccountSet?.remove(accountId)
    }
  }

  /// 获取缓存用户名字，p2p： 备注 > 昵称 > ID
  open func getShowName(_ userId: String,
                        _ showAlias: Bool = true) -> String {
    let user = getFriendInfo(userId)
    return user?.showName(showAlias) ?? userId
  }

  /// 获取用户信息
  open func loadShowName(_ userIds: [String],
                         _ showAlias: Bool = true,
                         _ completion: @escaping ([NEUserWithFriend]?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", user.count: \(userIds.count)")
    var loadUserIds = Set<String>()
    // 一次 sync 完成全部缓存命中检查，避免循环中多次加锁
    let friendUsers = cacheQueue.sync { () -> [NEUserWithFriend] in
      var hits = [NEUserWithFriend]()
      for userId in userIds {
        if let friendUser = _friendCache?[userId] {
          hits.append(friendUser)
        } else {
          loadUserIds.insert(userId)
        }
      }
      return hits
    }

    if loadUserIds.isEmpty {
      completion(friendUsers)
      return
    }

    ContactRepo.shared.getUserListFromCloud(accountIds: Array(loadUserIds)) { users, error in
      completion(friendUsers + (users ?? []))
    }
  }

  ///    全名后几位
  public static func getShortName(_ name: String, _ length: Int = 2) -> String {
    name
      .count > length ? String(name[name.index(name.endIndex, offsetBy: -length)...]) : name
  }

  /// 截取字符串 abcdefghi -> abcd...hi
  /// - Parameters:
  ///   - name: 字符串
  ///   - length: 超过多少截取
  /// - Returns: 替换后的字符串
  public static func getCutName(_ name: String, _ length: Int = 7) -> String {
    if name.count > 7 {
      let leftEndIndex = name.index(name.startIndex, offsetBy: 4)
      let rightStartIndex = name.index(name.endIndex, offsetBy: -2)
      return name[name.startIndex ..< leftEndIndex] + "..." + name[rightStartIndex ..< name.endIndex]
    }
    return name
  }
}

extension NEFriendUserCache: NEIMKitClientListener {
  ///  登录状态变更回调
  ///  - Parameter status: 登录状态
  open func onLoginStatus(_ status: V2NIMLoginStatus) {
    if status == .LOGIN_STATUS_LOGOUT {
      removeAllFriendInfo()
    }
  }

  /// 被踢下线回调
  /// - Parameter detail: 被踢下线的详细信息
  open func onKickedOffline(_ detail: V2NIMKickedOfflineDetail) {
    removeAllFriendInfo()
  }
}
