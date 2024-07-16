// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECommonKit
import NECommonUIKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK

@objc
public protocol ChatViewModelDelegate: NSObjectProtocol {
  /// 本端即将发送消息状态回调，此时消息还未发送，可对消息进行修改或者拦截发送
  /// 来源： 发送消息， 插入消息
  /// - Parameter message: 消息
  /// - Parameter completion: 是否继续发送消息
  @objc optional func readySendMessage(_ message: V2NIMMessage, _ completion: @escaping (Bool) -> Void)

  /// 消息发送中，此时消息已经发送
  /// - Parameters:
  ///   - message: 消息
  ///   - index: 消息下标
  func sending(_ message: V2NIMMessage, _ index: IndexPath)

  /// 消息发送完成，发送结果为成功或失败
  /// - Parameters:
  ///   - message: 消息
  ///   - index: 消息下标
  func sendSuccess(_ message: V2NIMMessage, _ index: IndexPath)

  /// 消息重发成功
  /// - Parameters:
  ///   - fromIndex: 消息原下标
  ///   - toIndexPath: 消息新下标
  func onResendSuccess(_ fromIndex: IndexPath, _ toIndexPath: IndexPath)

  /// 收到消息
  /// - Parameters:
  ///   - messages: 消息列表
  ///   - indexs: 消息下标列表
  func onRecvMessages(_ messages: [V2NIMMessage], _ indexs: [IndexPath])

  /// 消息加载更多完成
  /// - Parameter indexs: 消息下标列表
  func onLoadMoreWithMessage(_ indexs: [IndexPath])

  /// 删除消息或收到删除消息回调
  /// - Parameters:
  ///   - messages: 消息列表
  ///   - deleteIndexs: 删除消息的下标列表
  ///   - reloadIndex: 需要刷新的消息的下标列表
  func onDeleteMessage(_ messages: [V2NIMMessage], deleteIndexs: [IndexPath], reloadIndex: [IndexPath])

  /// 撤回消息或收到撤回消息回调
  /// - Parameters:
  ///   - message: 消息
  ///   - atIndexs: 消息下标列表
  func onRevokeMessage(_ message: V2NIMMessage, atIndexs: [IndexPath])

  /// 收到消息标记状态变更
  /// - Parameter message: 消息
  /// - Parameter atIndexs: 消息下标
  func onMessagePinStatusChange(_ message: V2NIMMessage?, atIndexs: [IndexPath])

  /// 单聊对方正在输入中
  func remoteUserEditing()

  /// 单聊对方停止输入
  func remoteUserEndEditing()

  /// 消息列表重新加载
  func tableViewReload()

  /// 设置消息置顶内容
  /// - Parameters:
  ///   - name: 消息发送者昵称
  ///   - content: 消息内容
  ///   - url: 图片或视频链接
  ///   - isVideo: 是否是视频
  ///   - hideClose: 是否隐藏关闭按钮
  func setTopValue(name: String?, content: String?, url: String?, isVideo: Bool, hideClose: Bool)

  /// 更新消息置顶浮窗中的昵称
  /// - Parameter name: 昵称
  func updateTopName(name: String?)

  /// 显示错误浮窗
  /// - Parameter error: 错误信息
  @objc optional func showErrorToast(error: Error?)

  /// 消息重新加载
  @objc optional func dataReload()

  /// 获取消息模型
  /// - Parameter model: 模型
  @objc optional func getMessageModel(model: MessageModel)

  /// 多选列表变更
  /// - Parameter count: 选中的消息数量
  @objc optional func selectedMessagesChanged(_ count: Int)

  /// 翻译结果回调
  @objc optional func didTranslateResult(_ content: String)
}

@objcMembers
open class ChatViewModel: NSObject {
  public var conversationId: String
  public var sessionId: String
  public var messages = [MessageModel]()
  public weak var delegate: ChatViewModelDelegate?

  // 多选选中的消息
  public var selectedMessages = [V2NIMMessage]() {
    didSet {
      delegate?.selectedMessagesChanged?(selectedMessages.count)
    }
  }

  // 上拉时间戳
  private var newMsg: V2NIMMessage?
  // 下拉时间戳
  private var oldMsg: V2NIMMessage?

  public let chatRepo = ChatRepo.shared
  public let contactRepo = ContactRepo.shared
  public var operationModel: MessageContentModel?
  public var topMessage: V2NIMMessage? // 置顶消息
  public var isReplying = false
  public let messagPageNum: Int = 100
  public let aiMessagNum: Int = 30 // 从 aiMessagNum 条消息中取文本消息作为上下文内容
  public var anchor: V2NIMMessage?

  public var isHistoryChat = false

  public var deletingMsgDic = Set<String>()

  /// AI 翻译 User
  public var translationAIUser: V2NIMAIUser?

  /// 翻译request id 记录
  public var translationlanguageRquestId = ""

  /// 数字人请求成功code
  public var aiUserRequestSuccess = 200

  override init() {
    conversationId = ""
    sessionId = ""
    super.init()
  }

