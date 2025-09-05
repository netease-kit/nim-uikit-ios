// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreText
import Foundation
import NEChatKit
import NECoreIM2Kit
import NIMSDK

@objcMembers
open class P2PChatViewModel: ChatViewModel {
  var online: Bool = false

  /// 重写初始化方法
  override public init(conversationId: String) {
    super.init(conversationId: conversationId)
  }

  /// 重写初始化方法
  override public init(conversationId: String, anchor: V2NIMMessage?) {
    super.init(conversationId: conversationId, anchor: anchor)
  }

  /// 添加子类监听
  override open func addListener() {
    super.addListener()
    chatRepo.addNotiListener(self)
    if IMKitConfigCenter.shared.enableOnlineStatus {
      SubscribeRepo.shared.addListener(self)
      subscribeOnlineStatus()
    }
  }

  deinit {
    chatRepo.removeNotiListener(self)
    if IMKitConfigCenter.shared.enableOnlineStatus {
      SubscribeRepo.shared.removeListener(self)
    }
  }

  /// 重写 获取用户展示名称
  /// - Parameters:
  ///   - accountId: 用户 accountId
  ///   - showAlias: 是否展示备注
  /// - Returns: 名称和好友信息
  override open func getShowName(_ accountId: String,
                                 _ showAlias: Bool = true) -> String {
    if NEFriendUserCache.shared.isFriend(accountId) {
      return NEFriendUserCache.shared.getShowName(accountId, showAlias)
    } else {
      return NEP2PChatUserCache.shared.getShowName(accountId, showAlias)
    }
  }

  /// 重写 获取用户展示名称
  /// - Parameters:
  ///   - accountIds: 用户 accountId 列表
  ///   - teamId: 群 id
  ///   - completion: 完成回调
  override open func loadShowName(_ accountIds: [String],
                                  _ teamId: String? = nil,
                                  _ completion: @escaping () -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", count: \(accountIds.count)")
    NEFriendUserCache.shared.loadShowName(accountIds) { users in
      for user in users ?? [] {
        // 非好友，单独缓存
        if let uid = user.user?.accountId, !NEFriendUserCache.shared.isFriend(uid) {
          NEP2PChatUserCache.shared.updateUserInfo(user)
        }
      }
      completion()
    }
  }

  /// 重写 发送消息已读回执
  /// - Parameters:
  ///   - messages: 需要发送已读回执的消息
  ///   - completion: 完成回调
  override open func markRead(messages: [V2NIMMessage], _ completion: @escaping ((any Error)?) -> Void) {
    markReadInP2P(messages: messages, completion)
  }

  /// 单人会话消息发送已读回执
  /// - Parameters:
  ///   - messages: 需要发送已读回执的消息
  ///   - completion: 完成回调
  open func markReadInP2P(messages: [V2NIMMessage], _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messages.count: \(messages.count)")

    let messages = messages.sorted { msg1, msg2 in
      msg1.createTime > msg2.createTime
    }
    for message in messages {
      if !message.isSelf, message.messageStatus.readReceiptSent == false {
        chatRepo.markP2PMessageRead(message: message, completion)
        return
      }
    }
    completion(nil)
  }

  /// 重写获取消息已读未读回执
  /// - Parameters:
  ///   - messages: 消息列表
  ///   - completion: 完成回调
  override open func getMessageReceipts(messages: [V2NIMMessage],
                                        _ completion: @escaping ([IndexPath], Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messages.count: \(messages.count)")
    getP2PMessageReceipt(messages: messages, completion)
  }

  /// 获取 P2P 消息已读未读回执
  /// - Parameters:
  ///   - messages: 消息列表
  ///   - completion: 完成回调
  open func getP2PMessageReceipt(messages: [V2NIMMessage], _ completion: @escaping ([IndexPath], Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    chatRepo.getP2PMessageReceipt(conversationId: ChatRepo.conversationId) { readReceipt, error in
      if let readReceipt = readReceipt {
        var reloadIndexs = [IndexPath]()
        for (i, model) in self.messages.enumerated() {
          if model.message?.isSelf == false {
            continue
          }

          if model.message?.messageConfig?.readReceiptEnabled == false {
            continue
          }

          if let msgCreateTime = model.message?.createTime, msgCreateTime <= readReceipt.timestamp {
            if model.readCount == 1, model.unreadCount == 0 {
              continue
            }

            model.readCount = 1
            model.unreadCount = 0
            reloadIndexs.append(IndexPath(row: i, section: 0))
          }
        }
        completion(reloadIndexs, error)
      } else {
        completion([], error)
      }
    }
  }

  /// 发送正在输入中状态
  open func sendInputTypingState() {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    if V2NIMConversationIdUtil.conversationType(ChatRepo.conversationId) == .CONVERSATION_TYPE_P2P {
      setTypingCustom(1)
    }
  }

  /// 发送结束输入中状态
  open func sendInputTypingEndState() {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    if V2NIMConversationIdUtil.conversationType(ChatRepo.conversationId) == .CONVERSATION_TYPE_P2P {
      setTypingCustom(0)
    }
  }

  /// 发送输入状态
  /// - Parameter typing: 输入状态: 1-正在输入, 0-结束输入
  open func setTypingCustom(_ typing: Int) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", typing: \(typing)")
    let content = getJSONStringFromDictionary(["typing": typing])
    let param = V2NIMSendCustomNotificationParams()
    chatRepo.sendCustomNotification(conversationId: ChatRepo.conversationId, content: content, params: param) { error in
      if let err = error {
        print("send noti success :", err)
      }
    }
  }
}

