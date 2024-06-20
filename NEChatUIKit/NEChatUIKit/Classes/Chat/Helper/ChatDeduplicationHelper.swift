//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIM2Kit
import NIMSDK

@objcMembers
public class ChatDeduplicationHelper: NSObject, NEIMKitClientListener {
  // 单例变量
  static let instance = ChatDeduplicationHelper()
  // 最多缓存数量，可外部修改
  public var limit = 100
  // 黑名单消息id记录
  public var blackListMessageIds = Set<String>()
  // 音频消息记录
  public var recordAudioMessagePaths = Set<String>()
  // 发送中消息记录
  public var sendingMessageIds = Set<String>()
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
    blackListMessageIds.removeAll()
    recordAudioMessagePaths.removeAll()
    revokeMessageIds.removeAll()
    NEFriendUserCache.shared.removeAllFriendInfo()
  }

  // 是否已经发送过对应消息的提示
  public func isMessageSended(messageId: String) -> Bool {
    if sendingMessageIds.contains(messageId) {
      return true
    }
    if sendingMessageIds.count > limit {
      sendingMessageIds.removeAll()
    }
    sendingMessageIds.insert(messageId)
    return false
  }

  // 是否已经发送过黑名单消息的提示
  public func isBlackTipSended(messageId: String) -> Bool {
    if blackListMessageIds.contains(messageId) {
      return true
    }
    if blackListMessageIds.count > limit {
      blackListMessageIds.removeAll()
    }
    blackListMessageIds.insert(messageId)
    return false
  }

  // 移除黑名单消息提示去重 id
  public func removeBlackTipSendedId(messageId: String?) {
    guard let messageId = messageId else {
      return
    }

    if blackListMessageIds.contains(messageId) {
      blackListMessageIds.remove(messageId)
    }
  }

  // 是否已经发过对应路径的音频消息，防止重复发送
  public func isRecordAudioSended(path: String) -> Bool {
    if recordAudioMessagePaths.contains(path) {
      return true
    }
    if recordAudioMessagePaths.count > limit {
      recordAudioMessagePaths.removeAll()
    }
    return false
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