  init(conversationId: String) {
    NEALog.infoLog(ModuleName + " " + ChatViewModel.className(), desc: #function + ", conversationId:\(conversationId)")
    self.conversationId = conversationId
    sessionId = V2NIMConversationIdUtil.conversationTargetId(conversationId) ?? ""
    anchor = nil
    super.init()
    addListener()
  }

  init(conversationId: String, anchor: V2NIMMessage?) {
    NEALog.infoLog(ModuleName + " " + ChatViewModel.className(), desc: #function + ", conversationId:\(conversationId)")
    self.conversationId = conversationId
    self.anchor = anchor
    sessionId = V2NIMConversationIdUtil.conversationTargetId(conversationId) ?? ""
    super.init()
    if anchor != nil {
      isHistoryChat = true
    }
    addListener()
  }

  /// 添加监听
  open func addListener() {
    chatRepo.addChatListener(self)

    if IMKitConfigCenter.shared.enableAIUser {
      AIRepo.shared.addAIListener(self)
    }
  }

  deinit {
    chatRepo.removeChatListener(self)

    if IMKitConfigCenter.shared.enableAIUser {
      AIRepo.shared.removeAIListener(self)
    }
  }

  /// 根据会话id列表清空相应会话的未读数
  public func clearUnreadCount() {
    ConversationRepo.shared.clearUnreadCountByIds([conversationId]) { result, error in
      NEALog.infoLog(ModuleName, desc: #function + " error" + (error?.localizedDescription ?? ""))
    }
    ConversationRepo.shared.markConversationRead(conversationId) { result, error in
      NEALog.infoLog(ModuleName, desc: #function + " makr covnersaion read error : \(error?.localizedDescription ?? "")")
    }
  }

  /// 加载数据
  /// - Parameter completion: 完成回调
  open func loadData(_ completion: @escaping (Error?, NSInteger, NSInteger, Int) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)

    messages.removeAll()

    // 记录可信时间戳
    if anchor == nil {
      isHistoryChat = false

      getHistoryMessage(order: .QUERY_DIRECTION_DESC, message: nil) { [weak self] error, count, models in
        NEALog.infoLog(
          ModuleName + " " + ChatViewModel.className(),
          desc: "CALLBACK getMessageList " + (error?.localizedDescription ?? "no error")
        )
        completion(error, count, 0, 0)
        self?.loadMoreWithMessage(models)
      }
    } else {
      isHistoryChat = true

      // 有锚点消息，从两个方向拉去消息
      newMsg = anchor
      oldMsg = anchor

      let group = DispatchGroup()

      var moreEnd = 0
      var newEnd = 0
      var historyDatas = [V2NIMMessage]()
      var newDatas = [V2NIMMessage]()
      var loadMessages = [V2NIMMessage]()

      var err: Error?
      group.enter()
      getHistoryMessage(order: .QUERY_DIRECTION_DESC, message: anchor) { [weak self] error, value, models in
        moreEnd = value
        if error != nil {
          err = error
        }

        historyDatas.append(contentsOf: models)
        loadMessages.append(contentsOf: historyDatas)

        group.enter()
        if let anchorMessage = self?.anchor {
          loadMessages.append(anchorMessage)
          self?.modelFromMessage(message: anchorMessage) { model in
            self?.messages.append(model)
            group.leave()
          }
        }

        group.enter()
        self?.getHistoryMessage(order: .QUERY_DIRECTION_ASC, message: self?.anchor) { error, value, models in
          NEALog.infoLog(
            ModuleName + " " + ChatViewModel.className(),
            desc: "CALLBACK pullRemoteRefresh " + (error?.localizedDescription ?? "no error")
          )
          newEnd = value
          if err != nil {
            err = error
          }

          newDatas.append(contentsOf: models)
          loadMessages.append(contentsOf: newDatas)
          group.leave()
        }
        group.leave()
      }

      group.notify(queue: .main) { [weak self] in
        completion(err, moreEnd, newEnd, historyDatas.count)
        self?.loadMoreWithMessage(loadMessages)
      }
    }
  }

  /// 查询回复
  /// - Parameters:
  ///   - model: 消息体
  ///   - completion: 完成回调
  func loadReply(_ model: MessageModel, _ completion: @escaping () -> Void) {
    if model.replyedModel != nil,
       model.replyedModel?.message?.messageServerId == nil ||
       model.replyedModel?.message?.messageServerId?.isEmpty == true {
      if let message = model.message {
        getReplyMessageWithoutThread(message: message) { replyedModel in
          if let reply = replyedModel as? MessageContentModel,
             model.replyText != ReplyMessageUtil.textForReplyModel(model: reply) {
            model.replyedModel = replyedModel
          } else {
            model.replyText = chatLocalizable("message_not_found")
          }
          completion()
        }
        return
      }
    }
    completion()
  }

  /// 加载消息的更多信息（回复、标记、发送者信息）
  /// - Parameter messageArray: 消息列表
  func loadMoreWithMessage(_ messageArray: [V2NIMMessage]) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    let group = DispatchGroup()
    let sema = DispatchSemaphore(value: 0)

    DispatchQueue.global().async { [weak self] in
      guard let conversationId = self?.conversationId else { return }

      // 群聊需要获取群昵称
      if V2NIMConversationIdUtil.conversationType(conversationId) != .CONVERSATION_TYPE_P2P {
        let userIds = self?.messages.compactMap { $0.message?.senderId }
        if let userIds = userIds {
          self?.loadShowName(userIds, self?.sessionId) { [weak self] in
            // 获取头像昵称
            for model in self?.messages ?? [] {
              if let uid = ChatMessageHelper.getSenderId(model.message),
                 let fullName = self?.getShowName(uid) {
                let userFriend = ChatMessageHelper.getUserFromCache(uid)
                model.avatar = userFriend?.user?.avatar
                model.fullName = fullName
                model.shortName = NEFriendUserCache.getShortName(userFriend?.showName() ?? "")
              }
            }
            sema.signal()
          }
          sema.wait()
        }
      }

      // 查询回复
      for model in self?.messages ?? [] {
        group.enter()
        self?.loadReply(model) {
          group.leave()
        }
      }

      // 查找标记记录
      group.enter()
      self?.chatRepo.getPinnedMessageList(conversationId: conversationId) { [weak self] pinList, error in

        if let pinList = pinList {
          let userIds = pinList.map(\.operatorId)
          group.enter()
          self?.loadShowName(userIds, self?.sessionId) {
            for pin in pinList {
              for model in self?.messages ?? [] {
                if model.message?.messageClientId == pin.messageRefer?.messageClientId {
                  model.isPined = true
                  model.pinAccount = pin.operatorId
                  model.pinShowName = self?.getShowName(pin.operatorId)
                  break
                }
              }
            }
            group.leave()
          }
        }
        group.leave()
      }

      // 获取消息已读未读
      group.enter()
      self?.getMessageReceipts(messages: messageArray) { reloadIndexs, error in
        NEALog.infoLog(
          ModuleName + " " + ChatViewModel.className(),
          desc: "CALLBACK getP2PMessageReceipt " + (error?.localizedDescription ?? "no error")
        )
        group.leave()
      }

      group.notify(queue: .main) { [weak self] in
        self?.delegate?.tableViewReload()
      }
    }

    // 下载语音附件
    downloadAudioFile(messages)

    // 加载置顶消息
    loadTopMessage()
  }

  /// 更新消息发送者的信息
  /// - Parameter accid: 发送者 accid
  func updateMessageInfo(_ accid: String?) {
    guard let accid = accid else { return }

    let showName = getShowName(accid)
    var indexPaths = [IndexPath]()
    for (i, model) in messages.enumerated() {
      // 更新消息发送者昵称和头像
      if ChatMessageHelper.getSenderId(model.message) == accid {
        let user = ChatMessageHelper.getUserFromCache(accid)
        model.fullName = showName
        model.shortName = NEFriendUserCache.getShortName(showName)
        model.avatar = user?.user?.avatar
        indexPaths.append(IndexPath(row: i, section: 0))
      }

      // 更新标记者昵称
      if model.isPined, model.pinAccount == accid {
        model.pinShowName = showName
        indexPaths.append(IndexPath(row: i, section: 0))
      }
    }

    // 更新置顶消息发送者昵称
    if accid == ChatMessageHelper.getSenderId(topMessage) {
      delegate?.updateTopName(name: showName)
    }

    delegate?.onLoadMoreWithMessage(indexPaths)
  }

  /// 插入消息
  /// - Parameter newModel: 新消息模型
  /// - Returns: 插入位置
  @discardableResult
  func insertToMessages(_ newModel: MessageModel) -> Int {
    var index = -1

    // 无消息时直接尾插
    if messages.isEmpty {
      messages.append(newModel)
      return 0
    }

    // 最新的消息直接尾插
    if newModel.message?.createTime ?? 0 >= (messages.last?.message?.createTime ?? 0) {
      messages.append(newModel)
      return messages.count - 1
    }

    for (i, model) in messages.enumerated() {
      if (newModel.message?.createTime ?? 0) < (model.message?.createTime ?? 0) {
        messages.insert(newModel, at: i)
        index = i
        break
      }
    }

    return index
  }

  /// 查询历史消息
  /// - Parameters:
  ///   - order: 查询方向
  ///   - message: 锚点消息
  ///   - completion: 完成回调
  open func getHistoryMessage(order: V2NIMQueryDirection,
                              message: V2NIMMessage?,
                              _ completion: @escaping (Error?, NSInteger, [V2NIMMessage])
                                -> Void) {
    let opt = V2NIMMessageListOption()
    opt.limit = messagPageNum
    opt.anchorMessage = message
    opt.conversationId = conversationId
    opt.direction = order

    if let msg = message {
      if order == .QUERY_DIRECTION_DESC {
        opt.endTime = msg.createTime
      } else {
        opt.beginTime = msg.createTime
      }
    }

    chatRepo.getMessageList(option: opt) { [weak self] messages, error in
      if let messageArray = messages, messageArray.count > 0 {
        let group = DispatchGroup()

        if order == .QUERY_DIRECTION_DESC {
          self?.oldMsg = messageArray.last
        } else {
          self?.newMsg = messageArray.last
        }
        for msg in messageArray {
          // 数字人回复的消息
          if ChatMessageHelper.isAISender(msg) {
            self?.setErrorText(msg)
          }

          group.enter()
          self?.modelFromMessage(message: msg) { model in
            if self?.messages.contains(where: { $0.message?.messageClientId == model.message?.messageClientId }) == false {
              self?.insertToMessages(model)
            }
            group.leave()
          }
        }

        group.notify(queue: .main) {
          // 显示时间
          self?.addTimeForHistoryMessage()

          // 回调消息列表
          completion(error, messageArray.count, messageArray)
        }

        // 标记已读
        self?.markRead(messages: messageArray) { error in
          NEALog.infoLog(
            ModuleName + " " + ChatViewModel.className(),
            desc: "CALLBACK markRead " + (error?.localizedDescription ?? "no error")
          )
        }
      } else {
        if self?.messages.isEmpty == true,
           let accid = self?.sessionId,
           NEAIUserManager.shared.isAIUser(accid) {
          if let cid = self?.conversationId,
             let welcomeText = NEAIUserManager.shared.getWelcomeText(accid) {
            self?.insertTextMessage(welcomeText, cid, accid)
          }
          completion(error, 1, [])
        } else {
          completion(error, 0, [])
        }
      }
    }
  }

  /// 下拉获取历史消息
  /// - Parameter completion: 完成回调
  open func dropDownRemoteRefresh(_ completion: @escaping (Error?, NSInteger, [V2NIMMessage])
    -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)

    // 首次会话下拉，没有锚点消息 || 锚点消息被删除，需要手动设置锚点消息
    if oldMsg == nil || !messages.contains(where: { $0.message?.messageClientId == oldMsg?.messageClientId }) {
      for msg in messages {
        if let mmsg = msg.message {
          oldMsg = mmsg
          break
        }
      }
    }

    if messages.isEmpty {
      oldMsg = nil
    }

    getHistoryMessage(order: .QUERY_DIRECTION_DESC, message: oldMsg) { [weak self] error, count, messages in
      completion(error, count, messages)
      if count > 0 {
        self?.loadMoreWithMessage(messages)
      }
    }
  }

  /// 上拉获取最新消息
  /// - Parameter completion: 完成回调
  open func pullRemoteRefresh(_ completion: @escaping (Error?, NSInteger, [V2NIMMessage])
    -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    getHistoryMessage(order: .QUERY_DIRECTION_ASC, message: newMsg) { [weak self] error, count, messages in
      completion(error, count, messages)
      self?.loadMoreWithMessage(messages)
    }
  }

  /// 下载语音消息附件
  /// - Parameter models: 消息列表
  open func downloadAudioFile(_ models: [MessageModel]) {
    DispatchQueue.global().async { [weak self] in
      for model in models {
        if model.type == .audio, let audioAttach = model.message?.attachment as? V2NIMMessageAudioAttachment {
          let path = audioAttach.path ?? ChatMessageHelper.createFilePath(model.message)
          if !FileManager.default.fileExists(atPath: path) {
            if let urlString = audioAttach.url {
              self?.downLoad(urlString, path, nil) { _, error in
                if error == nil {
                  NEALog.infoLog(ModuleName + " " + ChatViewController.className(), desc: #function + "CALLBACK downLoad")
                }
              }
            }
          }
        }
      }
    }
  }

  /// 加载置顶消息
  open func loadTopMessage() {}

  /// 发送消息
  /// - Parameters:
  ///   - message: 需要发送的消息体
  ///   - conversationId: 会话id
  ///   - completion: 回调
  open func sendMessage(message: V2NIMMessage,
                        conversationId: String? = nil,
                        params: V2NIMSendMessageParams? = nil,
                        _ completion: @escaping (V2NIMMessage?, Error?, UInt) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", text: \(String(describing: message.text))")

    chatRepo.sendMessage(message: message,
                         conversationId: conversationId ?? self.conversationId,
                         params: params) { result, error, pro in
      completion(result?.message ?? message, error, pro)
    }
  }

  /// 获取请求大模型的内容
  /// - Parameters:
  ///   - text: 请求/响应的文本内容
  ///   - type: 类型
  /// - Returns: 请求大模型的内容
  open func getAIModelCallContent(_ text: String?,
                                  _ type: V2NIMAIModelCallContentType) -> V2NIMAIModelCallContent {
    let content = V2NIMAIModelCallContent()
    content.msg = text ?? ""
    content.type = type
    return content
  }

  /// 获取上下文内容
  /// - Returns: 上下文内容
  open func getAIMessages() -> [V2NIMAIModelCallMessage]? {
    guard NEAIUserManager.shared.isAIUser(sessionId) else {
      return nil
    }

    let messageModels = messages.suffix(aiMessagNum)
    let aiMessageModels = messageModels.filter { $0.type == .text || $0.type == .richText || $0.type == .reply }

    var firstUserMessage = false // 是否找到第一条用户发的消息
    var aiMessages = [V2NIMAIModelCallMessage]()

    for (i, model) in aiMessageModels.enumerated() {
      var isUserMessage = false
      if model.message?.aiConfig == nil || model.message?.aiConfig?.aiStatus != .MESSAGE_AI_STATUS_RESPONSE {
        firstUserMessage = true
        isUserMessage = true
      }

      // 找到第一条用户发送的消息
      if !firstUserMessage {
        continue
      }

      let aiMessage = V2NIMAIModelCallMessage()
      aiMessage.type = .NIM_AI_MODEL_CONTENT_TYPE_TEXT

      if isUserMessage {
        aiMessage.role = .NIM_AI_MODEL_ROLE_TYPE_USER
      } else {
        aiMessage.role = .NIM_AI_MODEL_ROLE_TYPE_ASSISTANT
      }

      if model.type == .text || model.type == .reply {
        let text = model.message?.text ?? ""
        aiMessage.msg = text
        NEALog.infoLog(ModuleName + " " + className(), desc: #function + "[AIChat], message text\(i + 1): \(text)")
      } else if model.type == .richText, let m = model as? MessageRichTextModel {
        let text = (m.titleText ?? "") + (m.message?.text ?? "")
        aiMessage.msg = text
        NEALog.infoLog(ModuleName + " " + className(), desc: #function + "[AIChat], message text\(i + 1): \(text)")
      }

      aiMessages.append(aiMessage)
    }

    return aiMessages.isEmpty ? nil : aiMessages
  }

  /// 获取消息发送参数
  /// - Parameters:
  ///   - aiUserAccid: 数字人 id
  ///   - message: 消息
  /// - Returns: 消息发送参数
  func getSendMessageParams(_ aiUserAccid: String? = nil, _ message: V2NIMMessage) -> V2NIMSendMessageParams {
    var aiUserAccid = aiUserAccid
    var needMessgaes = false // 是否需要上下文
    if NEAIUserManager.shared.isAIUser(sessionId) {
      aiUserAccid = sessionId
      needMessgaes = true // 与 AI 单聊才需要回溯上下文，@ 数字人无上下文
    }

    let params = chatRepo.getSendMessageParams()
    if let aiAccid = aiUserAccid {
      let aiConfig = V2NIMMessageAIConfigParams()
      aiConfig.accountId = aiAccid

      // 文本消息
      if message.messageType == .MESSAGE_TYPE_TEXT, let text = message.text {
        aiConfig.content = getAIModelCallContent(text, .NIM_AI_MODEL_CONTENT_TYPE_TEXT)
        if needMessgaes {
          aiConfig.messages = getAIMessages()
        }
      }

      // 换行消息
      if message.messageType == .MESSAGE_TYPE_CUSTOM,
         let type = NECustomUtils.typeOfCustomMessage(message.attachment),
         type == customRichTextType {
        let title = NECustomUtils.titleOfRichText(message.attachment)
        let body = NECustomUtils.bodyOfRichText(message.attachment)
        let text = (title ?? "") + (body ?? "")
        aiConfig.content = getAIModelCallContent(text, .NIM_AI_MODEL_CONTENT_TYPE_TEXT)
        if needMessgaes {
          aiConfig.messages = getAIMessages()
        }
      }

      params.aiConfig = aiConfig
    }

    return params
  }

  /// 获取回复消息发送参数
  /// 回复消息上下文只取被回复的消息
  /// - Parameters:
  ///   - aiUserAccid: 数字人 id
  ///   - replyMessage: 被回复的消息
  ///   - message: 回复的消息
  /// - Returns: 消息发送参数
  func getReplyMessageParams(_ aiUserAccid: String? = nil,
                             _ replyMessage: V2NIMMessage,
                             _ message: V2NIMMessage) -> V2NIMSendMessageParams {
    let params = chatRepo.getSendMessageParams()
    if let aiAccid = aiUserAccid {
      let aiConfig = V2NIMMessageAIConfigParams()
      aiConfig.accountId = aiAccid

      // 文本消息
      if replyMessage.messageType == .MESSAGE_TYPE_TEXT {
        let aiMessage = V2NIMAIModelCallMessage()
        aiMessage.msg = replyMessage.text ?? ""
        aiMessage.type = .NIM_AI_MODEL_CONTENT_TYPE_TEXT
        aiMessage.role = .NIM_AI_MODEL_ROLE_TYPE_USER

        aiConfig.messages = [aiMessage]
        NEALog.infoLog(ModuleName + " " + className(), desc: #function + "[AIChat], reply message text: \(replyMessage.text ?? "")")
      }

      // 换行消息
      if replyMessage.messageType == .MESSAGE_TYPE_CUSTOM,
         let type = NECustomUtils.typeOfCustomMessage(replyMessage.attachment),
         type == customRichTextType {
        let title = NECustomUtils.titleOfRichText(replyMessage.attachment)
        let body = NECustomUtils.bodyOfRichText(replyMessage.attachment)
        let text = (title ?? "") + (body ?? "")

        let aiMessage = V2NIMAIModelCallMessage()
        aiMessage.msg = text
        aiMessage.type = .NIM_AI_MODEL_CONTENT_TYPE_TEXT
        aiMessage.role = .NIM_AI_MODEL_ROLE_TYPE_USER

        aiConfig.messages = [aiMessage]
        NEALog.infoLog(ModuleName + " " + className(), desc: #function + "[AIChat], reply message text: \(replyMessage.text ?? "")")
      }

      aiConfig.content = getAIModelCallContent(message.text, .NIM_AI_MODEL_CONTENT_TYPE_TEXT)
      params.aiConfig = aiConfig
    }

    return params
  }

  /// 获取转发消息发送参数
  /// 转发消息给数字人没有上下文
  /// - Parameters:
  ///   - aiUserAccid: 数字人 id
  ///   - forwordMessage: 转发的消息
  /// - Returns: 消息发送参数
  func getForwardMessageParams(_ aiUserAccid: String? = nil,
                               _ forwordMessage: V2NIMMessage) -> V2NIMSendMessageParams {
    let params = chatRepo.getSendMessageParams()
    if let aiAccid = aiUserAccid {
      let aiConfig = V2NIMMessageAIConfigParams()
      aiConfig.accountId = aiAccid

      // 文本消息
      if forwordMessage.messageType == .MESSAGE_TYPE_TEXT {
        aiConfig.content = getAIModelCallContent(forwordMessage.text, .NIM_AI_MODEL_CONTENT_TYPE_TEXT)
      }

      // 换行消息
      if forwordMessage.messageType == .MESSAGE_TYPE_CUSTOM,
         let type = NECustomUtils.typeOfCustomMessage(forwordMessage.attachment),
         type == customRichTextType {
        let title = NECustomUtils.titleOfRichText(forwordMessage.attachment)
        let body = NECustomUtils.bodyOfRichText(forwordMessage.attachment)
        let text = (title ?? "") + (body ?? "")
        aiConfig.content = getAIModelCallContent(text, .NIM_AI_MODEL_CONTENT_TYPE_TEXT)
      }

      params.aiConfig = aiConfig
    }

    return params
  }

  /// 发送文本消息
  /// - Parameters:
  ///   - text: 文本内容
  ///   - conversationId: 会话 id
  ///   - remoteExt: 扩展字段
  ///   - aiUserAccid: 数字人 accountId
  ///   - completion: 完成回调
  open func sendTextMessage(text: String,
                            conversationId: String? = nil,
                            remoteExt: [String: Any]? = nil,
                            aiUserAccid: String? = nil,
                            _ completion: @escaping (V2NIMMessage?, Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", text.count: \(text.count)")
    if text.count <= 0 {
      completion(nil, nil)
      return
    }

    let message = MessageUtils.textMessage(text: text, remoteExt: remoteExt)

    var aiUserAccid = aiUserAccid
    if NEAIUserManager.shared.isAIUser(sessionId) {
      aiUserAccid = sessionId
    }
    let params = getSendMessageParams(aiUserAccid, message)
    sendMessage(message: message, conversationId: conversationId, params: params) { message, error, pro in
      completion(message, error)
    }
  }

  /// 发送换行消息
  /// - Parameters:
  ///   - message: 换行消息
  ///   - title: 标题
  ///   - body: 内容
  ///   - aiUserAccid: 数字人 accountId
  ///   - completion: 完成回调
  open func sendRichTextMessage(message: V2NIMMessage,
                                title: String? = nil,
                                body: String? = nil,
                                aiUserAccid: String? = nil,
                                _ completion: @escaping (V2NIMMessage?, Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", title: \(String(describing: title)), body: \(String(describing: body))")

    let params = getSendMessageParams(aiUserAccid, message)
    sendMessage(message: message, conversationId: conversationId, params: params) { message, error, pro in
      completion(message, error)
    }
  }

  /// 发送语音消息
  /// - Parameters:
  ///   - filePath: 语音文件路径
  ///   - conversationId: 会话 id
  ///   - completion: 完成回调
  open func sendAudioMessage(filePath: String,
                             conversationId: String? = nil,
                             _ completion: @escaping (Error?) -> Void) {
    if ChatDeduplicationHelper.instance.isRecordAudioSended(path: filePath) == true {
      NEALog.infoLog(ModuleName + " " + className(), desc: #function + ",duplicate send audio at filePath:" + filePath)
      return
    }

    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", filePath:" + filePath)

    let message = MessageUtils.audioMessage(filePath: filePath, name: nil, sceneName: nil, duration: 0)
    let params = getSendMessageParams(nil, message)
    sendMessage(message: message, conversationId: conversationId, params: params) { _, error, pro in
      completion(error)
    }
  }

  /// 发送图片消息
  /// - Parameters:
  ///   - path: 图片文件路径
  ///   - conversationId: 会话 id
  ///   - completion: 完成回调
  open func sendImageMessage(path: String,
                             name: String? = "image",
                             width: Int32 = 0,
                             height: Int32 = 0,
                             conversationId: String? = nil,
                             _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", image path: \(path)")

    let message = MessageUtils.imageMessage(path: path, name: name, sceneName: nil, width: width, height: height)
    let params = getSendMessageParams(nil, message)
    sendMessage(message: message, conversationId: conversationId, params: params) { _, error, pro in
      completion(error)
    }
  }

  /// 发送视频消息
  /// - Parameters:
  ///   - url: 视频文件路径
  ///   - conversationId: 会话 id
  ///   - completion: 完成回调
  open func sendVideoMessage(url: URL,
                             name: String? = "video",
                             width: Int32 = 0,
                             height: Int32 = 0,
                             duration: Int32 = 0,
                             conversationId: String? = nil,
                             _ completion: @escaping (V2NIMMessage?, Error?, UInt) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ",video url.path:" + url.path)

    convertVideoToMP4(videoURL: url) { [weak self] url, error in
      if let path = url?.path {
        let message = MessageUtils.videoMessage(filePath: path, name: name, sceneName: nil, width: width, height: height, duration: duration)
        let params = self?.getSendMessageParams(nil, message)
        self?.sendMessage(message: message, conversationId: conversationId, params: params) { message, error, pro in
          completion(message, error, pro)
        }
      } else {
        NEALog.errorLog("chat veiw model", desc: "convert mov to mp4 failed")
        completion(nil, NSError(domain: "convert mov to mp4 failed", code: 414), 0)
      }
    }
  }

  /// 将视频格式转为 MP4
  /// - Parameters:
  ///   - videoURL: 视频文件路径
  ///   - completion: 完成回调
  func convertVideoToMP4(videoURL: URL, completion: @escaping (URL?, Error?) -> Void) {
    let outputFileName = NIMKitFileLocationHelper.genFilename(withExt: "mp4")
    guard let outputPath = NIMKitFileLocationHelper.filepath(forVideo: outputFileName) else {
      return
    }
    let asset = AVURLAsset(url: videoURL, options: nil)
    let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
    let outputUrl = URL(fileURLWithPath: outputPath)
    session?.outputURL = outputUrl
    session?.outputFileType = AVFileType.mp4
    session?.shouldOptimizeForNetworkUse = true
    session?.exportAsynchronously {
      DispatchQueue.main.async {
        if session?.status == AVAssetExportSession.Status.completed {
          completion(outputUrl, nil)
        } else {
          completion(nil, nil)
        }
      }
    }
  }

  /// 发送地理位置消息
  /// - Parameters:
  ///   - model: 位置信息
  ///   - conversationId: 会话 id
  ///   - completion: 完成回调
  open func sendLocationMessage(model: ChatLocaitonModel,
                                conversationId: String? = nil,
                                _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", title:\(model.title), address:\(model.address)")

    let message = MessageUtils.locationMessage(lat: model.lat,
                                               lng: model.lng,
                                               address: model.title + model.address)
    message.text = model.title
    let params = getSendMessageParams(nil, message)
    sendMessage(message: message, conversationId: conversationId, params: params) { _, error, pro in
      completion(error)
    }
  }

  /// 发送文件消息
  /// - Parameters:
  ///   - filePath: 源文件路径
  ///   - displayName: 文件展示名称
  ///   - conversationId: 会话 id
  ///   - completion: 完成回调
  open func sendFileMessage(filePath: String,
                            displayName: String?,
                            conversationId: String? = nil,
                            _ completion: @escaping (V2NIMMessage?, Error?, UInt) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", filePath:\(filePath)")

    let message = MessageUtils.fileMessage(filePath: filePath, displayName: displayName, sceneName: nil)
    let params = getSendMessageParams(nil, message)
    sendMessage(message: message, conversationId: conversationId, params: params) { message, error, pro in
      completion(message, error, pro)
    }
  }

  /// 发送自定义消息
  /// - Parameters:
  ///   - text: 文本内容
  ///   - rawAttachment: 附件内容
  ///   - conversationId: 会话 id
  ///   - completion: 完成回调
  open func sendCustomMessage(text: String,
                              rawAttachment: String,
                              conversationId: String? = nil,
                              _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", text:\(text)")

    let message = MessageUtils.customMessage(text: text, rawAttachment: rawAttachment)
    let params = getSendMessageParams(nil, message)
    sendMessage(message: message, conversationId: conversationId, params: params) { _, error, pro in
      completion(error)
    }
  }

