// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIM2Kit
import NECoreKit

public protocol BlackListViewModelDelegate: NSObjectProtocol {
  func tableViewReload()
  func tableViewReload(_ indexs: [IndexPath])
  func tableViewDelete(_ indexs: [IndexPath])
  func tableViewInsert(_ indexs: [IndexPath])
}

@objcMembers
open class BlackListViewModel: NSObject, NEContactListener {
  var contactRepo = ContactRepo.shared
  public var blockList = [NEUserWithFriend]()
  public weak var delegate: BlackListViewModelDelegate?

  override init() {
    super.init()
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    contactRepo.addContactListener(self)
  }

  /// 获取黑名单列表
  func getBlackList() {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    blockList = NEFriendUserCache.shared.getBlocklist().map(\.value)
  }

  /// 移除黑名单
  /// - Parameters:
  ///   - account: 好友 Id
  ///   - index: 该用户在表格中的位置
  ///   - completion: 回调
  func removeFromBlackList(account: String, _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", account:\(account)")
    contactRepo.removeBlockList(accountId: account) { error in
      if let err = error as? NSError {
        NEALog.errorLog(ModuleName + " " + BlackListViewModel.className(), desc: #function + ", error:\(err)")
        completion(err)
      } else {
        NEFriendUserCache.shared.removeBlockAccount(account)
        completion(nil)
      }
    }
  }

  /// 将好友添加到黑名单
  /// - Parameters:
  ///   - users: 好友列表
  ///   - completion: 回调
  func addBlackList(users: [NEUserWithFriend], _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", users.count:\(users.count)")

    for (i, user) in users.enumerated() {
      contactRepo.addBlockList(accountId: user.user?.accountId ?? "") { error in
        if let err = error as? NSError {
          NEALog.errorLog(ModuleName + " " + BlackListViewModel.className(), desc: #function + ", error:\(err)")
          completion(err)
        } else {
          completion(nil)
        }
      }
    }
  }

  // MARK: - NEContactListener

  /// 用户信息变更回调
  /// - Parameter users: 用户列表
  public func onUserProfileChanged(_ users: [V2NIMUser]) {
    for user in users {
      for (index, friendUser) in blockList.enumerated() {
        if friendUser.user?.accountId == user.accountId {
          friendUser.user = user
          delegate?.tableViewReload([IndexPath(row: index, section: 0)])
          break
        }
      }
    }
  }

  /// 黑名单添加回调
  /// - Parameter user: 用户信息
  public func onBlockListAdded(_ user: V2NIMUser) {
    guard let accountId = user.accountId else { return }

    // 黑名单中已存在
    if blockList.contains(where: { $0.user?.accountId == user.accountId }) {
      return
    }

    let blockUser = NEFriendUserCache.shared.getFriendInfo(accountId) ?? NEUserWithFriend(user: user)
    let index = IndexPath(row: blockList.count, section: 0)
    blockList.append(blockUser)
    delegate?.tableViewInsert([index])
  }

  /// 黑名单移除回调
  /// - Parameter accountId: 好友 Id
  public func onBlockListRemoved(_ accountId: String) {
    for (index, friendUser) in blockList.enumerated() {
      if friendUser.user?.accountId == accountId {
        blockList.remove(at: index)
        delegate?.tableViewDelete([IndexPath(row: index, section: 0)])
        break
      }
    }
  }

  /// 删除好友通知
  /// 本端删除好友，多端同步
  /// - Parameters:
  ///   - accountId: 删除的好友账号ID
  ///   - deletionType: 好友删除的类型
  public func onFriendDeleted(_ accountId: String, deletionType: V2NIMFriendDeletionType) {
    if NEFriendUserCache.shared.isBlockAccount(accountId) {
      onBlockListRemoved(accountId)
    }
  }

  /// 好友信息变更回调
  /// - Parameter friendInfo: 好友信息
  public func onFriendInfoChanged(_ friendInfo: V2NIMFriend) {
    for (index, friendUser) in blockList.enumerated() {
      if friendUser.user?.accountId == friendInfo.accountId {
        friendUser.friend = friendInfo
        delegate?.tableViewReload([IndexPath(row: index, section: 0)])
        break
      }
    }
  }
}
