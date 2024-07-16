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
open class BlackListViewModel: NSObject {
  var contactRepo = ContactRepo.shared
  public var blockList = [NEUserWithFriend]()
  public weak var delegate: BlackListViewModelDelegate?

  override init() {
    super.init()
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    contactRepo.addContactListener(self)
  }

  deinit {
    contactRepo.removeContactListener(self)
  }

  /// 获取黑名单列表
  func getBlackList() {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    if let blockList = NEFriendUserCache.shared.getBlocklist() {
      NEFriendUserCache.shared.loadShowName(blockList) { users in
        if let users = users {
          self.blockList = users
        }
        self.delegate?.tableViewReload()
      }
    }
  }

  /// 移除黑名单
  /// - Parameters:
  ///   - account: 好友 Id
  ///   - index: 该用户在表格中的位置
  ///   - completion: 回调
  func removeFromBlackList(account: String, _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", account:\(account)")
    contactRepo.removeBlockList(accountId: account) { error in
      if let err = error {
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

    for user in users {
      contactRepo.addBlockList(accountId: user.user?.accountId ?? "") { error in
        if let err = error {
          NEALog.errorLog(ModuleName + " " + BlackListViewModel.className(), desc: #function + ", error:\(err)")
          completion(err)
        } else {
          completion(nil)
        }
      }
    }
  }
}

// MARK: - NEContactListener

extension BlackListViewModel: NEContactListener {
  /// 黑名单移除回调 （非好友）
  /// - Parameter accountId: 移除黑名单用户账号ID
  public func onBlockListRemoved(_ accountId: String) {
    for (index, friendUser) in blockList.enumerated() {
      // 移除黑名单
      if friendUser.user?.accountId == accountId {
        blockList.remove(at: index)
        delegate?.tableViewDelete([IndexPath(row: index, section: 0)])
      }
    }
  }

  /// 好友信息缓存更新
  /// - Parameter accountId: 用户 id
  public func onContactChange(_ changeType: NEContactChangeType, _ contacts: [NEUserWithFriend]) {
    for contact in contacts {
      // 添加黑名单
      if changeType == .addBlock,
         !blockList.contains(where: { $0.user?.accountId == contact.user?.accountId }) {
        let index = IndexPath(row: blockList.count, section: 0)
        blockList.append(contact)
        delegate?.tableViewInsert([index])
      }

      for (index, friendUser) in blockList.enumerated() {
        // 用户信息更新
        if changeType == .update,
           friendUser.user?.accountId == contact.user?.accountId {
          blockList[index] = contact
          delegate?.tableViewReload([IndexPath(row: index, section: 0)])
        }

        // 移除黑名单
        if changeType == .removeBlock,
           friendUser.user?.accountId == contact.user?.accountId {
          blockList.remove(at: index)
          delegate?.tableViewDelete([IndexPath(row: index, section: 0)])
        }

        // 删除好友
        if changeType == .deleteFriend,
           friendUser.user?.accountId == contact.user?.accountId {
          blockList.remove(at: index)
          delegate?.tableViewDelete([IndexPath(row: index, section: 0)])
        }
      }
    }
  }
}