  /// 本地插入文本消息
  /// - Parameter text: 消息文本
  /// - Parameter conversationId: 会话 id
  /// - Parameter senderId: 发送者 id
  open func insertTextMessage(_ text: String,
                              _ conversationId: String,
                              _ senderId: String? = nil) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", text:\(text)")

    let message = MessageUtils.textMessage(text: text)
    chatRepo.insertMessageToLocal(message: message, conversationId: conversationId, senderId: senderId) { [weak self] _, error in
      if let currentSid = self?.conversationId, currentSid == conversationId {
        self?.modelFromMessage(message: message) { model in
          if let index = self?.insertToMessages(model) {
            self?.delegate?.sending(message, IndexPath(row: index, section: 0))
          }
        }
      }
    }
    ConversationRepo.shared.createConversation(conversationId) { [weak self] conversation, error in
      NEALog.infoLog(self?.className() ?? "", desc: #function + "insertTextMessage \(error?.localizedDescription ?? "")")
    }
  }

  /// 本地插入提示消息
  /// - Parameter text: 提示文本
  /// - Parameter conversationId: 会话 id
  /// - Parameter senderId: 发送者 id
  open func insertTipMessage(_ text: String,
                             _ conversationId: String? = nil,
                             _ senderId: String? = nil) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", text:\(text)")

    let cid = conversationId ?? self.conversationId
    let tip = MessageUtils.tipMessage(text: text)
    chatRepo.insertMessageToLocal(message: tip,
                                  conversationId: cid,
                                  senderId: senderId) { [weak self] _, error in
      // 当前聊天页面插入的提示消息
      if cid == self?.conversationId {
        self?.modelFromMessage(message: tip) { model in
          if let index = self?.insertToMessages(model) {
            self?.delegate?.sending(tip, IndexPath(row: index, section: 0))
          }
        }
      }
    }
  }

  /// 发送消息已读回执
  /// - Parameters:
  ///   - messages: 需要发送已读回执的消息
  ///   - completion: 完成回调
  open func markRead(messages: [V2NIMMessage], _ completion: @escaping (Error?) -> Void) {}

  /// 获取消息已读未读回执
  /// - Parameters:
  ///   - messages: 消息列表
  ///   - completion: 完成回调
  open func getMessageReceipts(messages: [V2NIMMessage],
                               _ completion: @escaping ([IndexPath], Error?) -> Void) {}

  /// 删除消息
  /// - Parameter completion: 完成回调
  open func deleteMessage(_ completion: @escaping (Error?) -> Void) {
    guard let message = operationModel?.message,
          let messageId = message.messageClientId else {
      NEALog.errorLog(ModuleName + " " + className(), desc: #function + ", message is nil")
      return
    }
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageClientId:\(messageId)")

    // 已撤回的消息不能删除
    if operationModel?.isRevoked == true {
      return
    }

    if deletingMsgDic.contains(messageId) {
      return
    }
    deletingMsgDic.insert(messageId)

    // 本地消息
    if !(message.messageServerId?.isEmpty == false) {
      chatRepo.deleteMessage(message: message, onlyDeleteLocal: true) { [weak self] error in
        if error == nil {
          self?.deleteMessageUpdateUI([message])
          self?.deletingMsgDic.remove(messageId)
        }
        completion(error)
      }
      return
    }

    if message.messageServerId == "0" {
      chatRepo.deleteMessage(message: message, onlyDeleteLocal: true) { [weak self] error in
        if error == nil {
          self?.deleteMessageUpdateUI([message])
          self?.deletingMsgDic.remove(messageId)
        }
        completion(error)
      }
      return
    }

    chatRepo.deleteMessage(message: message, onlyDeleteLocal: false) { [weak self] error in
      if error == nil {
        self?.deleteMessageUpdateUI([message])
        self?.deletingMsgDic.remove(messageId)
      }
      completion(error)
    }
  }

  /// 批量删除消息
  /// - Parameters:
  ///   - messages: 需要删除的消息
  ///   - completion: 完成回调
  open func deleteMessages(messages: [V2NIMMessage], _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", message count:\(messages.count)")
    var localMsgs = [V2NIMMessage]()
    var remoteMsgs = [V2NIMMessage]()
    for msg in messages {
      guard let messageId = msg.messageClientId else {
        continue
      }

      if deletingMsgDic.contains(messageId) {
        continue
      }

      deletingMsgDic.insert(messageId)
      if !(msg.messageServerId?.isEmpty == false) {
        localMsgs.append(msg)
      } else {
        remoteMsgs.append(msg)
      }
    }

    chatRepo.deleteMessages(messages: localMsgs, onlyDeleteLocal: true) { [weak self] error in
      if error == nil {
        self?.deleteMessageUpdateUI(localMsgs)
        for msg in localMsgs {
          if let msgId = msg.messageClientId {
            self?.deletingMsgDic.remove(msgId)
          }
        }
      }
      completion(error)
    }

    chatRepo.deleteMessages(messages: remoteMsgs, onlyDeleteLocal: false) { [weak self] error in
      if error == nil {
        self?.deleteMessageUpdateUI(remoteMsgs)
        for msg in remoteMsgs {
          if let msgId = msg.messageClientId {
            self?.deletingMsgDic.remove(msgId)
          }
        }
      }
      completion(error)
    }
  }

  /// 回复消息（不使用 thread ）
  /// - Parameters:
  ///   - message: 新生成的消息
  ///   - replyMessage: 被回复的消息
  open func replyMessageWithoutThread(message: V2NIMMessage,
                                      replyMessage: V2NIMMessage,
                                      aiUserAccid: String? = nil,
                                      _ completion: @escaping (V2NIMMessage?, Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageClientId:\(String(describing: message.messageClientId))")

    let yxReplyMsg: [String: Any] = [
      "idClient": replyMessage.messageClientId as Any,
      "scene": replyMessage.conversationType.rawValue,
      "from": replyMessage.senderId as Any,
      "receiverId": replyMessage.receiverId as Any,
      "to": replyMessage.conversationId as Any,
      "idServer": replyMessage.messageServerId as Any,
      "time": Int(replyMessage.createTime * 1000),
    ]

    var remoteExt = NECommonUtil.getDictionaryFromJSONString(message.serverExtension ?? "") as? [String: Any]
    if remoteExt == nil {
      remoteExt = [keyReplyMsgKey: yxReplyMsg]
    } else {
      remoteExt![keyReplyMsgKey] = yxReplyMsg
    }
    message.serverExtension = NECommonUtil.getJSONStringFromDictionary(remoteExt ?? [:])

    let params = getReplyMessageParams(aiUserAccid, replyMessage, message)
    sendMessage(message: message, conversationId: conversationId, params: params) { message, error, pro in
      completion(message, error)
    }
  }

  /// 撤回消息
  /// - Parameters:
  ///   - message: 消息
  ///   - completion: 完成回调
  open func revokeMessage(message: V2NIMMessage, _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageClientId:\(String(describing: message.messageClientId))")

    var muta = [String: Any]()
    muta[revokeLocalMessage] = true
    if message.messageType == .MESSAGE_TYPE_TEXT {
      muta[revokeLocalMessageContent] = message.text
    }

    if message.messageType == .MESSAGE_TYPE_CUSTOM {
      if let title = NECustomUtils.titleOfRichText(message.attachment), !title.isEmpty {
        muta[revokeLocalMessageContent] = title
      }
      if let body = NECustomUtils.bodyOfRichText(message.attachment), !body.isEmpty {
        muta[revokeLocalMessageContent] = body
      }
    }

    let revokeParams = V2NIMMessageRevokeParams()
    revokeParams.serverExtension = getJSONStringFromDictionary(muta)
    chatRepo.revokeMessage(message: message, params: revokeParams) { [weak self] error in
      if error == nil {
        self?.revokeMessageUpdateUI(message)
      }
      completion(error)
    }
  }

  /// 获取用户展示名称
  /// - Parameters:
  ///   - accountId: 用户 accountId
  ///   - showAlias: 是否展示备注
  /// - Returns: 名称和好友信息
  open func getShowName(_ accountId: String,
                        _ showAlias: Bool = true) -> String {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", accountId:" + accountId)
    return NEAIUserManager.shared.getShowName(accountId) ?? NEFriendUserCache.shared.getShowName(accountId, showAlias)
  }

  /// 获取用户展示名称
  /// - Parameters:
  ///   - accountId: 用户 accountId
  ///   - showAlias: 是否展示备注
  ///   - completion: 完成回调
  open func loadShowName(_ accountIds: [String],
                         _ teamId: String? = nil,
                         _ completion: @escaping () -> Void) {}

  /// 获取消息所支持的操作列表
  /// - Parameter model: 消息模型
  /// - Returns: 操作列表
  open func avalibleOperationsForMessage(_ model: MessageContentModel?) -> [OperationItem]? {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", pinAccount: " + (model?.pinAccount ?? "nil"))
    var items = [OperationItem]()

    /// 消息发送中的消息只能删除（文本可复制）
    if model?.message?.sendingState == .MESSAGE_SENDING_STATE_SENDING {
      switch model?.message?.messageType {
      case .MESSAGE_TYPE_TEXT:
        items.append(contentsOf: [
          OperationItem.copyItem(),
          OperationItem.deleteItem(),
        ])
        return items
      default:
        return [
          OperationItem.deleteItem(),
        ]
      }
    }

    /// 发送失败 || 黑名单中的消息 || 话单消息 只能多选和删除（文本可复制）
    if model?.message?.sendingState == .MESSAGE_SENDING_STATE_FAILED ||
      model?.message?.messageType == .MESSAGE_TYPE_CALL {
      switch model?.message?.messageType {
      case .MESSAGE_TYPE_TEXT:
        items.append(contentsOf: [
          OperationItem.copyItem(),
          OperationItem.deleteItem(),
          OperationItem.selectItem(),
        ])
        return items
      default:
        return [
          OperationItem.deleteItem(),
          OperationItem.selectItem(),
        ]
      }
    }

    /// 消息发送成功
    let pinItem = model?.isPined == false ? OperationItem.pinItem() : OperationItem.removePinItem()
    let topItem = model?.message?.messageClientId == topMessage?.messageClientId ? OperationItem.untopItem() : OperationItem.topItem()

    switch model?.message?.messageType {
    case .MESSAGE_TYPE_LOCATION:
      items.append(contentsOf: [
        OperationItem.replayItem(),
        OperationItem.forwardItem(),
        pinItem,
        OperationItem.deleteItem(),
        OperationItem.selectItem(),
        OperationItem.collectionItem(),
        topItem,
      ])
    case .MESSAGE_TYPE_TEXT:
      items = [
        OperationItem.copyItem(),
        OperationItem.replayItem(),
        OperationItem.forwardItem(),
        pinItem,
        OperationItem.deleteItem(),
        OperationItem.selectItem(),
        OperationItem.collectionItem(),
        topItem,
      ]
    case .MESSAGE_TYPE_IMAGE, .MESSAGE_TYPE_VIDEO, .MESSAGE_TYPE_FILE:
      items = [
        OperationItem.replayItem(),
        OperationItem.forwardItem(),
        pinItem,
        OperationItem.deleteItem(),
        OperationItem.selectItem(),
        OperationItem.collectionItem(),
        topItem,
      ]
    case .MESSAGE_TYPE_AUDIO:
      items = [
        OperationItem.replayItem(),
        pinItem,
        OperationItem.deleteItem(),
        OperationItem.selectItem(),
        OperationItem.collectionItem(),
        topItem,
      ]
    case .MESSAGE_TYPE_CUSTOM:
      if (model?.customType ?? 0) > 0 {
        // 换行消息可以【复制】
        if model?.customType == customRichTextType {
          items = [
            OperationItem.copyItem(),
          ]
        }

        items.append(contentsOf: [
          OperationItem.replayItem(),
          OperationItem.forwardItem(),
          pinItem,
          OperationItem.deleteItem(),
          OperationItem.selectItem(),
          OperationItem.collectionItem(),
          topItem,
        ])
      } else {
        // 未知消息体
        items = [
          OperationItem.deleteItem(),
          OperationItem.selectItem(),
          OperationItem.collectionItem(),
        ]
      }
    default:
      items = [
        OperationItem.replayItem(),
        pinItem,
        OperationItem.deleteItem(),
        OperationItem.selectItem(),
      ]
    }

    // 自己发送且非未知消息可以 【撤回】
    if model?.message?.isSelf == true {
      if model?.message?.messageType == .MESSAGE_TYPE_CUSTOM,
         model?.unkonwMessage == true {
        return items
      }

      // 【撤回】位置在【删除】后面
      for (i, item) in items.enumerated() {
        if item.type == .delete {
          items.insert(OperationItem.recallItem(), at: i + 1)
          break
        }
      }
    }

    // 根据配置项移除 【收藏】
    if IMKitConfigCenter.shared.enableCollectionMessage == false {
      items.removeAll { item in
        item.type == .collection
      }
    }

    // 根据配置项移除 【标记】
    if IMKitConfigCenter.shared.enablePinMessage == false {
      items.removeAll { item in
        item.type == .pin || item.type == .removePin
      }
    }

    // 根据配置项移除 【置顶】
    // 单聊移除【置顶】
    if IMKitConfigCenter.shared.enableTopMessage == false || model?.message?.conversationType == .CONVERSATION_TYPE_P2P {
      items.removeAll { item in
        item.type == .top || item.type == .untop
      }
    }

    return items
  }

  /// 消息列表添加时间
  private func addTimeForHistoryMessage() {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    for (i, model) in messages.enumerated() {
      if i == 0, let createTime = model.message?.createTime {
        // 第一条消息默认显示时间
        let timeText = String.stringFromDate(date: Date(timeIntervalSince1970: createTime))
        model.timeContent = timeText
        continue
      }

      if let message = model.message, NotificationMessageUtils.isDiscussSeniorTeamNoti(message: message) {
        continue
      }

      // 当前消息时间 - 上一条消息时间 > 5s, 则显示当前消息的创建时间
      let lastModel = messages[i - 1]
      let lastTime = lastModel.message?.createTime ?? 0.0
      let curTime = model.message?.createTime ?? 0
      let dur = curTime - lastTime
      if (dur / 60) > 5 {
        let timeText = String.stringFromDate(date: Date(timeIntervalSince1970: curTime))
        model.timeContent = timeText
      }
    }
  }

  /// 构建聊天页面UI显示model
  /// - Parameters:
  ///   - message: 消息
  ///   - completion: 完成回调
  open func modelFromMessage(message: V2NIMMessage, _ completion: @escaping (MessageModel) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageClientId: \(String(describing: message.messageClientId))")
    ChatMessageHelper.modelFromMessage(message: message) { [weak self] model in
      if ChatMessageHelper.isRevokeMessage(message: model.message) {
        if let content = ChatMessageHelper.getRevokeMessageContent(message: model.message) {
          model.isReedit = true
          model.message?.text = content
        }
        model.isRevoked = true
      }

      if let uid = ChatMessageHelper.getSenderId(message),
         let fullName = self?.getShowName(uid) {
        let user = ChatMessageHelper.getUserFromCache(uid)
        model.avatar = user?.user?.avatar
        model.fullName = fullName
        model.shortName = NEFriendUserCache.getShortName(fullName)
      }

      if let replyModel = self?.getReplyMessageWithoutThread(message: message) {
        model.replyedModel = replyModel
      }
      self?.delegate?.getMessageModel?(model: model)
      completion(model)
    }
  }

  /// 构建聊天页面UI显示model
  /// - Parameter message: 消息
  /// - Returns: 消息体
  open func modelFromMessage(message: V2NIMMessage) -> MessageModel {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageClientId: \(String(describing: message.messageClientId))")
    let model = ChatMessageHelper.modelFromMessage(message: message)

    if ChatMessageHelper.isRevokeMessage(message: model.message) {
      if let content = ChatMessageHelper.getRevokeMessageContent(message: model.message) {
        model.isReedit = true
        model.message?.text = content
      }
      model.isRevoked = true
    }

    if let uid = ChatMessageHelper.getSenderId(message) {
      let fullName = getShowName(uid)
      let user = ChatMessageHelper.getUserFromCache(uid)
      model.avatar = user?.user?.avatar
      model.fullName = fullName
      model.shortName = NEFriendUserCache.getShortName(fullName)

      if user == nil {
        contactRepo.getUserWithFriend(accountIds: [uid]) { _, _ in }
      }
    }

    if let replyModel = getReplyMessageWithoutThread(message: message) {
      model.replyedModel = replyModel
      if replyModel.message == nil {
        model.replyText = chatLocalizable("message_not_found")
      }
    }
    delegate?.getMessageModel?(model: model)
    return model
  }

  /// 查找回复消息，优先不使用 thread 方案 (不进行远端拉取)
  /// - Parameters:
  ///   - message: 需要查找回复的消息
  ///   - completion: 完成回调
  open func getReplyMessageWithoutThread(message: V2NIMMessage) -> MessageModel? {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageClientId: \(String(describing: message.messageClientId))")
    var replyId: String?

    // 非thread方案
    let replyDic = ChatMessageHelper.getReplyDictionary(message: message)
    replyId = replyDic?["idClient"] as? String

    // thread 方案优先
    if let threadId = message.threadReply?.messageClientId, !threadId.isEmpty {
      replyId = threadId
    }

    guard let replyId = replyId, !replyId.isEmpty else {
      return nil
    }

    for model in messages {
      if model.message?.messageClientId == replyId, model.isRevoked == false {
        model.isReplay = true
        return model
      }
    }

    let model = MessageTextModel(message: nil)
    model.isReplay = true
    if let replySenderId = replyDic?["from"] as? String {
      model.fullName = replySenderId
    }
    return model
  }

  /// 查找回复消息，优先不使用 thread 方案，已加载的消息中没有则去远端查
  /// - Parameters:
  ///   - message: 需要查找回复的消息
  ///   - fetch: 是否远端查询
  ///   - completion: 完成回调
  open func getReplyMessageWithoutThread(message: V2NIMMessage,
                                         _ completion: @escaping (MessageModel?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageClientId: \(String(describing: message.messageClientId))")
    var replyId: String?

    // 非thread方案
    let replyDic = ChatMessageHelper.getReplyDictionary(message: message)
    replyId = replyDic?["idClient"] as? String

    // thread 方案优先
    if let threadId = message.threadReply?.messageClientId, !threadId.isEmpty {
      replyId = threadId
    }

    guard let replyId = replyId, !replyId.isEmpty else {
      completion(nil)
      return
    }

    // 先去已加载的消息中查
    for model in messages {
      if model.message?.messageClientId == replyId, !model.isRevoked {
        model.isReplay = true
        completion(model)
        return
      }
    }

    // 已加载的消息中没有则去远端查
    let refer = ChatMessageHelper.createMessageRefer(replyDic)
    chatRepo.getMessageListByRefers([refer]) { [weak self] messages, error in
      if let m = messages?.first {
        self?.modelFromMessage(message: m) { model in
          model.isReplay = true
          completion(model)
        }
      } else {
        completion(nil)
      }
    }
  }

  @discardableResult
  func deleteMessageModel(_ message: V2NIMMessage) -> (deleteIndexs: [Int], reloadIndexs: [Int]) {
    var deleteIndexs = [Int]()
    var reloadIndexs = [Int]()
    var index = -1
    var replyIndex = [Int]()
    var hasFind = false

    for (i, model) in messages.enumerated() {
      if hasFind {
        var replyId: String?

        // 非thread方案
        if let remoteExt = getDictionaryFromJSONString(model.message?.serverExtension ?? ""),
           let yxReplyMsg = remoteExt[keyReplyMsgKey] as? [String: Any] {
          replyId = yxReplyMsg["idClient"] as? String
        }

        // thread 方案优先
        if let threadId = model.message?.threadReply?.messageClientId, !threadId.isEmpty {
          replyId = threadId
        }

        if let id = replyId, !id.isEmpty, id == message.messageClientId {
          messages[i].replyText = chatLocalizable("message_not_found")
          replyIndex.append(i)
        }
      } else {
        if model.message?.messageClientId == message.messageClientId {
          index = i
          hasFind = true
        }
      }
    }

    if index >= 0 {
      deleteIndexs.append(index)
      for replyIdx in replyIndex {
        reloadIndexs.append(replyIdx)
      }
    }

    return (deleteIndexs, reloadIndexs)
  }

  /// 删除消息更新UI
  /// - Parameter message: 消息
  func deleteMessageUpdateUI(_ messages: [V2NIMMessage]) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messages count: \(messages.count)")
    var deleteIndexs = Set<Int>()
    var reloadIndexs = Set<Int>()
    for message in messages {
      let indexs = deleteMessageModel(message)

      for index in indexs.deleteIndexs {
        deleteIndexs.insert(index)
      }

      for index in indexs.reloadIndexs {
        reloadIndexs.insert(index)
      }
    }

    let deleteIndexPaths = deleteIndexs.map { IndexPath(row: $0, section: 0) }
    let reloadIndexPaths = reloadIndexs.map { IndexPath(row: $0, section: 0) }

    delegate?.onDeleteMessage(messages, deleteIndexs: deleteIndexPaths, reloadIndex: reloadIndexPaths)
  }

  /// 撤回消息更新UI
  /// - Parameter message: 消息
  func revokeMessageUpdateUI(_ message: V2NIMMessage) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageClientId: \(String(describing: message.messageClientId))")
    var index = -1
    var indexs = [IndexPath]()
    var hasFind = false

    // 遍历查找回复该条消息的消息
    for (i, model) in messages.enumerated() {
      if hasFind {
        var replyId: String?

        // 非thread方案
        if let remoteExt = getDictionaryFromJSONString(model.message?.serverExtension ?? ""),
           let yxReplyMsg = remoteExt[keyReplyMsgKey] as? [String: Any] {
          replyId = yxReplyMsg["idClient"] as? String
        }

        // thread 方案优先
        if let threadId = model.message?.threadReply?.messageClientId, !threadId.isEmpty {
          replyId = threadId
        }

        if let id = replyId, !id.isEmpty, id == message.messageClientId {
          messages[i].replyText = chatLocalizable("message_not_found")
          indexs.append(IndexPath(row: i, section: 0))
        }
      } else {
        if model.message?.messageServerId == message.messageServerId {
          index = i
          hasFind = true
        }
      }
    }

    if index >= 0 {
      messages[index].isRevoked = true
      messages[index].replyedModel = nil
      messages[index].isPined = false

      // 是否可以重新编辑
      if let content = ChatMessageHelper.getRevokeMessageContent(message: messages[index].message) {
        messages[index].isReedit = true
        messages[index].message?.text = content
      }

      indexs.append(IndexPath(row: index, section: 0))
    }

    delegate?.onRevokeMessage(message, atIndexs: indexs)
  }

  /// 下载附件
  /// - Parameters:
  ///   - urlString: 远端 url
  ///   - filePath: 本地路径
  ///   - progress: 下载进度回调
  ///   - completion: 完成回调
  open func downLoad(_ urlString: String,
                     _ filePath: String,
                     _ progress: ((UInt) -> Void)?,
                     _ completion: ((String?, NSError?) -> Void)?) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageClientId: " + urlString)
    ResourceRepo.shared.downLoad(urlString, filePath, progress, completion)
  }

  /// 转发消息
  /// - Parameters:
  ///   - conversationIds: 会话 id 列表
  ///   - isMultiForward: 是否是合并转发
  ///   - depth: 合并转发深度
  ///   - comment: 留言
  ///   - completion: 完成回调
  open func forwardMessages(_ conversationIds: [String],
                            _ isMultiForward: Bool,
                            _ depth: Int,
                            _ comment: String?,
                            _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messages.count: \(selectedMessages.count)")

    // 排序（发送时间正序）
    let forwardMessages = selectedMessages.sorted { msg1, msg2 in
      msg1.createTime < msg2.createTime
    }

    if isMultiForward {
      forwardMultiMessage(forwardMessages: forwardMessages,
                          conversationIds: conversationIds,
                          depth: depth,
                          comment: comment,
                          completion)
    } else {
      forwardMessage(selectedMessages, conversationIds, comment, completion)
    }
  }

  /// 逐条转发消息
  /// - Parameters:
  ///   - forwardMessages: 需要逐条转发的消息列表
  ///   - conversationId: 转发的会话 id
  ///   - comment: 留言
  ///   - completion: 完成回调
  open func forwardMessage(_ forwardMessages: [V2NIMMessage],
                           _ conversationIds: [String],
                           _ comment: String?,
                           _ completion: @escaping (Error?) -> Void) {
    for conversationId in conversationIds {
      for message in forwardMessages {
        let forwardMessage = MessageUtils.forwardMessage(message: message)
        ChatMessageHelper.clearForwardAtMark(forwardMessage)

        var params = chatRepo.getSendMessageParams()
        if let sessionId = V2NIMConversationIdUtil.conversationTargetId(conversationId),
           NEAIUserManager.shared.isAIUser(sessionId) {
          params = getForwardMessageParams(sessionId, forwardMessage)
        }
        chatRepo.sendMessage(message: forwardMessage, conversationId: conversationId, params: params) { result, error, pro in
        }
      }

      // 发送留言
      if let text = comment, !text.isEmpty {
        // 延迟 0.2s 发送，确保留言位置在最后
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: DispatchWorkItem(block: { [weak self] in
          let message = MessageUtils.textMessage(text: text, remoteExt: nil)

          var params = self?.chatRepo.getSendMessageParams()
          if let sessionId = V2NIMConversationIdUtil.conversationTargetId(conversationId),
             NEAIUserManager.shared.isAIUser(sessionId) {
            params = self?.getForwardMessageParams(sessionId, message)
          }
          self?.sendMessage(message: message, conversationId: conversationId, params: params) { _, error, pro in
            completion(error)
          }
        }))
      } else {
        completion(nil)
      }
    }
  }

  /// 合并转发消息
  /// - Parameters:
  ///   - forwardMessages: 需要合并的消息列表
  ///   - toconversationId: 转发的会话 id
  ///   - users: 需要转发的好友列表
  ///   - depth: 合并转发消息的深度
  ///   - comment: 留言
  ///   - completion: 完成回调
  open func forwardMultiMessage(forwardMessages: [V2NIMMessage],
                                conversationIds: [String],
                                depth: Int = 0,
                                comment: String?,
                                _ completion: @escaping (Error?) -> Void) {
    if forwardMessages.count <= 0 {
      if let text = comment, !text.isEmpty {
        for conversationId in conversationIds {
          let message = MessageUtils.textMessage(text: text, remoteExt: nil)

          var params = chatRepo.getSendMessageParams()
          if let sessionId = V2NIMConversationIdUtil.conversationTargetId(conversationId),
             NEAIUserManager.shared.isAIUser(sessionId) {
            params = getForwardMessageParams(sessionId, message)
          }

          sendMessage(message: message, conversationId: conversationId, params: params) { _, error, pro in
            completion(error)
          }
        }
      } else {
        completion(nil)
      }
      return
    }

    let fromSession = conversationId
    let header = ChatMessageHelper.buildHeader(messageCount: forwardMessages.count)
    ChatMessageHelper.buildBody(messages: forwardMessages) { body, abstracts in
      let multiForwardMsg = header + body
      let fileName = multiForwardFileName + "\(Int(Date().timeIntervalSince1970))"
      if var filePath = NEPathUtils.getDirectoryForDocuments(dir: "\(imkitDir)file/") {
        filePath += fileName

        do {
          try multiForwardMsg.write(toFile: filePath, atomically: true, encoding: .utf8)
        } catch {
          completion(NSError(domain: chatLocalizable("forward_failed"), code: 414))
          print("Error writing string to file: \(error)")
          return
        }

        let fileTask = ResourceRepo.shared.createUploadFileTask(filePath)
        ResourceRepo.shared.upload(fileTask, nil) { [weak self] url, error in
          if let err = error {
            completion(err)
          } else if let url = url, let filePath = URL(string: filePath) {
            let md5 = ChatMessageHelper.getFileChecksum(fileURL: filePath)

            // 删除本地文件
            do {
              try FileManager.default.removeItem(atPath: filePath.path)
            } catch {
              print("无法删除合并转发文件：\(error)")
            }

            var data = [String: Any]()
            data["sessionId"] = V2NIMConversationIdUtil.conversationTargetId(fromSession)
            data["url"] = url
            data["md5"] = md5
            data["depth"] = depth
            data["abstracts"] = abstracts
            data["sessionName"] = ChatMessageHelper.getSessionName(conversationId: fromSession, showAlias: false)

            var jsonData = [String: Any]()
            jsonData["data"] = data
            jsonData["messageType"] = "custom"
            jsonData["type"] = customMultiForwardType

            // 转发到会话
            for conversationId in conversationIds {
              let message = MessageUtils.customMessage(text: "[\(chatLocalizable("chat_history"))]",
                                                       rawAttachment: getJSONStringFromDictionary(jsonData))

              var params = self?.chatRepo.getSendMessageParams()
              if let sessionId = V2NIMConversationIdUtil.conversationTargetId(conversationId),
                 NEAIUserManager.shared.isAIUser(sessionId) {
                params = self?.getForwardMessageParams(sessionId, message)
              }
              self?.sendMessage(message: message, conversationId: conversationId, params: params) { _, error, pro in
                completion(error)
              }

              // 发送留言
              if let text = comment, !text.isEmpty {
                // 延迟 0.2s 发送，确保留言位置在最后
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: DispatchWorkItem(block: { [weak self] in
                  let message = MessageUtils.textMessage(text: text, remoteExt: nil)

                  var params = self?.chatRepo.getSendMessageParams()
                  if let sessionId = V2NIMConversationIdUtil.conversationTargetId(conversationId),
                     NEAIUserManager.shared.isAIUser(sessionId) {
                    params = self?.getForwardMessageParams(sessionId, message)
                  }

                  self?.sendMessage(message: message, conversationId: conversationId, params: params) { _, error, pro in
                    completion(error)
                  }
                }))
              } else {
                completion(nil)
              }
            }
          }
        }
      }
    }
  }

  /// 标记消息
  /// - Parameters:
  ///   - message: 消息
  ///   - completion: 完成回调
  open func addPinMessage(message: V2NIMMessage,
                          _ completion: @escaping (Error?, Int) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageClientId: \(String(describing: message.messageClientId))")
    chatRepo.pinMessage(message: message, serverExtension: "") { [weak self] error in
      var index = -1
      if error != nil {
        completion(error, index)
      } else {
        for (i, model) in (self?.messages ?? []).enumerated() {
          if message.messageClientId == model.message?.messageClientId, !(self?.messages[i].isPined == true) {
            self?.messages[i].isPined = true
            self?.messages[i].pinAccount = IMKitClient.instance.account()
            self?.messages[i].pinShowName = self?.getShowName(IMKitClient.instance.account())
            index = i
            break
          }
        }
        completion(nil, index)
      }
    }
  }

  /// 取消消息标记
  /// - Parameters:
  ///   - message: 消息
  ///   - completion: 完成回调
  open func removePinMessage(message: V2NIMMessage,
                             _ completion: @escaping (Error?, Int) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageClientId: \(String(describing: message.messageClientId))")
    chatRepo.unpinMessage(messageRefer: message, serverExtension: "") { [weak self] error in
      if error != nil {
        completion(error, -1)
      } else {
        let index = self?.removeLocalPinMessage(message) ?? -1
        completion(nil, index)
      }
    }
  }

  /// 置顶消息
  /// - Parameter completion: 回调
  open func topMessage(_ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageClientId: \(String(describing: operationModel?.message?.messageClientId))")
  }

  /// 取消置顶消息
  /// - Parameter completion: 回调
  open func untopMessage(_ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageClientId \(String(describing: topMessage?.messageClientId))")
  }

  /// 收藏消息
  /// - Parameter model: UI使用消息体
  /// - Parameter conversationName: 会话名
  /// - Parameter completion: 回调
  open func collectMessage(_ model: MessageContentModel, _ conversationName: String, _ completion: @escaping (NSError?) -> Void) {
    guard let message = model.message else {
      return
    }
    let collectionType = message.messageType.rawValue + collectionTypeOffset
    var collectionDic = [String: Any]()

    if let messageString = V2NIMMessageConverter.messageSerialization(message) {
      if let collectionMessage = V2NIMMessageConverter.messageDeserialization(messageString) {
        // 移除收藏消息中的at信息
        if var remoteExt = getDictionaryFromJSONString(collectionMessage.serverExtension ?? "") as? [String: Any] {
          remoteExt.removeValue(forKey: yxAtMsg)
          let serverExtensionString = getJSONStringFromDictionary(remoteExt)
          collectionMessage.serverExtension = serverExtensionString
        }
        if let saveMessageString = V2NIMMessageConverter.messageSerialization(collectionMessage) {
          collectionDic["message"] = saveMessageString
        }
      }
    }
    collectionDic["conversationName"] = conversationName

    if let accountId = ChatMessageHelper.getSenderId(model.message) {
      if let aiUser: V2NIMAIUser = NEAIUserManager.shared.getAIUserById(accountId), let senderName = aiUser.name {
        collectionDic["senderName"] = senderName
      } else if let senderName = model.fullName {
        collectionDic["senderName"] = senderName
      }
    } else if let senderName = model.fullName {
      collectionDic["senderName"] = senderName
    }

    if let avatar = model.avatar {
      collectionDic["avatar"] = avatar
    }

    let content = getJSONStringFromDictionary(collectionDic)

    let params = V2NIMAddCollectionParams()
    params.collectionType = Int32(collectionType)
    params.collectionData = content
    params.uniqueId = message.messageServerId

    chatRepo.addCollection(params) { collection, error in
      if let err = error {
        completion(err)
      } else {
        completion(nil)
      }
    }
  }

  /// 获取听筒模式
  /// - Returns: 听筒模式
  open func getHandSetEnable() -> Bool {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    return SettingRepo.shared.getHandsetMode()
  }

  @discardableResult
  /// 移除缓存数据的标记状态
  /// - Parameter message: 消息
  /// - Returns: 消息下标
  private func removeLocalPinMessage(_ message: V2NIMMessage) -> Int {
    var index = -1

    for (i, model) in messages.enumerated() {
      if message.messageClientId == model.message?.messageClientId, messages[i].isPined {
        messages[i].isPined = false
        messages[i].pinAccount = nil
        index = i
        break
      }
    }
    return index
  }

  /// 消息即将发送
  /// - Parameter message: 消息
  open func sendingMsg(_ message: V2NIMMessage) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageClientId:\(String(describing: message.messageClientId))")
    print("\(#function)")

    // 消息不是当前会话的消息，不处理（转发）
    if message.conversationId != conversationId {
      return
    }

    // 消息已存在则更新消息状态
    for (i, model) in messages.enumerated() {
      if message.messageClientId == model.message?.messageClientId {
        messages[i].message = message
        delegate?.sendSuccess(message, IndexPath(row: i, section: 0))
        return
      }
    }

    // 避免重复发送
    if ChatDeduplicationHelper.instance.isMessageSended(messageId: message.messageClientId ?? "") {
      return
    }

    // 自定义消息发送之前的处理
    if newMsg == nil {
      newMsg = message
    }

    // 插入一条消息
    let model = modelFromMessage(message: message)
    ChatMessageHelper.addTimeMessage(model, messages.last)
    let index = insertToMessages(model)

    delegate?.sending(message, IndexPath(row: index, section: 0))
  }

  /// 消息发送完成
  /// - Parameters:
  ///   - message: 消息
  ///   - error: 错误信息
  @nonobjc open func sendMsgSuccess(_ message: V2NIMMessage) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageClientId: \(String(describing: message.messageClientId))")

    if message.conversationId != conversationId {
      return
    }

    var failedIndex = -1
    var index = -1
    for (i, msg) in messages.enumerated() {
      if message.messageClientId == msg.message?.messageClientId {
        if messages[i].message?.sendingState != .MESSAGE_SENDING_STATE_SUCCEEDED {
          failedIndex = i
        }
        index = i
        messages[i].message = message
        break
      }
    }

    var indexPath = IndexPath(row: index, section: 0)
    if failedIndex >= 0 {
      indexPath = IndexPath(row: failedIndex, section: 0)

      // 重发消息位置替换
      if failedIndex != messages.count - 1 {
        for (i, model) in messages.enumerated() {
          if message.createTime < (model.message?.createTime ?? 0) {
            if i - 1 != failedIndex {
              exchangeMessageModel(failedIndex, i)
              return
            } else {
              break
            }
          } else if i == messages.count - 1 {
            if i != failedIndex {
              exchangeMessageModel(failedIndex, i)
              return
            }
          }
        }
      }
    }

    if indexPath.row >= 0 {
      delegate?.sendSuccess(message, indexPath)
    }
  }

  /// 消息发送失败
  /// - Parameters:
  ///   - message: 消息
  ///   - error: 错误信息
  open func sendMsgFailed(_ message: V2NIMMessage, _ error: Error?) {
    guard let messageClientId = message.messageClientId else {
      NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", error: \(String(describing: error))")
      return
    }
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + "messageClientId:\(messageClientId), error: \(String(describing: error))")

    // 判断发送失败原因是否是因为在黑名单中
    if error != nil {
      if let err = error as NSError? {
        if err.code == inBlackListCode, let conversationId = message.conversationId {
          // 防重
          if ChatDeduplicationHelper.instance.isBlackTipSended(messageId: messageClientId) {
            return
          }

          DispatchQueue.main.async { [weak self] in
            self?.insertTipMessage(chatLocalizable("black_list_tip"), conversationId)
            if conversationId == self?.conversationId {
              self?.sendMsgSuccess(message)
            }
          }
        }
      }
    } else {
      sendMsgSuccess(message)
    }
  }

  /// 交换消息位置
  /// - Parameters:
  ///   - fromIndex: 原始位置
  ///   - toIndex: 新位置
  func exchangeMessageModel(_ fromIndex: Int, _ toIndex: Int) {
    let resendModel = messages[fromIndex]
    // 更新旧位置下一条消息的时间
    if fromIndex + 1 < messages.count {
      ChatMessageHelper.addTimeMessage(messages[fromIndex + 1], messages[fromIndex - 1])
    }

    // 更新新位置当前消息的时间
    if toIndex > 0 {
      ChatMessageHelper.addTimeMessage(resendModel, messages[toIndex])
    }

    // 更新新位置下一条消息的时间
    if toIndex + 1 < messages.count {
      ChatMessageHelper.addTimeMessage(messages[toIndex + 1], resendModel)
    }

    messages.remove(at: fromIndex)
    messages.insert(resendModel, at: toIndex)
    delegate?.onResendSuccess(IndexPath(row: fromIndex, section: 0), IndexPath(row: toIndex, section: 0))
  }

  /// 数字人回复的消息错误码映射
  /// - Parameter error: 错误信息
  /// - Parameter message: 消息
  func setErrorText(_ message: V2NIMMessage?) {
    guard let message = message else { return }
    if let content = ChatMessageHelper.getAIErrorMsage(message.messageStatus.errorCode) {
      message.text = content
    }
  }
}

