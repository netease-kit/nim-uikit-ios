//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIM2Kit
import NIMSDK

@objcMembers
public class ConversationDeduplicationHelper: NSObject, NEIMKitClientListener {
  // 单例变量
  static let instance = ConversationDeduplicationHelper()
  // 最多缓存数量，可外部修改
  public var limit = 100
  // 撤回消息记录
  public var revokeMessageIds = Set<String>()

  override private init() {
    super.init()
    IMKitClient.instance.addLoginListener(self)
  }

  deinit {
    IMKitClient.instance.removeLoginListener(self)
  }

  public func onLoginStatus(_ status: V2NIMLoginStatus) {
    if status == .LOGIN_STATUS_LOGOUT {
      clearCache()
    }
  }

  public func onKickedOffline(_ detail: V2NIMKickedOfflineDetail) {
    clearCache()
  }

  public func clearCache() {
    revokeMessageIds.removeAll()
  }

  // 是否已经保存过此撤回消息，防止重复保存本地撤回记录
  public func isRevokeMessageSaved(messageId: String) -> Bool {
    if revokeMessageIds.contains(messageId) {
      return true
    }
    if revokeMessageIds.count > limit {
      revokeMessageIds.removeAll()
    }
    revokeMessageIds.insert(messageId)
    return false
  }
}