//    MARK: - NENotiListener

extension P2PChatViewModel: NENotiListener {
  /// 收到自定义系统通知回调
  /// 用于展示对方输入状态
  /// - Parameter customNotifications: 自定义系统通知
  open func onReceiveCustomNotifications(_ customNotifications: [V2NIMCustomNotification]) {
    NEALog.infoLog(
      ModuleName + " " + className(),
      desc: #function + ", customNotifications.count:\(customNotifications.count)"
    )

    // 只处理单聊的输入状态
    if V2NIMConversationIdUtil.conversationType(ChatRepo.conversationId) != .CONVERSATION_TYPE_P2P {
      return
    }

    for notification in customNotifications {
      // 只处理当前会话的输入状态
      if ChatRepo.sessionId != notification.senderId {
        continue
      }

      if let content = notification.content,
         let dic = getDictionaryFromJSONString(content) as? [String: Any],
         let typing = dic["typing"] as? Int {
        if typing == 1 {
          delegate?.remoteUserEditing()
        } else {
          delegate?.remoteUserEndEditing()
        }
      }
    }
  }
}

// MARK: - NEEventListener

extension P2PChatViewModel: NESubscribeListener {
  /// 订阅在线状态
  open func subscribeOnlineStatus() {
    guard IMKitConfigCenter.shared.enableOnlineStatus else {
      return
    }

    if NEAIUserManager.shared.isAIUser(ChatRepo.sessionId) {
      return
    }

    if let event = NESubscribeManager.shared.getSubscribeStatus(ChatRepo.sessionId) {
      online = event.statusType == .USER_STATUS_TYPE_LOGIN
      return
    }

    NESubscribeManager.shared.subscribeUsersOnlineState([ChatRepo.sessionId]) { error in
    }
  }

  /// 取消订阅
  open func unsubscribeOnlineStatus() {
    NESubscribeManager.shared.unSubscribeUsersOnlineState([ChatRepo.sessionId]) { error in
    }
  }

  /// 用户状态变更
  /// - Parameter data: 用户状态列表
  public func onUserStatusChanged(_ data: [V2NIMUserStatus]) {
    for d in data {
      if d.accountId == ChatRepo.sessionId {
        online = d.statusType == .USER_STATUS_TYPE_LOGIN
        delegate?.remoteUserOnlineChanged()
        break
      }
    }
  }
}

// MARK: - NEIMKitClientListener

extension P2PChatViewModel: NEIMKitClientListener {
  /// 登录连接状态回调
  /// - Parameter status: 连接状态
  open func onConnectStatus(_ status: V2NIMConnectStatus) {
    if status == .CONNECT_STATUS_WAITING {
      networkBroken = true
    }

    if status == .CONNECT_STATUS_CONNECTED, networkBroken {
      networkBroken = false
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: DispatchWorkItem(block: { [weak self] in
        self?.subscribeOnlineStatus()
      }))
    }
  }
}