// MARK: - NEChatListener

extension ChatViewModel: NEChatListener {
  /// 本端即将发送消息状态回调，此时消息还未发送，可对消息进行修改或者拦截发送
  /// 来源： 发送消息， 插入消息
  /// - Parameter message: 消息
  /// - Parameter completion: 是否继续发送消息
  public func readySendMessage(_ message: V2NIMMessage, _ completion: @escaping (Bool) -> Void) {
    delegate?.readySendMessage?(message, completion)
  }

  /// 本端发送消息状态回调
  /// 来源： 发送消息， 插入消息
  /// - Parameter message: 消息
  public func onSendMessage(_ message: V2NIMMessage) {
    switch message.sendingState {
    case .MESSAGE_SENDING_STATE_SENDING:
      sendingMsg(message)
    case .MESSAGE_SENDING_STATE_FAILED:
      sendMsgFailed(message, nil)
    case .MESSAGE_SENDING_STATE_SUCCEEDED:
      sendMsgSuccess(message)
    default:
      break
    }
  }

  /// 消息发送失败
  /// - Parameters:
  ///   - message: 消息
  ///   - error: 错误信息
  public func sendMessageFailed(_ message: V2NIMMessage, _ error: NSError) {
    sendMsgFailed(message, error)
  }

  /// 收到消息
  /// - Parameter messages: 消息列表
  public func onReceiveMessages(_ messages: [V2NIMMessage]) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messages.count: \(messages.count), first.messageID: \(messages.first?.messageClientId ?? "")")

