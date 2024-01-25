//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
@objcMembers
public class ChatDeduplicationHelper: NSObject, NIMLoginManagerDelegate {
  // 单例变量
  static let instance = ChatDeduplicationHelper()
  // 最多缓存数量，可外部修改
  public var limit = 100
  // 黑名单消息id记录
  public var blackListMessageIds = Set<String>()
  // 音频消息记录
  public var recordAudioMessagePaths = Set<String>()
  // 撤回消息记录
  public var revokeMessageIds = Set<String>()

  override private init() {
    super.init()
    NIMSDK.shared().loginManager.add(self)
  }

  deinit {
    NIMSDK.shared().loginManager.remove(self)
  }

  public func onLogin(_ step: NIMLoginStep) {
    if step == .logout {
      clearCache()
    }
  }

  public func onKickout(_ result: NIMLoginKickoutResult) {
    clearCache()
  }

  public func clearCache() {
    blackListMessageIds.removeAll()
    recordAudioMessagePaths.removeAll()
    revokeMessageIds.removeAll()
  }

  // 是否已经发送过对应消息的提示
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
