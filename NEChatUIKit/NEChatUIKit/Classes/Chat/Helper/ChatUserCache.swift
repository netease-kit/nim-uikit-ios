// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIM2Kit
import NIMSDK

/// 用户信息缓存，主要缓存非好友用户
public class ChatUserCache: NSObject {
  public static let shared = ChatUserCache()

  // 非好友列表,聊天页面销毁时同步清空
  public var noUserCache = [String: NEUserWithFriend]()

  override private init() {
    super.init()
  }

  // 添加（更新）非好友信息
  public func updateUserInfo(_ user: V2NIMUser?) {
    guard let userId = user?.accountId else { return }
    noUserCache[userId]?.user = user
  }

  // 添加（更新）非好友信息
  public func updateUserInfo(_ user: NEUserWithFriend?) {
    guard let userId = user?.user?.accountId else { return }
    noUserCache[userId] = user
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