    for msg in messages {
      guard V2NIMConversationIdUtil.conversationTargetId(msg.conversationId ?? "") == sessionId else {
        return
      }

      if !(msg.messageServerId?.isEmpty == false), msg.messageType != .MESSAGE_TYPE_CUSTOM {
        continue
      }
      newMsg = msg

      if isHistoryChat {
        delegate?.dataReload?()
        return
      }

      // 数字人回复的消息
      if ChatMessageHelper.isAISender(msg) {
        setErrorText(msg)
      }

      modelFromMessage(message: msg) { [weak self] model in
        ChatMessageHelper.addTimeMessage(model, self?.messages.last)
        self?.downloadAudioFile([model])
        self?.loadReply(model) {
          if let index = self?.insertToMessages(model) {
            self?.delegate?.onRecvMessages(messages, [IndexPath(row: index, section: 0)])
            self?.loadMoreWithMessage([msg])
          }
        }
      }
    }
  }

  /// 消息撤回回调
  /// - Parameter revokeNotifications: 撤回通知
  public func onMessageRevokeNotifications(_ revokeNotifications: [V2NIMMessageRevokeNotification]) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", revokeNotifications.count: \(revokeNotifications.count)")
    for revokeNoti in revokeNotifications {
      if revokeNoti.messageRefer?.conversationId != conversationId {
        continue
      }
      if revokeNoti.messageRefer?.messageClientId?.isEmpty == true {
        continue
      }

      // 移除置顶效果
      if topMessage?.messageClientId == revokeNoti.messageRefer?.messageClientId {
        topMessage = nil
        delegate?.setTopValue(name: nil, content: nil, url: nil, isVideo: false, hideClose: false)
      }

      for model in messages {
        if let msg = model.message, msg.messageClientId == revokeNoti.messageRefer?.messageClientId {
          msg.localExtension = revokeNoti.serverExtension
          revokeMessageUpdateUI(msg)
          break
        }
      }
    }
  }

  /// 消息删除成功回调。当本地端或多端同步删除消息成功时会触发该回调。
  /// - Parameter messageDeletedNotification: 删除通知
  public func onMessageDeletedNotifications(_ messageDeletedNotification: [V2NIMMessageDeletedNotification]) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageDeletedNotification.count: \(messageDeletedNotification.count)")

    var deleteMessages = [V2NIMMessage]()
    for message in messageDeletedNotification {
      if message.messageRefer.conversationId != conversationId {
        continue
      }
      if message.messageRefer.messageClientId?.isEmpty == true {
        continue
      }

      // 移除置顶效果
      if topMessage?.messageClientId == message.messageRefer.messageClientId {
        topMessage = nil
        delegate?.setTopValue(name: nil, content: nil, url: nil, isVideo: false, hideClose: false)
      }

      for model in messages {
        if let msg = model.message, msg.messageClientId == message.messageRefer.messageClientId {
          deleteMessages.append(msg)
        }
      }
    }

    deleteMessageUpdateUI(deleteMessages)
  }

  /// 消息清空成功回调。当本地端或多端同步清空消息成功时会触发该回调。
  /// - Parameter clearHistoryNotification: 清空通知
  public func onClearHistoryNotifications(_ clearHistoryNotification: [V2NIMClearHistoryNotification]) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", clearHistoryNotification.count: \(clearHistoryNotification.count)")
  }

  /// 消息pin状态回调通知
  /// - Parameter pinNotification: 消息pin状态变化通知数据
  public func onMessagePinNotification(_ pinNotification: V2NIMMessagePinNotification) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId:\(String(describing: pinNotification.pin?.messageRefer?.messageClientId)), pinStatus:\(pinNotification.pinState.rawValue)")
    if pinNotification.pinState == .MESSAGE_PIN_STEATE_PINNED {
      // 置顶
      var index = -1
      for (i, model) in messages.enumerated() {
        if pinNotification.pin?.messageRefer?.messageServerId == model.message?.messageServerId {
          messages[i].isPined = true
          let pinID = pinNotification.pin?.operatorId ?? IMKitClient.instance.account()
          messages[i].pinAccount = pinID

          if let _ = ChatMessageHelper.getUserFromCache(pinID) {
            messages[i].pinShowName = getShowName(pinID)
          } else {
            loadShowName([pinID], sessionId) { [weak self] in
              self?.messages[i].pinShowName = self?.getShowName(pinID)
              if let msg = self?.messages[i].message {
                self?.delegate?.onMessagePinStatusChange(msg, atIndexs: [IndexPath(row: i, section: 0)])
              }
            }
          }
          index = i
          break
        }
      }
      if index >= 0, let msg = messages[index].message {
        delegate?.onMessagePinStatusChange(msg, atIndexs: [IndexPath(row: index, section: 0)])
      }
    } else if pinNotification.pinState == .MESSAGE_PIN_STEATE_NOT_PINNED {
      // 取消置顶
      var index = -1
      for (i, model) in messages.enumerated() {
        if pinNotification.pin?.messageRefer?.messageServerId == model.message?.messageServerId {
          if !messages[i].isPined {
            return
          }
          messages[i].isPined = false
          messages[i].pinAccount = nil
          messages[i].pinShowName = nil
          index = i
          break
        }
      }
      if index >= 0, let msg = messages[index].message {
        delegate?.onMessagePinStatusChange(msg, atIndexs: [IndexPath(row: index, section: 0)])
      }
    }
  }

  /// 消息评论状态回调
  /// - Parameter notification: 快捷评论通知数据
  public func onMessageQuickCommentNotification(_ notification: V2NIMMessageQuickCommentNotification) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", quickComment.index: \(notification.quickComment.index)")
  }

  /// 收到点对点已读回执
  /// - Parameter readReceipts: 已读回执
  public func onReceiveP2PMessageReadReceipts(_ readReceipts: [V2NIMP2PMessageReadReceipt]) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", readReceipts.count: \(readReceipts.count)")
    var reloadIndexPaths: [IndexPath] = []
    for readReceipt in readReceipts {
      if readReceipt.conversationId != conversationId {
        continue
      }

      for (i, model) in messages.enumerated() {
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
          reloadIndexPaths.append(IndexPath(row: i, section: 0))
        }
      }
    }
    delegate?.onLoadMoreWithMessage(reloadIndexPaths)
  }

  /// 收到群已读回执
  /// - Parameter readReceipts: 已读回执
  public func onReceiveTeamMessageReadReceipts(_ readReceipts: [V2NIMTeamMessageReadReceipt]) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", readReceipts.count: \(readReceipts.count)")
    var reloadIndexPaths: [IndexPath] = []
    for readReceipt in readReceipts {
      if readReceipt.conversationId != conversationId {
        continue
      }

      for (i, model) in messages.enumerated() {
        if model.message?.isSelf == false {
          continue
        }

        if model.message?.messageConfig?.readReceiptEnabled == false {
          continue
        }

        if model.message?.messageClientId == readReceipt.messageClientId {
          model.readCount = readReceipt.readCount
          model.unreadCount = readReceipt.unreadCount
          reloadIndexPaths.append(IndexPath(row: i, section: 0))
        }
      }
    }
    delegate?.onLoadMoreWithMessage(reloadIndexPaths)
  }
}

