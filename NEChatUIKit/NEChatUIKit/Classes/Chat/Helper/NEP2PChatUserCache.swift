// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIM2Kit
import NIMSDK

@objc
public protocol NEP2PChatUserCacheListener: NSObjectProtocol {
  /// 非好友单聊信息缓存更新
  /// - Parameter accountId: 用户 id
  @objc optional func onUserInfoUpdate(_ accountId: String)
}

/// 陌生人用户信息缓存，只缓存非好友单聊用户
public class NEP2PChatUserCache: NSObject {
  public static let shared = NEP2PChatUserCache()

  /// 多代理容器
  private let multiDelegate = MultiDelegate<NEP2PChatUserCacheListener>(strongReferences: false)

  // 非好友列表,聊天页面销毁时同步清空
  public var noUserCache = [String: NEUserWithFriend]()

  override private init() {
    super.init()
    ContactRepo.shared.addContactListener(self)
  }

  deinit {
    ContactRepo.shared.removeContactListener(self)
  }

  /// 添加代理
  /// - Parameter listener: 代理
  public func addListener(_ listener: NEP2PChatUserCacheListener) {
    multiDelegate.addDelegate(listener)
  }

  /// 移除代理
  /// - Parameter listener: 代理
  public func removeListener(_ listener: NEP2PChatUserCacheListener) {
    multiDelegate.removeDelegate(listener)
  }

  // 添加（更新）非好友信息
  public func updateUserInfo(_ user: V2NIMUser?) {
    guard let accid = user?.accountId else { return }
    noUserCache[accid]?.user = user

    multiDelegate |> { delegate in
      delegate.onUserInfoUpdate?(accid)
    }
  }

  // 添加（更新）非好友信息
  public func updateUserInfo(_ user: NEUserWithFriend?) {
    guard let accid = user?.user?.accountId else { return }
    noUserCache[accid] = user
  }

  /// 获取缓存的非好友信息
  public func getUserInfo(_ accountId: String) -> NEUserWithFriend? {
    noUserCache[accountId]
  }

  /// 删除非好友信息缓存
  public func removeUserInfo(_ accountId: String) {
    if let _ = noUserCache[accountId] {
      noUserCache.removeValue(forKey: accountId)
    }
  }

  /// 删除所有非好友信息缓存
  public func removeAllUserInfo() {
    noUserCache.removeAll()
  }

  /// 获取缓存用户名字，p2p： 备注 > 昵称 > ID
  public func getShowName(_ userId: String,
                          _ showAlias: Bool = true) -> String {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", userId: " + userId)
    let user = getUserInfo(userId)
    return user?.showName(showAlias) ?? userId
  }
}

// MARK: - NEContactListener

extension NEP2PChatUserCache: NEContactListener {
  /// 用户信息变更回调
  /// - Parameter users: 用户列表
  public func onUserProfileChanged(_ users: [V2NIMUser]) {
    for user in users {
      guard let accid = user.accountId else { break }

      if noUserCache[accid] == nil {
        updateUserInfo(user)
      }
    }
  }
}
