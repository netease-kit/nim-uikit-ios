// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreMedia
import Foundation
import NECommonKit
import NECoreIM2Kit
import NIMSDK

/// 通知监听回调
@objc
public protocol NENotiListener: NSObjectProtocol {
  /// 收到自定义系统通知回调
  /// - Parameter messages: 系统通知列表
  @objc optional func onReceiveCustomNotifications(_ customNotifications: [V2NIMCustomNotification])

  /// 收到全员广播通知回调
  /// - Parameter boradcastNotifications: 全员广播通知列表
  @objc optional func onReceiveBroadcastNotifications(_ boradcastNotifications: [V2NIMBroadcastNotification])
}

/// 消息监听回调
@objc
public protocol NEMessageListener: NSObjectProtocol {
  /// 本端即将发送消息状态回调，此时消息还未发送，可对消息进行修改或者拦截发送
  /// 来源： 发送消息， 插入消息
  /// - Parameter param: 消息参数，包含消息、会话 id、发送参数
  /// - Returns: （修改后的）消息参数，若消息参数为 nil，则表示拦截该消息不发送
  @objc optional func beforeSend(_ param: MessageSendParams) -> MessageSendParams?

  /// 本端即将发送消息状态回调，此时消息还未发送，可对消息进行修改或者拦截发送
  /// 来源： 发送消息， 插入消息
  /// - Parameter param: 消息参数，包含消息、会话 id、发送参数
  /// - Parameter completion: （修改后的）消息参数，若消息参数为 nil，则表示拦截该消息不发送
  @objc optional func beforeSend(_ param: MessageSendParams, _ completion: @escaping (MessageSendParams?) -> Void)

  /// 本端发送消息后的回调，为 sendMessage 接口callback，可在回调中获取消息反垃圾结果
  /// - Parameter result: 发送结果
  /// - Parameter error: 失败详情
  /// - Parameter progress: 发送进度
  @objc optional func sendMessageCallback(_ result: V2NIMSendMessageResult?, _ error: V2NIMError?, _ progress: UInt)
}

/// 消息监听回调
@objc
public protocol NEChatListener: NSObjectProtocol {
  /// 本端发送消息状态回调，此时消息已经发送
  /// 来源： 发送消息， 插入消息
  /// - Parameter message: 消息
  @objc optional func onSendMessage(_ message: V2NIMMessage)

  /// 消息发送失败
  /// - Parameters:
  ///   - message: 消息
  ///   - error: 错误信息
  @objc optional func sendMessageFailed(_ message: V2NIMMessage, _ error: NSError)

  /// 收到消息回调
  /// - Parameter messages: 消息列表
  @objc optional func onReceiveMessages(_ messages: [V2NIMMessage])

  /// 收到点对点已读回执
  /// - Parameter readReceipts: 已读回执
  @objc optional func onReceiveP2PMessageReadReceipts(_ readReceipts: [V2NIMP2PMessageReadReceipt])

  /// 收到群已读回执
  /// - Parameter readReceipts: 已读回执
  @objc optional func onReceiveTeamMessageReadReceipts(_ readReceipts: [V2NIMTeamMessageReadReceipt])

  /// 收到消息撤回回调
  /// - Parameter revokeNotifications: 消息撤回通知数据
  @objc optional func onMessageRevokeNotifications(_ revokeNotifications: [V2NIMMessageRevokeNotification])

  /// 消息pin状态回调通知
  /// - Parameter pinNotification: 消息pin状态变化通知数据
  @objc optional func onMessagePinNotification(_ pinNotification: V2NIMMessagePinNotification)

  /// 消息评论状态回调
  /// - Parameter notification: 快捷评论通知数据
  @objc optional func onMessageQuickCommentNotification(_ notification: V2NIMMessageQuickCommentNotification)

  /// 消息被删除通知
  /// - Parameter messageDeletedNotification: 被删除的消息列表
  @objc optional func onMessageDeletedNotifications(_ messageDeletedNotification: [V2NIMMessageDeletedNotification])

  /// 消息被清空通知
  /// - Parameter clearHistoryNotification: 清空的会话列表
  @objc optional func onClearHistoryNotifications(_ clearHistoryNotification: [V2NIMClearHistoryNotification])

  /// 更新消息在线同步通知
  /// 更新消息多端同步通知
  /// 更新消息漫游通知
  /// - Parameter messages: 被修改的消息列表
  @objc optional func onReceiveMessagesModified(_ messages: [V2NIMMessage])
}

@objcMembers
public class ChatRepo: NSObject, V2NIMMessageListener, V2NIMNotificationListener {
  public static let shared = ChatRepo()
  public static var conversationId = ""
  public static var sessionId = ""
  private let messageMutiDelegate = MultiDelegate<NEMessageListener>(strongReferences: false)
  private let chatMutiDelegate = MultiDelegate<NEChatListener>(strongReferences: false)
  private let notiMutiDelegate = MultiDelegate<NENotiListener>(strongReferences: false)

  /// 聊天Provider
  public let chatProvider = ChatProvider.shared

  /// 通知Provider
  public let notificationProvider = NotificationProvider.shared

  override private init() {
    super.init()
    addMessageListener(self)
    addNoticationListener(self)
  }

  /// 默认的消息配置
  open func messageConfig() -> V2NIMMessageConfig {
    let messageConfig = V2NIMMessageConfig()
    messageConfig.readReceiptEnabled = true
    messageConfig.lastMessageUpdateEnabled = true
    messageConfig.historyEnabled = true
    messageConfig.roamingEnabled = true
    messageConfig.onlineSyncEnabled = true
    messageConfig.offlineEnabled = true
    messageConfig.unreadEnabled = true
    return messageConfig
  }

  /// 默认的消息配置
  open func pushConfig() -> V2NIMMessagePushConfig {
    if let pushConfig = SettingRepo.shared.getMessagePushConfig() {
      return pushConfig
    }

    return V2NIMMessagePushConfig()
  }