// MARK: AI Listener

extension ChatViewModel: V2NIMAIListener {
  public func onProxyAIModelCall(_ data: V2NIMAIModelCallResult) {
    if data.code == aiUserRequestSuccess {
      if data.requestId == translationlanguageRquestId {
        delegate?.didTranslateResult?(data.content.msg)
        NEALog.infoLog(className(), desc: #function + " ai translate result : \(data.content.msg)")
      }
    }
  }

  /// 翻译
  /// - Parameter 需要翻译文本
  /// - Parameter 目标语言
  public func translateLanguage(_ sourceText: String, targetLanguage: String, _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(className(), desc: #function + " ai translate source : \(sourceText)")

    let request = V2NIMProxyAIModelCallParams()
    translationlanguageRquestId = UUID().uuidString
    request.requestId = translationlanguageRquestId

    let content = V2NIMAIModelCallContent()
    content.msg = sourceText
    content.type = .NIM_AI_MODEL_CONTENT_TYPE_TEXT

    request.content = content

    let configParams = V2NIMAIModelConfigParams()
    configParams.temperature = NEAIUserManager.shared.getTranslatePromptValue()
    request.modelConfigParams = configParams

    if let accountId = translationAIUser?.accountId {
      request.accountId = accountId
    }

    let promptKey = NEAIUserManager.shared.getTranslatePromptKey()
    let promptVariables = [promptKey: targetLanguage]
    let jsonString = getJSONStringFromDictionary(promptVariables)
    request.promptVariables = jsonString

    AIRepo.shared.proxyAIModelCall(request) { error in
      completion(error)
    }
  }
}
