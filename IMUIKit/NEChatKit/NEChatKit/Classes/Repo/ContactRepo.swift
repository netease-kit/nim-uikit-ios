// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit
import NECoreIM2Kit
import NIMSDK

@objc
public enum NEContactChangeType: Int {
  case addFriend = 0
  case update
  case deleteFriend
  case addBlock
  case removeBlock
}

@objc
public protocol NEContactListener: NSObjectProtocol {
  /// 用户信息变更回调
  /// - Parameter users: 用户列表
  @objc optional func onUserProfileChanged(_ users: [V2NIMUser])

  /// 黑名单添加回调
  /// - Parameter user: 加入黑名单的好友
  @objc optional func onBlockListAdded(_ user: V2NIMUser)

  /// 黑名单移除回调
  /// - Parameter accountId: 移除黑名单用户账号ID
  @objc optional func onBlockListRemoved(_ accountId: String)

  /// 添加好友通知
  /// - Parameter friendInfo: 好友信息
  @objc optional func onFriendAdded(_ friendInfo: V2NIMFriend)

  /// 删除好友通知
  /// 本端删除好友，多端同步
  /// - Parameters:
  ///   - accountId: 删除的好友账号ID
  ///   - deletionType: 好友删除的类型
  @objc optional func onFriendDeleted(_ accountId: String, deletionType: V2NIMFriendDeletionType)

  /// 收到好友添加申请回调
  /// - Parameter application: 申请添加好友信息
  @objc optional func onFriendAddApplication(_ application: V2NIMFriendAddApplication)

  /// 好友添加申请被拒绝回调
  /// - Parameter rejectionInfo: 申请添加好友拒绝信息
  @objc optional func onFriendAddRejected(_ rejectionInfo: V2NIMFriendAddApplication)

  /// 好友信息变更回调
  /// - Parameter friendInfo: 好友信息
  @objc optional func onFriendInfoChanged(_ friendInfo: V2NIMFriend)

  /// 好友信息缓存更新（包含好友信息和用户信息）
  /// - Parameter changeType: 操作类型
  /// - Parameter contacts: 好友列表
  @objc optional func onContactChange(_ changeType: NEContactChangeType, _ contacts: [NEUserWithFriend])
}

@objcMembers
public class ContactRepo: NSObject, V2NIMUserListener, V2NIMFriendListener {
  public static let shared = ContactRepo()
  private let mutiDelegate = MultiDelegate<NEContactListener>(strongReferences: false)

  /// 好友Provider
  var friendProvider = FriendProvider.shared

  /// 用户信息Provider
  var userProvider = UserProvider.shared

  override private init() {
    super.init()
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    addUserListener(self)
    addFriendListener(self)
    IMKitClient.instance.addLoginListener(self)
  }

  deinit {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
  }

  // MARK: - 代理

  /// 添加通讯录监听
  /// - Parameter listener: 监听器
  open func addContactListener(_ listener: NEContactListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    mutiDelegate.addDelegate(listener)
  }

  /// 移除通讯录监听
  /// - Parameter listener: 监听器
  open func removeContactListener(_ listener: NEContactListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    mutiDelegate.removeDelegate(listener)
  }

  /// 添加好友监听器
  /// - Parameter listener: 监听器
  open func addFriendListener(_ listener: V2NIMFriendListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    friendProvider.addFriendListener(listener: listener)
  }

  /// 移除好友监听器
  /// - Parameter listener: 监听器
  open func removeFriendListener(_ listener: V2NIMFriendListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    friendProvider.removeFriendListener(listener: listener)
  }

  /// 添加用户资料监听器
  /// - Parameter listener: 监听器
  open func addUserListener(_ listener: V2NIMUserListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    userProvider.addUserListener(listener: listener)
  }

  /// 移除用户资料监听器
  /// - Parameter listener: 监听器
  open func removeUserListener(_ listener: V2NIMUserListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    userProvider.removeUserListener(listener: listener)
  }

  // MARK: -