  /// 默认的消息发送相关参数
  open func getSendMessageParams() -> V2NIMSendMessageParams {
    let param = V2NIMSendMessageParams()
    param.messageConfig = messageConfig()
    param.pushConfig = pushConfig()
    return param
  }

  // MARK: - 代理

  /// 添加消息发送拦截器
  /// - Parameter listener: 监听器
  open func addMessageSendListener(_ listener: NEMessageListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    messageMutiDelegate.addDelegate(listener)
  }

  /// 移除消息发送拦截器
  /// - Parameter listener: 监听器
  open func removeMessageSendListener(_ listener: NEMessageListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    messageMutiDelegate.removeDelegate(listener)
  }

  /// 添加消息监听器
  /// - Parameter listener: 监听器
  open func addChatListener(_ listener: NEChatListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    chatMutiDelegate.addDelegate(listener)
  }

  /// 移除消息监听器
  /// - Parameter listener: 监听器
  open func removeChatListener(_ listener: NEChatListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    chatMutiDelegate.removeDelegate(listener)
  }

  /// 添加消息监听器
  /// - Parameter listener: 监听器
  open func addMessageListener(_ listener: V2NIMMessageListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    chatProvider.addMessageListener(listener: listener)
  }

  /// 移除消息监听器
  /// - Parameter listener: 监听器
  open func removeMessageListener(_ listener: V2NIMMessageListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    chatProvider.removeMessageListener(listener: listener)
  }

  /// 添加系统通知监听
  /// - Parameter listener: 监听器
  open func addNotiListener(_ listener: NENotiListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    notiMutiDelegate.addDelegate(listener)
  }

  /// 移除系统通知监听
  /// - Parameter listener: 监听器
  open func removeNotiListener(_ listener: NENotiListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    notiMutiDelegate.removeDelegate(listener)
  }

  /// 添加系统通知监听
  /// - Parameter listener: 监听器
  open func addNoticationListener(_ listener: V2NIMNotificationListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    notificationProvider.addNoticationListener(listener: listener)
  }

  /// 移除系统通知监听
  /// - Parameter listener: 监听器
  open func removeNoticationListener(_ listener: V2NIMNotificationListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    notificationProvider.removeNoticationListener(listener: listener)
  }

  // MARK: - notificationProvider