  /// 根据AccountId获取用户信息，本地查询
  /// - Parameters:
  ///   - accountIds: 账号列表
  /// - Returns: 用户信息
  open func getUserInfo(_ accountIds: [String]) -> [NEUserWithFriend]? {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)

    var users = [NEUserWithFriend]()
    if let userDelegate = userProvider.userDelegate {
      for accountId in accountIds {
        let user = userDelegate.getUserInfo?(account: accountId)
        if let user = user {
          users.append(user)
        }
      }
    } else {
      for accountId in accountIds {
        if let user = NEFriendUserCache.shared.getFriendInfo(accountId) {
          users.append(user)
        }
      }
    }
    return users
  }

  /// 获取好友列表(不包含黑名单中的好友)
  /// - Parameters:
  ///   - completion: 完成回调，包含好友列表
  open func getContactList(_ completion: @escaping ([NEUserWithFriend]?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    friendProvider.getFriendList { [weak self] friends, error in
      if let friends = friends {
        var friendMap = [String: NEUserWithFriend]()
        for friend in friends {
          guard let accid = friend.accountId else {
            continue
          }

          friendMap[accid] = NEUserWithFriend(friend: friend)
        }

        // 查询好友的 user 信息
        let loadList = friends.compactMap(\.accountId)
        self?.userProvider.getUserListFromCloud(accountIds: loadList) { users, error in
          if let users = users {
            for user in users {
              guard let accid = user.accountId else {
                continue
              }
              friendMap[accid]?.user = user
            }
          }

          let userWithFriendList = Array(friendMap.values)
          NEFriendUserCache.shared.initFriendCacheWithList(userWithFriendList)
          self?.userProvider.getBlacklist { block, error in
            if let block = block {
              NEFriendUserCache.shared.initBlockAccountSet(block)
              let filterFriends = userWithFriendList.filter { !block.contains($0.user?.accountId ?? "") }
              completion(filterFriends, nil)
            } else {
              completion(userWithFriendList, error?.nserror as? NSError)
            }
          }
        }
      } else {
        completion(nil, error?.nserror as? NSError)
      }
    }
  }

  /// 根据用户账号列表获取用户资料
  /// - Parameter accountIds: 需要获取用户资料的账号列表
  ///  List为空， 或者size==0， 返回参数错误
  ///  单次最大150， 500以内不做强制校验，大于500返回参数错误
  /// - Parameter completion: 获取列表回调
  open func getUserListFromCloud(accountIds: [String],
                                 _ completion: @escaping ([NEUserWithFriend]?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " \(accountIds)")

    if let userDelegate = userProvider.userDelegate {
      userDelegate.fetchUserInfo?(accountList: accountIds, completion: completion)
      return
    }

    userProvider.getUserListFromCloud(accountIds: accountIds) { users, error in
      guard let users = users else {
        completion(nil, error?.nserror as? NSError)
        return
      }

      var userWithFriends = [NEUserWithFriend]()
      for user in users {
        guard let accid = user.accountId else { continue }
        if NEFriendUserCache.shared.isFriend(accid) {
          NEFriendUserCache.shared.updateFriendInfo(user)
        }

        let userWithFriend = NEUserWithFriend(user: user)
        userWithFriends.append(userWithFriend)
      }
      completion(userWithFriends, error?.nserror as? NSError)
    }
  }

  /// 根据AccountId获取好友信息
  /// - Parameters:
  ///   - accountIds: 好友账号列表
  ///   - completion: 完成回调
  open func getFriendList(accountIds: [String],
                          _ completion: @escaping ([NEUserWithFriend]?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " \(accountIds)")
    friendProvider.getFriendByIds(accountIds: accountIds) { friends, error in
      guard let friends = friends else {
        completion(nil, error?.nserror as? NSError)
        return
      }

      var userWithFriends = [NEUserWithFriend]()
      for friend in friends {
        NEFriendUserCache.shared.updateFriendInfo(friend)
        let userWithFriend = NEUserWithFriend(friend: friend)
        userWithFriends.append(userWithFriend)
      }
      completion(userWithFriends, error?.nserror as? NSError)
    }
  }

  /// 根据AccountId获取用户信息，包含好友和陌生人
  /// - Parameters:
  ///   - accountIds: 好友账号列表
  ///   - completion: 完成回调
  open func getUserWithFriend(accountIds: [String],
                              _ completion: @escaping ([NEUserWithFriend]?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " \(accountIds)")

    getUserListFromCloud(accountIds: accountIds) { [weak self] users, error in
      if let err = error {
        completion(users, err)
        return
      }

      var fetchAccountIds = accountIds
      for user in users ?? [] {
        if let accid = user.user?.accountId, NEFriendUserCache.shared.isFriend(accid) {
          user.friend = NEFriendUserCache.shared.getFriendInfo(accid)?.friend
          fetchAccountIds.removeAll(where: { $0 == accid })
        }
      }

      guard !fetchAccountIds.isEmpty else {
        completion(users, nil)
        return
      }

      self?.getFriendList(accountIds: fetchAccountIds) { friends, error in
        if let err = error {
          completion(users, err)
          return
        }

        var friendMap = [String: NEUserWithFriend]()
        for friend in friends ?? [] {
          if let accid = friend.user?.accountId {
            friendMap[accid] = friend
          }
        }

        for user in users ?? [] {
          if let accid = user.user?.accountId {
            user.friend = friendMap[accid]?.friend
          }
        }

        completion(users, error)
      }
    }
  }

  /// 添加好友
  /// - Parameters:
  ///   - accountId: 被添加为好友的账号ID
  ///   - params: 添加好友参数
  ///   - completion: 完成回调
  open func addFriend(accountId: String,
                      params: V2NIMFriendAddParams,
                      _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", accountId: \(accountId)")
    friendProvider.addFriend(accountId: accountId, params: params) { error in
      completion(error?.nserror as? NSError)
    }
  }

  /// 删除好友
  /// - Parameters:
  ///   - account: 好友Id
  ///   - params: 删除好友参数
  ///   - completion: 完成回调
  open func deleteFriend(account: String,
                         params: V2NIMFriendDeleteParams,
                         _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", account: " + account)
    friendProvider.deleteFriend(accountId: account, param: params) { error in
      completion(error?.nserror as? NSError)
    }
  }

  /// 接受好友申请
  /// - Parameters:
  ///   - application: 申请添加好友的相关信息
  ///   - completion: 请求回调
  open func acceptAddApplication(application: V2NIMFriendAddApplication,
                                 _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", operatorAccountId: " + (application.operatorAccountId ?? ""))
    friendProvider.acceptAddApplication(application: application) { error in
      completion(error?.nserror as? NSError)
    }
  }

  /// 拒绝添加好友申请
  /// - Parameters:
  ///   - application: 拒绝添加好友的相关信息
  ///   - postscript: 拒绝申请的附言
  ///   - completion: 请求回调
  open func rejectAddApplication(application: V2NIMFriendAddApplication,
                                 postscript: String? = nil,
                                 _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", operatorAccountId: " + (application.operatorAccountId ?? ""))
    friendProvider.rejectAddApplication(application: application, postscript: postscript ?? "") { error in
      completion(error?.nserror as? NSError)
    }
  }

  /// 获取添加好友申请列表
  /// - Parameters:
  ///   - option: 申请添加好友相关信息查询参数
  ///   - completion: 请求回调
  open func getAddApplicationList(option: V2NIMFriendAddApplicationQueryOption,
                                  _ completion: @escaping (V2NIMFriendAddApplicationResult?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", offset: \(option.offset)")
    friendProvider.getAddApplicationList(option: option) { result, error in
      completion(result, error?.nserror as? NSError)
    }
  }

  /// 获取好友申请未读数量,统计所有状态为未处理，且未读的数量
  /// - Parameters:
  ///   - completion: 请求回调
  open func getUnreadApplicationCount(_ completion: @escaping (Int, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    friendProvider.getAddApplicationUnreadCount { count, error in
      completion(count, error?.nserror as? NSError)
    }
  }

  /// 设置好友申请已读,调用该方法，历史数据未读数据均标记为已读
  /// - Parameters:
  ///   - completion: 请求回调
  open func setAddApplicationRead(_ completion: @escaping (Bool, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    friendProvider.setAddApplicationRead { success, error in
      completion(success, error?.nserror as? NSError)
    }
  }

  /// 清空通知
  open func clearNotification(_ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    friendProvider.clearNotification { error in
      completion(error?.nserror as? NSError)
    }
  }

  /// 返回所有在黑名单中的用户列表
  /// - Parameter completion: 回调，包含黑名单成员User列表
  open func getBlockList(_ completion: @escaping ([NEUserWithFriend]?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    userProvider.getBlacklist { [weak self] blocklist, error in
      guard let blocklist = blocklist else {
        completion(nil, error?.nserror as? NSError)
        return
      }

      NEFriendUserCache.shared.initBlockAccountSet(blocklist)
      self?.getFriendList(accountIds: blocklist) { userFriends, error in
        completion(userFriends, error)
      }
    }
  }

  /// 添加用户到黑名单
  /// - Parameters:
  ///   - accountId: 用户Id
  ///   - completion: 完成回调
  open func addBlockList(accountId: String, _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", accountId: \(accountId)")
    userProvider.addUserToBlackList(accountId: accountId) { error in
      completion(error?.nserror as? NSError)
    }
  }

  /// 将用户从黑名单移除
  /// - Parameters:
  ///   - accountId: 用户Id
  ///   - completion: 完成回调
  open func removeBlockList(accountId: String, _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", accountId: \(accountId)")
    userProvider.removeUserFromBlackList(accountId: accountId) { error in
      completion(error?.nserror as? NSError)
    }
  }

  /// 更新好友信息
  /// - Parameters:
  ///   - accountId: 用户Id
  ///   - params: 好友信息参数
  ///   - completion: 请求回调
  open func setFriendInfo(accountId: String,
                          params: V2NIMFriendSetParams,
                          _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", accountId: " + accountId)
    friendProvider.setFriendInfo(accountId: accountId, params: params) { error in
      completion(error?.nserror as? NSError)
    }
  }

  /// 按选项搜索好友
  /// - Parameters:
  ///   - option: 搜索选项
  ///   - completion: 请求回调
  open func searchFriendByOption(option: V2NIMFriendSearchOption,
                                 _ completion: @escaping ([V2NIMFriend]?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    friendProvider.searchFriendByOption(option: option) { friends, error in
      completion(friends, error?.nserror as? NSError)
    }
  }

  /// 标记单条好友申请已读
  /// - Parameters:
  ///   - application: 需要标记的申请记录，nil 则标记全部
  ///   - completion: 请求回调
  open func setAddApplicationReadEx(application: V2NIMFriendAddApplication?,
                                    _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    friendProvider.setAddApplicationReadEx(application: application) { error in
      completion(error?.nserror as? NSError)
    }
  }

  /// 删除好友申请记录
  /// - Parameters:
  ///   - application: 需要删除的申请记录
  ///   - completion: 请求回调
  open func deleteAddApplication(application: V2NIMFriendAddApplication,
                                 _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    friendProvider.deleteAddApplication(application: application) { error in
      completion(error?.nserror as? NSError)
    }
  }

  /// 按选项批量清除好友申请记录
  /// - Parameters:
  ///   - option: 清除选项
  ///   - completion: 请求回调
  open func clearAllAddApplicationEx(option: V2NIMFriendClearAddApplicationOption,
                                     _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    friendProvider.clearAllAddApplicationEx(option: option) { error in
      completion(error?.nserror as? NSError)
    }
  }

  /// 按选项搜索用户
  /// - Parameters:
  ///   - option: 搜索选项
  ///   - completion: 完成回调
  open func searchUserByOption(option: V2NIMUserSearchOption,
                               _ completion: @escaping ([V2NIMUser]?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    userProvider.searchUserByOption(option: option) { users, error in
      completion(users, error?.nserror as? NSError)
    }
  }

  /// 异步查询账号拉黑状态
  /// - Parameters:
  ///   - accountIds: 账号 ID 列表
  ///   - completion: 完成回调
  open func checkBlock(accountIds: [String],
                       _ completion: @escaping ([String: NSNumber]?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " accountIds: \(accountIds)")
    userProvider.checkBlock(accountIds: accountIds) { result, error in
      completion(result, error?.nserror as? NSError)
    }
  }

  /// 获取本地用户列表（不请求云端）
  /// - Parameters:
  ///   - accountIds: 账号 ID 列表
  ///   - error: 错误信息，调用失败时赋值
  /// - Returns: 本地已缓存的用户信息列表
  open func getUserListLocal(accountIds: [String],
                             error: inout V2NIMError?) -> [V2NIMUser]? {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " accountIds count:\(accountIds.count)")
    return userProvider.getUserListLocal(accountIds: accountIds, error: &error)
  }

  /// 获取单个用户信息（本地缓存，不请求云端）
  /// - Parameters:
  ///   - accountId: 账号 ID
  ///   - error: 错误信息，调用失败时赋值
  /// - Returns: 用户信息
  open func getUserInfoLocal(accountId: String,
                             error: inout V2NIMError?) -> V2NIMUser? {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " accountId:\(accountId)")
    return userProvider.getUserInfoLocal(accountId: accountId, error: &error)
  }

  /// 同步查询账号拉黑状态（本地缓存）
  /// - Parameter accountIds: 账号 ID 列表
  /// - Returns: accountId -> isBlocked 的字典
  open func checkBlockLocal(accountIds: [String]) -> [String: NSNumber]? {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " accountIds count:\(accountIds.count)")
    return userProvider.checkBlockLocal(accountIds: accountIds)
  }

  /// 更新自己的用户资料
  /// - Parameter updateParams: 更新自己的用户资料参数
  /// - Parameter completion: 更新用户资料完成回调
  open func updateSelfUserProfile(_ updateParams: V2NIMUserUpdateParams,
                                  _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + "\(updateParams)")
    if let userDelegate = userProvider.userDelegate {
      userDelegate.updateUserInfo?(values: updateParams, completion: completion)
      return
    }

    UserProvider.shared.updateSelfUserProfile(updateParams) { error in
      completion(error)
    }
  }

  // MARK: - V2NIMUserListener

  /// 用户信息变更回调
  /// - Parameter users: 用户列表
  open func onUserProfileChanged(_ users: [V2NIMUser]) {
    print(ModuleName + " " + #function)

    var updateUsers = [NEUserWithFriend]()
    for user in users {
      if let accid = user.accountId,
         NEFriendUserCache.shared.isFriend(accid) {
        NEFriendUserCache.shared.updateFriendInfo(user)
        if let userWithFriend = NEFriendUserCache.shared.getFriendInfo(accid) {
          updateUsers.append(userWithFriend)
        }
      } else {
        updateUsers.append(NEUserWithFriend(user: user))
      }
    }

    mutiDelegate |> { delegate in
      delegate.onUserProfileChanged?(users)
      delegate.onContactChange?(.update, updateUsers)
    }
  }

  /// 黑名单添加回调
  /// - Parameter user: 加入黑名单的好友
  open func onBlockListAdded(_ user: V2NIMUser) {
    print(ModuleName + " " + #function)

    if let accid = user.accountId,
       NEFriendUserCache.shared.isFriend(accid) {
      NEFriendUserCache.shared.addBlockAccount(accid)
    }

    mutiDelegate |> { delegate in
      delegate.onBlockListAdded?(user)

      if let accid = user.accountId,
         let userWithFriend = NEFriendUserCache.shared.getFriendInfo(accid) {
        delegate.onContactChange?(.addBlock, [userWithFriend])
      }
    }
  }

  /// 黑名单移除回调
  /// - Parameter accountId: 移除黑名的用户账号ID
  open func onBlockListRemoved(_ accountId: String) {
    print(ModuleName + " " + #function)

    NEFriendUserCache.shared.removeBlockAccount(accountId)
    mutiDelegate |> { delegate in
      delegate.onBlockListRemoved?(accountId)

      if let userWithFriend = NEFriendUserCache.shared.getFriendInfo(accountId) {
        delegate.onContactChange?(.removeBlock, [userWithFriend])
      }
    }
  }

  // MARK: - V2NIMFriendListener

  /// 添加好友通知
  /// - Parameter friendInfo: 好友信息
  open func onFriendAdded(_ friendInfo: V2NIMFriend) {
    print(ModuleName + " " + #function)

    NEFriendUserCache.shared.updateFriendInfo(friendInfo)
    mutiDelegate |> { delegate in
      delegate.onFriendAdded?(friendInfo)

      if let accid = friendInfo.accountId,
         let userWithFriend = NEFriendUserCache.shared.getFriendInfo(accid) {
        delegate.onContactChange?(.addFriend, [userWithFriend])
      }
    }
  }

  /// 删除好友通知
  /// 本端删除好友，多端同步
  /// - Parameters:
  ///   - accountId: 删除的好友账号ID
  ///   - deletionType: 好友删除的类型
  open func onFriendDeleted(_ accountId: String, deletionType: V2NIMFriendDeletionType) {
    let userWithFriend = NEFriendUserCache.shared.getFriendInfo(accountId)
    NEFriendUserCache.shared.removeFriendInfo(accountId)
    mutiDelegate |> { delegate in
      delegate.onFriendDeleted?(accountId, deletionType: deletionType)

      if let userWithFriend = userWithFriend {
        delegate.onContactChange?(.deleteFriend, [userWithFriend])
      }
    }
  }

  /// 收到好友添加申请回调
  /// - Parameter application: 申请添加好友信息
  open func onFriendAddApplication(_ application: V2NIMFriendAddApplication) {
    print(ModuleName + " " + #function)
    mutiDelegate |> { delegate in
      delegate.onFriendAddApplication?(application)
    }
  }

  /// 好友添加申请被拒绝回调
  /// - Parameter rejectionInfo: 申请添加好友拒绝信息
  open func onFriendAddRejected(_ rejectionInfo: V2NIMFriendAddApplication) {
    print(ModuleName + " " + #function)
    mutiDelegate |> { delegate in
      delegate.onFriendAddRejected?(rejectionInfo)
    }
  }

  /// 好友信息变更回调
  /// - Parameter friendInfo: 好友信息
  open func onFriendInfoChanged(_ friendInfo: V2NIMFriend) {
    print(ModuleName + " " + #function + "\(friendInfo.alias ?? friendInfo.accountId ?? "")")

    NEFriendUserCache.shared.updateFriendInfo(friendInfo)
    mutiDelegate |> { delegate in
      delegate.onFriendInfoChanged?(friendInfo)

      if let accountId = friendInfo.accountId,
         let userWithFriend = NEFriendUserCache.shared.getFriendInfo(accountId) {
        delegate.onContactChange?(.update, [userWithFriend])
      }
    }
  }
}

// MARK: - NEIMKitClientListener

extension ContactRepo: NEIMKitClientListener {
  /// 数据同步回调
  /// - Parameters:
  ///   - type: 同步的数据类型
  ///   - state: 同步状态
  ///   - error: 错误信息
  open func onDataSync(_ type: V2NIMDataSyncType, state: V2NIMDataSyncState, error: V2NIMError?) {
    if type == .DATA_SYNC_TYPE_MAIN, state == .DATA_SYNC_STATE_COMPLETED {
      NEALog.infoLog(className() + " [Performance]", desc: #function + "DATA_SYNC_TYPE_MAIN COMPLETED timestamp:\(Date().timeIntervalSince1970)")

      // 拉取好友信息
      DispatchQueue.global().async { [weak self] in
        if NEFriendUserCache.shared.getFriendInfo(IMKitClient.instance.account()) == nil {
          self?.getUserListFromCloud(accountIds: [IMKitClient.instance.account()]) { _, _ in }
        }
        self?.getContactList { friends, error in
          NEALog.infoLog(ContactRepo.className(), desc: #function + " getContactList count:\(String(describing: friends?.count))")
        }
      }
    }
  }
}