  /// 发送自定义通知
  /// - Parameters:
  ///   - converstaionId: 会话Id
  ///   - content: 通知内容
  ///   - params: 自定义通知参数
  ///   - completion: 完成回调
  open func sendCustomNotification(conversationId: String,
                                   content: String,
                                   params: V2NIMSendCustomNotificationParams,
                                   _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " conversationId: \(conversationId) content: \(content) params: \(params.description)")
    notificationProvider.sendCustomNotification(converstaionId: conversationId, content: content, params: params) { error in
      completion(error?.nserror)
    }
  }

  // MARK: - chatProvider

  /// 发送消息（私有方法），直接发送
  /// - Parameters:
  ///   - message: 消息对象
  ///   - session: 接收方
  ///   - completion: 发送完成后的回调，这里的回调完成只表示当前这个函数调用完成，需要后续的回调才能判断消息是否已经发送至服务器
  private func toSendMessage(message: V2NIMMessage,
                             conversationId: String,
                             params: V2NIMSendMessageParams? = nil,
                             _ completion: @escaping (V2NIMSendMessageResult?, NSError?, UInt) -> Void) {
    chatProvider.sendMessage(message: message,
                             conversationId: conversationId,
                             params: params) { [weak self] result, error, progress in
      guard let self = self else { return }

      if let err = error?.nserror as? NSError {
        self.chatMutiDelegate |> { delegate in
          delegate.sendMessageFailed?(message, err)
        }
      }

      if let _ = ChatKitClient.shared.sendMessageCallback {
        messageMutiDelegate |> { delegate in
          delegate.sendMessageCallback?(result, error, progress)
        }
      }

      completion(result, error?.nserror as? NSError, progress)
    }
  }

  /// 发送消息
  /// - Parameters:
  ///   - message: 消息对象
  ///   - conversationId: 会话 id
  ///   - params: 消息发送相关参数
  ///   - completion: 发送完成后的回调，这里的回调完成只表示当前这个函数调用完成，需要后续的回调才能判断消息是否已经发送至服务器
  open func sendMessage(message: V2NIMMessage,
                        conversationId: String,
                        params: V2NIMSendMessageParams? = nil,
                        _ completion: @escaping (V2NIMSendMessageResult?, NSError?, UInt) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " message: \(message.description)")
    let params = params ?? getSendMessageParams()
    if message.senderId == nil {
      message.senderId = IMKitClient.instance.account()
    }

    if message.conversationId == nil {
      message.conversationId = conversationId
    }

    if messageMutiDelegate.isEmpty {
      toSendMessage(message: message, conversationId: conversationId, params: params, completion)
      return
    }

    messageMutiDelegate |> { delegate in
      let oldParams = MessageSendParams(message: message, conversationId: conversationId, params: params)
      if delegate.responds(to: #selector(delegate.beforeSend(_:))) {
        if let sendParams = delegate.beforeSend?(oldParams) {
          let finalMessage = sendParams.message

          var finalParams = params
          if let param = sendParams.params {
            finalParams = param
          }

          // 发送消息
          toSendMessage(message: finalMessage, conversationId: conversationId, params: finalParams, completion)
        }
      } else if delegate.responds(to: #selector(delegate.beforeSend(_:_:))) {
        delegate.beforeSend?(oldParams) { [weak self] sendParams in
          // 消息被拦截
          guard let sendParams = sendParams else {
            completion(nil, nil, 0)
            return
          }

          let finalMessage = sendParams.message

          var finalParams = params
          if let param = sendParams.params {
            finalParams = param
          }

          // 发送消息
          self?.toSendMessage(message: finalMessage, conversationId: conversationId, params: finalParams, completion)
        }
      }
    }
  }

  /// 回复消息（私有方法），直接发送
  /// - Parameters:
  ///   - message: 消息对象
  ///   - session: 接收方
  ///   - completion: 发送完成后的回调，这里的回调完成只表示当前这个函数调用完成，需要后续的回调才能判断消息是否已经发送至服务器
  private func toReplyMessage(message: V2NIMMessage,
                              replyMessage: V2NIMMessage,
                              params: V2NIMSendMessageParams,
                              _ completion: @escaping (V2NIMSendMessageResult?, NSError?, UInt) -> Void) {
    chatProvider.replyMessage(message: message, replyMessage: replyMessage, params: params) { [weak self] result, error, progress in
      guard let self = self else { return }

      if let err = error?.nserror as? NSError {
        self.chatMutiDelegate |> { delegate in
          delegate.sendMessageFailed?(message, err)
        }
      }

      if let _ = ChatKitClient.shared.sendMessageCallback {
        messageMutiDelegate |> { delegate in
          delegate.sendMessageCallback?(result, error, progress)
        }
      }

      completion(result, error?.nserror as? NSError, progress)
    }
  }

  /// 回复消息
  /// - Parameters:
  ///   - message: 需要发送的消息体
  ///   - replyMessage: 被回复的消息
  ///   - params: 发送消息相关配置参数
  ///   - completion: 完成回调
  open func replyMessage(message: V2NIMMessage,
                         replyMessage: V2NIMMessage,
                         params: V2NIMSendMessageParams,
                         _ completion: @escaping (V2NIMSendMessageResult?, NSError?, UInt) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", message:\(message.description), replyMessage:\(replyMessage.description)")

    if messageMutiDelegate.isEmpty {
      toReplyMessage(message: message, replyMessage: replyMessage, params: params, completion)
      return
    }

    messageMutiDelegate |> { delegate in
      let oldParams = MessageSendParams(message: message, conversationId: replyMessage.conversationId, params: params)
      if let sendParams = delegate.beforeSend?(oldParams) {
        let finalMessage = sendParams.message

        var finalParams = params
        if let param = sendParams.params {
          finalParams = param
        }

        // 回复消息
        toReplyMessage(message: finalMessage, replyMessage: replyMessage, params: finalParams, completion)
      } else if delegate.responds(to: #selector(delegate.beforeSend(_:_:))) {
        delegate.beforeSend?(oldParams) { [weak self] sendParams in
          // 消息被拦截
          guard let sendParams = sendParams else {
            completion(nil, nil, 0)
            return
          }

          let finalMessage = sendParams.message

          var finalParams = params
          if let param = sendParams.params {
            finalParams = param
          }

          // 回复消息
          self?.toReplyMessage(message: finalMessage, replyMessage: replyMessage, params: finalParams, completion)
        }
      }
    }
  }

  /// 插入一条本地消息， 该消息不会
  /// 该消息不会多端同步，只是本端显示
  /// 插入成功后， SDK会抛出回调
  /// - Parameters:
  ///   - message: 需要插入的消息体
  ///   - conversationId: 会话 ID
  ///   - senderId: 发送者 id
  ///   - createTime: 消息创建时间
  ///   - completion: 完成回调
  open func insertMessageToLocal(message: V2NIMMessage,
                                 conversationId: String,
                                 senderId: String? = nil,
                                 createTime: TimeInterval? = nil,
                                 _ completion: @escaping (V2NIMMessage?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", conversationId:\(conversationId), senderId:\(String(describing: senderId)), createTime:\(String(describing: createTime)), message:\(message.description)")
    chatProvider.insertMessageToLocal(message: message,
                                      conversationId: conversationId,
                                      senderId: senderId ?? IMKitClient.instance.account(),
                                      createTime: createTime ?? Date().timeIntervalSince1970) { message, error in
      if let err = error?.nserror as? NSError {
        completion(nil, err)
      } else {
        completion(message, nil)
      }
    }
  }

  /// 查询历史消息，分页接口，每次默认50条，可以根据参数组合查询各种类型
  /// - Parameters:
  ///   - option: 查询消息配置选项
  ///   - completion: 完成回调
  open func getMessageList(option: V2NIMMessageListOption,
                           _ completion: @escaping ([V2NIMMessage]?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", anchorMessage.messageClientId:\(String(describing: option.anchorMessage?.messageClientId))")
    chatProvider.getMessageList(option: option) { messages, error in
      completion(messages, error?.nserror as? NSError)
    }
  }

  /// 根据MessageRefer列表查询消息（本地+远端）
  /// - Parameters:
  ///   - messageRefers: 需要查询的消息Refer列表
  ///   - completion: 完成回调
  open func getMessageListByRefers(_ messageRefers: [V2NIMMessageRefer],
                                   _ completion: @escaping ([V2NIMMessage]?, NSError?) -> Void) {
    if messageRefers.count <= 0 {
      NEALog.errorLog(ModuleName + " " + className(), desc: #function + ", messageIds is empty")
      completion(nil, nil)
      return
    }

    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " refers: \(messageRefers.description)")
    chatProvider.getMessageListByRefers(messageRefers: messageRefers) { messages, error in
      if let err = error {
        completion(nil, err as? NSError)
      } else {
        completion(messages, nil)
      }
    }
  }

  /// 搜索消息，云端搜索
  /// - Parameters:
  ///   - params: 搜索选项
  ///   - completion: 完成后的回调
  open func searchCloudMessages(params: V2NIMMessageSearchParams,
                                _ completion: @escaping ([HistoryMessageModel]?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", params:\(params.description)")

    ChatProvider.shared.searchCloudMessages(params: params) { messages, error in
      if error == nil {
        NEALog.infoLog(
          ModuleName + " " + ChatRepo.className(),
          desc: "CALLBACK searchCloudMessages SUCCESS"
        )
        var resultArr = [HistoryMessageModel]()
        messages?.forEach { message in
          let messageModel = HistoryMessageModel()
          messageModel.imMessage = message
          messageModel.content = message.text
          resultArr.append(messageModel)
        }

        completion(resultArr, nil)
      } else {
        NEALog.errorLog(
          ModuleName + " " + ChatRepo.className(),
          desc: "CALLBACK searchCloudMessages failed,error = \(error!)"
        )
        completion(nil, error?.nserror as? NSError)
      }
    }
  }

  /// 搜索消息，云端搜索
  /// - Parameters:
  ///   - params: 搜索选项
  ///   - completion: 完成后的回调
  open func searchCloudMessagesEx(params: V2NIMMessageSearchExParams,
                                  _ completion: @escaping (V2NIMMessageSearchResult?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", params:\(params.description)")

    ChatProvider.shared.searchCloudMessagesEx(params: params) { result, error in
      if error == nil {
        NEALog.infoLog(
          ModuleName + " " + ChatRepo.className(),
          desc: "CALLBACK searchLocalMessages SUCCESS"
        )
        completion(result, nil)
      } else {
        NEALog.errorLog(
          ModuleName + " " + ChatRepo.className(),
          desc: "CALLBACK searchLocalMessages failed,error = \(error!)"
        )
        completion(nil, error?.nserror as? NSError)
      }
    }
  }

  /// 搜索消息，本地端搜索
  /// - Parameters:
  ///   - params: 搜索选项
  ///   - completion: 完成后的回调
  open func searchLocalMessages(params: V2NIMMessageSearchExParams,
                                _ completion: @escaping (V2NIMMessageSearchResult?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", params:\(params.description)")

    ChatProvider.shared.searchLocalMessages(params: params) { result, error in
      if error == nil {
        NEALog.infoLog(
          ModuleName + " " + ChatRepo.className(),
          desc: "CALLBACK searchLocalMessages SUCCESS"
        )
        completion(result, nil)
      } else {
        NEALog.errorLog(
          ModuleName + " " + ChatRepo.className(),
          desc: "CALLBACK searchLocalMessages failed,error = \(error!)"
        )
        completion(nil, error?.nserror as? NSError)
      }
    }
  }

  /// 发送单聊消息已读回执
  /// - Parameters:
  ///   - message: 需要发送已读回执的消息
  ///   - completion: 完成回调
  open func markP2PMessageRead(message: V2NIMMessage,
                               _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", message:\(message.description)")
    chatProvider.sendP2PMessageReceipt(message: message) { error in
      completion(error?.nserror as? NSError)
    }
  }

  /// 发送群消息已读回执
  /// 所有消息必须属于同一个会话
  /// - Parameters:
  ///   - messages: 需要发送已读回执的消息列表
  ///   - completion: 完成回调
  open func markTeamMessagesRead(messages: [V2NIMMessage],
                                 _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messages.count: \(messages.count)")
    let chunkMessages = messages.chunk(50)
    for msgs in chunkMessages {
      chatProvider.sendTeamMessageReceipts(messages: msgs) { error in
        completion(error?.nserror as? NSError)
      }
    }
  }

  /// 删除消息
  /// 如果消息未发送成功,则只删除本地消息
  /// - Parameters:
  ///   - message: 需要删除的消息
  ///   - serverExtension: 扩展字段
  ///   - onlyDeleteLocal: 是否只删除本地消息
  ///   true：只删除本地，本地会将该消息标记为删除,getMessage会过滤该消息，界面不展示，卸载重装会再次显示
  ///   fasle：同时删除云端
  ///   - completion: 完成回调
  open func deleteMessage(message: V2NIMMessage,
                          serverExtension: String = "",
                          onlyDeleteLocal: Bool,
                          _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", message:\(message.description)")
    chatProvider.deleteMessage(message: message, serverExtension: serverExtension, onlyDeleteLocal: onlyDeleteLocal) { error in
      completion(error?.nserror as? NSError)
    }
  }

  /// 批量删除消息
  /// 如果单条消息未发送成功， 则只删除本地消息
  /// 每次50条, 不能跨会话删除,所有消息都属于同一个会话
  /// 删除本地消息不会多端同步，删除云端会多端同步
  /// - Parameters:
  ///   - messages: 需要删除的消息列表
  ///   - serverExtension: 扩展字段
  ///   - onlyDeleteLocal: 是否只删除本地消息
  ///   true：只删除本地，本地会将该消息标记为删除， getHistoryMessage会过滤该消息，界面不展示，卸载重装会再次显示
  ///   fasle：同时删除云端
  ///   - completion: 完成回调
  open func deleteMessages(messages: [V2NIMMessage],
                           serverExtension: String = "",
                           onlyDeleteLocal: Bool,
                           _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", message count:\(messages.count)")
    let chunkMsgs = messages.chunk(50)
    for msgs in chunkMsgs {
      chatProvider.deleteMessages(messages: msgs, serverExtension: serverExtension, onlyDeleteLocal: onlyDeleteLocal) { error in
        completion(error?.nserror as? NSError)
      }
    }
  }

  /// 清空历史消息
  /// 同步删除本地消息，云端消息
  /// 会话不会被删除
  /// - Parameters:
  ///   - option: 清空消息配置选项
  ///   - completion: 完成回调
  open func clearHistoryMessage(option: V2NIMClearHistoryMessageOption,
                                _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " option:\(option.description)")
    chatProvider.clearHistoryMessage(option: option) { error in
      completion(error?.nserror as? NSError)
    }
  }

  /// 撤回消息
  /// 只能撤回已经发送成功的消息
  /// - Parameters:
  ///   - message: 要撤回的消息
  ///   - params: 撤回消息相关参数
  ///   - completion: 完成回调
  open func revokeMessage(message: V2NIMMessage,
                          params: V2NIMMessageRevokeParams,
                          _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageClientId:\(String(describing: message.messageClientId))")
    chatProvider.revokeMessage(message: message, revokeParams: params) { error in
      completion(error?.nserror as? NSError)
    }
  }

  /// 查询单聊消息已读回执
  /// - Parameters:
  ///   - conversationId: 需要查询已读回执的会话
  ///   - completion: 完成回调
  open func getP2PMessageReceipt(conversationId: String,
                                 _ completion: @escaping (V2NIMP2PMessageReadReceipt?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", conversationId:\(conversationId)")
    chatProvider.getP2PMessageReceipt(conversationId: conversationId) { readReceipt, error in
      completion(readReceipt, error?.nserror as? NSError)
    }
  }

  /// 查询群消息已读回执状态
  /// - Parameters:
  ///   - messages: 需要查询已读回执状态的消息
  ///   - completion: 完成回调
  open func getTeamMessageReceipts(messages: [V2NIMMessage],
                                   _ completion: @escaping ([V2NIMTeamMessageReadReceipt]?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messages count:\(messages.count)")
    chatProvider.getTeamMessageReceipts(messages: messages) { readReceipts, error in
      completion(readReceipts, error?.nserror as? NSError)
    }
  }

  /// 获取群消息已读回执状态详情
  /// - Parameters:
  ///   - message: 需要查询已读回执状态的消息
  ///   - memberAccountIds: 查找指定的账号列表已读未读
  ///   - completion: 完成回调
  open func getTeamMessageReceiptDetail(message: V2NIMMessage,
                                        memberAccountIds: Set<String>,
                                        _ completion: @escaping (V2NIMTeamMessageReadReceiptDetail?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messagesId:\(String(describing: message.messageClientId))")
    chatProvider.getTeamMessageReceiptDetail(message: message, memberAccountIds: memberAccountIds) { readReceiptDetail, error in
      completion(readReceiptDetail, error?.nserror as? NSError)
    }
  }

  /// 添加一条PIN记录
  /// - Parameters:
  ///   - message: 需要被pin的消息体
  ///   - serverExtension: 扩展字段
  ///   - completion: 完成回调
  open func pinMessage(message: V2NIMMessage,
                       serverExtension: String,
                       _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(),
                   desc: #function + ", messageClientId:\(String(describing: message.messageClientId)), \(String(describing: message.text))")
    chatProvider.pinMessage(message: message, serverExtension: serverExtension) { error in
      completion(error?.nserror as? NSError)
    }
  }

  /// 删除一条PIN记录
  /// - Parameters:
  ///   - messageRefer: 需要被unpin的消息体
  ///   - serverExtension: 扩展字段
  ///   - completion: 完成回调
  open func unpinMessage(messageRefer: V2NIMMessageRefer,
                         serverExtension: String,
                         _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", sessionId:\(String(describing: messageRefer.messageClientId))")
    chatProvider.unpinMessage(messageRefer: messageRefer, serverExtension: serverExtension) { error in
      completion(error?.nserror as? NSError)
    }
  }

  /// 获取 pin 消息列表
  /// - Parameters:
  ///   - conversationId: 会话 id
  ///   - completion: 完成回调
  open func getPinnedMessageList(conversationId: String,
                                 _ completion: @escaping ([V2NIMMessagePin]?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", conversationId:\(conversationId)")
    chatProvider.getPinnedMessageList(conversationId: conversationId) { pinList, error in
      completion(pinList, error?.nserror as? NSError)
    }
  }

  /// 添加收藏
  /// - Parameters:
  ///   - params: 添加收藏参数
  ///   - completion: 完成回调
  open func addCollection(_ params: V2NIMAddCollectionParams,
                          _ completion: @escaping (V2NIMCollection?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " params:\(params.description)")
    chatProvider.addCollection(params, completion)
  }

  /// 移除收藏
  /// - Parameters:
  ///   - collections: 要移除的收藏列表
  ///   - completion: 完成回调
  open func removeCollections(_ collections: [V2NIMCollection],
                              _ completion: @escaping (Int32?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " collections:\(collections.description)")
    chatProvider.removeCollections(collections, completion)
  }

  /// 获取收藏列表
  /// - Parameters:
  ///   - option: 查询参数
  ///   - completion: 完成回调
  open func getCollections(_ option: V2NIMCollectionOption,
                           _ completion: @escaping ([V2NIMCollection]?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " option:\(option.description)")
    chatProvider.getCollectionList(option, completion)
  }

  /// 语音转文字
  /// - Parameter params: 语音转文字参数
  /// - Parameter completion: 完成回调
  open func voiceToText(_ params: V2NIMVoiceToTextParams, _ completion: @escaping (String?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " params:\(params.description)")
    chatProvider.voiceToText(params, completion)
  }

  /// 停止流式输出数字人消息
  /// - Parameters:
  ///   - message: 需要停止输出的数字人消息
  ///   - params: 停止数字人流式输出配置参数
  ///   - completion: 完成回调
  open func stopAIStreamMessage(_ message: V2NIMMessage,
                                _ params: V2NIMMessageAIStreamStopParams,
                                _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " messageId: \(String(describing: message.messageClientId)) params:\(params.description)")
    chatProvider.stopAIStreamMessage(message, params, completion)
  }

  /// 重新输出数字人消息
  /// - Parameters:
  ///   - message: 需要重新输出的数字人消息
  ///   - params: 重新输出数字人消息配置参数
  ///   - completion: 完成回调
  open func regenAIMessage(_ message: V2NIMMessage,
                           _ params: V2NIMMessageAIRegenParams,
                           _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " messageId: \(String(describing: message.messageClientId)) params:\(params.description)")
    chatProvider.regenAIMessage(message, params, completion)
  }

  /// 更新消息接口
  /// - Parameters:
  ///   - message: 需要更新的消息
  ///   - params: 消息更新参数，可更新字段：subType， text， attachment， serverExtension， 消息类型不允许变更、文件类型不可更新attachment，更新时可以配置反垃圾，反垃圾配置可以和原消息不一致
  ///   - completion: 完成回调
  open func modifyMessage(_ message: V2NIMMessage,
                          _ params: V2NIMModifyMessageParams,
                          _ completion: @escaping (V2NIMModifyMessageResult?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " params: \(params.description)")
    NIMSDK.shared().v2MessageService.modifyMessage(message, params: params) { result in
      completion(result, nil)
    } failure: { error in
      completion(nil, error.nserror as NSError)
    }
  }

  /// 更新 Pin 消息
  /// - Parameters:
  ///   - message: 需要更新 pin 的消息体
  ///   - serverExtension: 扩展字段
  ///   - completion: 完成回调
  open func updatePinMessage(message: V2NIMMessage,
                             serverExtension: String,
                             _ completion: @escaping (V2NIMError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " message:\(message.description)")
    ChatProvider.shared.updatePinMessage(message: message, serverExtension: serverExtension) { error in
      completion(error)
    }
  }

  /// 获取消息列表（扩展版）
  /// - Parameters:
  ///   - option: 查询选项
  ///   - completion: 完成回调
  open func getMessageListEx(option: V2NIMMessageListOption,
                             _ completion: @escaping (V2NIMMessageListResult?, V2NIMError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " option:\(option.description)")
    ChatProvider.shared.getMessageListEx(option: option) { messages, error in
      completion(messages, error)
    }
  }

  /// 获取云端消息列表
  /// - Parameters:
  ///   - option: 查询选项
  ///   - completion: 完成回调
  open func getCloudMessageList(option: V2NIMCloudMessageListOption,
                                _ completion: @escaping (V2NIMMessageListResult?, V2NIMError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " option:\(option.description)")
    ChatProvider.shared.getCloudMessageList(option: option) { messages, error in
      completion(messages, error)
    }
  }

  /// 获取 Thread 消息列表（云端）
  /// - Parameters:
  ///   - option: Thread 消息查询选项
  ///   - completion: 完成回调
  open func getThreadMessageList(option: V2NIMThreadMessageListOption,
                                 _ completion: @escaping (V2NIMThreadMessageListResult?, V2NIMError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " option:\(option.description)")
    ChatProvider.shared.getThreadMessageList(option: option) { result, error in
      completion(result, error)
    }
  }

  /// 获取 Thread 消息列表（本地）
  /// - Parameters:
  ///   - messageRefer: 根消息引用
  ///   - completion: 完成回调
  open func getLocalThreadMessageList(messageRefer: V2NIMMessageRefer,
                                      _ completion: @escaping (V2NIMThreadMessageListResult?, V2NIMError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " messageRefer:\(messageRefer.description)")
    ChatProvider.shared.getLocalThreadMessageList(messageRefer: messageRefer) { result, error in
      completion(result, error)
    }
  }

  /// 更新消息本地扩展字段
  /// - Parameters:
  ///   - message: 需要更新的消息体
  ///   - localExtension: 新的本地扩展字段
  ///   - completion: 完成回调
  open func updateMessageLocalExtension(message: V2NIMMessage,
                                        localExtension: String,
                                        _ completion: @escaping (V2NIMMessage?, V2NIMError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " message:\(message.description)")
    ChatProvider.shared.updateMessageLocalExtension(message: message, localExtension: localExtension) { msg, error in
      completion(msg, error)
    }
  }

  /// 更新本地消息
  /// - Parameters:
  ///   - message: 需要更新的消息体
  ///   - params: 更新参数
  ///   - completion: 完成回调
  open func updateLocalMessage(message: V2NIMMessage,
                               params: V2NIMUpdateLocalMessageParams,
                               _ completion: @escaping (V2NIMMessage?, V2NIMError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " message:\(message.description)")
    ChatProvider.shared.updateLocalMessage(message: message, params: params) { msg, error in
      completion(msg, error)
    }
  }

  /// 插入本地消息（扩展版）
  /// - Parameters:
  ///   - message: 需要插入的消息体
  ///   - params: 插入参数
  ///   - completion: 完成回调
  open func insertMessageToLocalEx(message: V2NIMMessage,
                                   params: V2NIMMessageInsertParams,
                                   _ completion: @escaping (V2NIMMessage?, V2NIMError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " message:\(message.description)")
    ChatProvider.shared.insertMessageToLocalEx(message: message, params: params) { msg, error in
      completion(msg, error)
    }
  }

  /// 批量导入本地消息
  /// - Parameters:
  ///   - messages: 消息列表
  ///   - option: 导入配置
  ///   - completion: 完成回调
  open func importMessagesToLocal(messages: [V2NIMMessage],
                                  option: V2NIMImportMessagesToLocalOption,
                                  _ completion: @escaping (V2NIMError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " messages count: \(messages.count)")
    ChatProvider.shared.importMessagesToLocal(messages: messages, option: option) { error in
      completion(error)
    }
  }

  /// 清除漫游消息（云端）
  /// - Parameters:
  ///   - conversationIds: 会话 ID 列表
  ///   - completion: 完成回调
  open func clearRoamingMessage(conversationIds: [String],
                                _ completion: @escaping (V2NIMError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " conversationIds: \(conversationIds)")
    ChatProvider.shared.clearRoamingMessage(conversationIds: conversationIds) { error in
      completion(error)
    }
  }

  /// 清空本地消息
  /// - Parameters:
  ///   - params: 清空参数，nil 表示全部清空
  ///   - completion: 完成回调
  open func clearLocalMessage(params: V2NIMClearLocalMessageParams?,
                              _ completion: @escaping (V2NIMError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    ChatProvider.shared.clearLocalMessage(params: params) { error in
      completion(error)
    }
  }

  /// 更新收藏扩展字段
  /// - Parameters:
  ///   - collection: 需要更新的收藏对象
  ///   - serverExtension: 新的扩展字段
  ///   - completion: 完成回调
  open func updateCollectionExtension(collection: V2NIMCollection,
                                      serverExtension: String,
                                      _ completion: @escaping (V2NIMCollection?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " collection:\(collection.description)")
    ChatProvider.shared.updateCollectionExtension(collection: collection, serverExtension: serverExtension) { updated, error in
      completion(updated, error)
    }
  }

  /// 获取收藏列表（扩展版，含分页游标）
  /// - Parameters:
  ///   - option: 查询参数
  ///   - completion: 完成回调
  open func getCollectionListEx(_ option: V2NIMCollectionOption,
                                _ completion: @escaping (V2NIMCollectionListResult?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " option:\(option.description)")
    ChatProvider.shared.getCollectionListEx(option) { result, error in
      completion(result, error)
    }
  }

  /// 取消消息附件上传
  /// - Parameters:
  ///   - message: 需要取消上传附件的消息
  ///   - completion: 完成回调
  open func cancelMessageAttachmentUpload(_ message: V2NIMMessage,
                                          _ completion: @escaping (V2NIMError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " message:\(message.description)")
    ChatProvider.shared.cancelMessageAttachmentUpload(message) { error in
      completion(error)
    }
  }

  /// 翻译文本
  /// - Parameters:
  ///   - params: 翻译参数
  ///   - completion: 完成回调
  open func translateText(params: V2NIMTextTranslateParams,
                          _ completion: @escaping (V2NIMTextTranslationResult?, V2NIMError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " params:\(params.description)")
    ChatProvider.shared.translateText(params: params) { result, error in
      completion(result, error)
    }
  }

  // MARK: - 消息翻译（Translation）

  /// 翻译任意文本字符串（支持 @ 保留：调用方可传入切分后的单个片段）
  /// - Parameters:
  ///   - text: 需要翻译的文本
  ///   - targetLanguage: 目标语言代码，如 "zh-CHS"、"en"
  ///   - completion: 回调，成功返回译文字符串，失败返回 error
  open func translateTextContent(_ text: String,
                                 targetLanguage: String,
                                 _ completion: @escaping (String?, Error?) -> Void) {
    guard !text.isEmpty else {
      completion(nil, NSError(domain: "TranslationError", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "text is empty"]))
      return
    }
    let params = V2NIMTextTranslateParams()
    params.text = text
    params.targetLanguage = targetLanguage
    params.sourceLanguage = ""
    translateText(params: params) { result, error in
      if let err = error {
        completion(nil, err.nserror as NSError)
      } else if let translated = result?.translatedText, !translated.isEmpty {
        completion(translated, nil)
      } else {
        completion(nil, NSError(domain: "TranslationError", code: -2,
                                userInfo: [NSLocalizedDescriptionKey: "empty translation result"]))
      }
    }
  }

  /// 翻译消息文本（UIKit 层唯一入口，禁止直接调用 translateText）
  /// - Parameters:
  ///   - message: 需要翻译的消息（类型须为文本消息）
  ///   - targetLanguage: 目标语言代码，如 "zh-CHS"、"en"
  ///   - completion: 回调，成功返回译文字符串，失败返回 error
  open func translateMessage(message: V2NIMMessage,
                             targetLanguage: String,
                             _ completion: @escaping (String?, Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(),
                   desc: #function + " clientId=\(message.messageClientId) lang=\(targetLanguage)")
    guard let text = message.text, !text.isEmpty else {
      completion(nil, NSError(domain: "TranslationError", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "message text is empty"]))
      return
    }
    let params = V2NIMTextTranslateParams()
    params.text = text
    params.targetLanguage = targetLanguage
    params.sourceLanguage = "" // 自动识别
    translateText(params: params) { result, error in
      if let err = error {
        completion(nil, err.nserror as NSError)
      } else if let translated = result?.translatedText, !translated.isEmpty {
        completion(translated, nil)
      } else {
        completion(nil, NSError(domain: "TranslationError", code: -2,
                                userInfo: [NSLocalizedDescriptionKey: "translation result is empty"]))
      }
    }
  }

  /// 将译文信息持久化到消息 localExtension（合并写入，保留已有字段）
  /// - Parameters:
  ///   - message: 消息对象
  ///   - info: 译文信息
  ///   - completion: 完成回调
  open func saveTranslationToLocalExtension(message: V2NIMMessage,
                                            info: TranslationInfo,
                                            _ completion: @escaping (V2NIMMessage?, V2NIMError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(),
                   desc: #function + " clientId=\(message.messageClientId)")
    let newExt = info.merged(into: message.localExtension)
    updateMessageLocalExtension(message: message, localExtension: newExt, completion)
  }

  /// 从消息 localExtension 中清除译文缓存（移除 translation 节点，保留其他字段）
  /// 用于消息撤回场景（Task 5.3）
  /// - Parameters:
  ///   - message: 需要清除译文的消息
  ///   - completion: 完成回调（可传 nil）
  open func clearTranslationFromLocalExtension(message: V2NIMMessage,
                                               _ completion: ((V2NIMMessage?, V2NIMError?) -> Void)?) {
    NEALog.infoLog(ModuleName + " " + className(),
                   desc: #function + " clientId=\(message.messageClientId)")
    guard let clearedExt = TranslationInfo.cleared(from: message.localExtension) else {
      // 原本无 translation 节点，无需操作
      completion?(nil, nil)
      return
    }
    updateMessageLocalExtension(message: message, localExtension: clearedExt) { msg, error in
      completion?(msg, error)
    }
  }

  // MARK: - V2NIMNotificationListener

  /// 收到自定义系统通知回调
  /// - Parameter messages: 系统通知列表
  open func onReceive(_ customNotifications: [V2NIMCustomNotification]) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " customNotifications:\(customNotifications.description)")
    notiMutiDelegate |> { delegate in
      delegate.onReceiveCustomNotifications?(customNotifications)
    }
  }

  /// 收到全员广播通知回调
  /// - Parameter boradcastNotifications: 全员广播通知列表
  open func onReceive(_ boradcastNotifications: [V2NIMBroadcastNotification]) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " boradcastNotifications:\(boradcastNotifications.description)")
    notiMutiDelegate |> { delegate in
      delegate.onReceiveBroadcastNotifications?(boradcastNotifications)
    }
  }

  // MARK: - V2NIMMessageListener

  /// 本端发送消息状态回调
  /// 来源： 发送消息， 插入消息
  /// - Parameter message: 消息
  open func onSend(_ message: V2NIMMessage) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " message:\(message.description)")
    chatMutiDelegate |> { delegate in
      delegate.onSendMessage?(message)
    }
  }

  /// 收到消息回调
  /// - Parameter messages: 消息列表
  open func onReceive(_ messages: [V2NIMMessage]) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " messages:\(messages.description)")
    chatMutiDelegate |> { delegate in
      delegate.onReceiveMessages?(messages)
    }
  }

  /// 收到点对点已读回执
  /// - Parameter readReceipts: 已读回执
  open func onReceive(_ readReceipts: [V2NIMP2PMessageReadReceipt]) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " readReceipts:\(readReceipts.description)")
    chatMutiDelegate |> { delegate in
      delegate.onReceiveP2PMessageReadReceipts?(readReceipts)
    }
  }

  /// 收到群已读回执
  /// - Parameter readReceipts: 已读回执
  open func onReceive(_ readReceipts: [V2NIMTeamMessageReadReceipt]) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " readReceipts:\(readReceipts.description)")
    chatMutiDelegate |> { delegate in
      delegate.onReceiveTeamMessageReadReceipts?(readReceipts)
    }
  }

  /// 保存撤回消息
  /// - Parameter messageRevoke: 撤回通知
  func insertRevokeTipMessage(_ revokeNotifications: [V2NIMMessageRevokeNotification]) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + "onMessageRevokeNotifications ids: \(revokeNotifications.map { $0.messageRefer?.messageServerId })")

    for messageRevoke in revokeNotifications {
      guard let msgServerId = messageRevoke.messageRefer?.messageServerId else {
        return
      }

      // 防止重复插入本地撤回消息
      if DeduplicationHelper.instance.isRevokeMessageSaved(messageId: msgServerId) {
        return
      }

      let messageNew = V2NIMMessageCreator.createTextMessage(coreLoader.localizable("message_recalled"))
      messageNew.messageConfig?.unreadEnabled = false

      var muta = [String: Any]()
      if let ext = NECommonUtil.getDictionaryFromJSONString(messageRevoke.serverExtension ?? "") as? [String: Any] {
        muta = ext
      }
      muta[revokeLocalMessage] = true
      messageNew.serverExtension = NECommonUtil.getJSONStringFromDictionary(muta)

      insertMessageToLocal(message: messageNew,
                           conversationId: messageRevoke.messageRefer?.conversationId ?? "",
                           senderId: messageRevoke.revokeAccountId,
                           createTime: messageRevoke.messageRefer?.createTime) { _, error in
        if let err = error {
          NEALog.infoLog(ModuleName + " " + #function, desc: "insertRevokeMessage error \(err)")
        }
      }
    }
  }

  /// 收到消息撤回回调
  /// - Parameter revokeNotifications: 消息撤回通知数据
  open func onMessageRevokeNotifications(_ revokeNotifications: [V2NIMMessageRevokeNotification]) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " revokeNotifications:\(revokeNotifications.description)")

    if IMKitConfigCenter.shared.enableInsertLocalMsgWhenRevoke {
      insertRevokeTipMessage(revokeNotifications)
    }

    chatMutiDelegate |> { delegate in
      delegate.onMessageRevokeNotifications?(revokeNotifications)
    }
  }

  /// 消息pin状态回调通知
  /// - Parameter pinNotification: 消息pin状态变化通知数据
  open func onMessagePinNotification(_ pinNotification: V2NIMMessagePinNotification) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " pinNotification:\(pinNotification.description)")
    chatMutiDelegate |> { delegate in
      delegate.onMessagePinNotification?(pinNotification)
    }
  }

  /// 消息评论状态回调
  /// - Parameter notification: 快捷评论通知数据
  open func onMessageQuickCommentNotification(_ notification: V2NIMMessageQuickCommentNotification) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " notification:\(notification.description)")
    chatMutiDelegate |> { delegate in
      delegate.onMessageQuickCommentNotification?(notification)
    }
  }

  /// 消息被删除通知
  /// - Parameter messageDeletedNotification: 被删除的消息列表
  open func onMessageDeletedNotifications(_ messageDeletedNotification: [V2NIMMessageDeletedNotification]) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " messageDeletedNotification:\(messageDeletedNotification.description)")
    chatMutiDelegate |> { delegate in
      delegate.onMessageDeletedNotifications?(messageDeletedNotification)
    }
  }

  /// 消息被清空通知
  /// - Parameter clearHistoryNotification: 清空的会话列表
  open func onClearHistoryNotifications(_ clearHistoryNotification: [V2NIMClearHistoryNotification]) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " clearHistoryNotification:\(clearHistoryNotification.description)")
    chatMutiDelegate |> { delegate in
      delegate.onClearHistoryNotifications?(clearHistoryNotification)
    }
  }

  /// 更新消息在线同步通知
  /// 更新消息多端同步通知
  /// 更新消息漫游通知
  /// - Parameter messages: 被修改的消息列表
  open func onReceiveMessagesModified(_ messages: [V2NIMMessage]) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " messages:\(messages.description)")
    chatMutiDelegate |> { delegate in
      delegate.onReceiveMessagesModified?(messages)
    }
  }
}
