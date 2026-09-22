// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NIMSDK

@objc
public protocol TopicChatViewModelOutput: NSObjectProtocol {
  func onTopicChanged(_ topic: V2NIMTopic)
  @objc optional func onTopicTipMessage(_ text: String)
  @objc optional func onCurrentTopicRemoved()
}

@objcMembers
open class TopicChatViewModel: P2PChatViewModel, NETopicListener {
  public let topicRepo = TopicRepo.shared
  public var topic: V2NIMTopic?
  public let sessionName: String

  private var oldestTopicMessage: V2NIMMessage?
  private var newestTopicMessage: V2NIMMessage?
  private var olderTopicAnchorMessage: V2NIMMessage?
  private var hasMoreOlderTopicMessages = false
  private var hasMoreNewerTopicMessages = false
  private var creatingTopicMessageIds = Set<String>()
  private var pendingAutoNameMessage: V2NIMMessage?
  private var pendingAutoNameTopicRefer: V2NIMTopicRefer?
  private var pendingAutoNameConversationId: String?
  private var isAutoNamingTopic = false
  private var isRemovingCurrentTopic = false
  private var didNotifyCurrentTopicRemoved = false

  override open var supportsLastReadPosition: Bool {
    false
  }

  // MARK: - Init

  public init(conversationId: String,
              anchor: V2NIMMessage?,
              topic: V2NIMTopic?,
              sessionName: String) {
    self.topic = topic
    self.sessionName = sessionName
    super.init(conversationId: conversationId, anchor: anchor)
    topicRepo.addTopicListener(self)
  }

  deinit {
    topicRepo.removeTopicListener(self)
  }

  open func currentTitle() -> String {
    if let title = topic?.topicName?.trimmingCharacters(in: .whitespacesAndNewlines),
       !title.isEmpty {
      return title
    }
    return sessionName
  }

  // MARK: - Topic Matching

  private func isCurrentTopicMessage(_ message: V2NIMMessage) -> Bool {
    guard message.conversationId == ChatRepo.conversationId else {
      return false
    }
    if let currentTopic = topic {
      guard let topicRefer = message.topicRefer else {
        return false
      }
      return isSameTopic(currentTopic, topicRefer)
    }
    if let clientId = message.messageClientId {
      if creatingTopicMessageIds.contains(clientId) {
        return true
      }
    }
    if let pendingTopicRefer = pendingAutoNameTopicRefer,
       let messageTopicRefer = message.topicRefer {
      return isSameTopic(pendingTopicRefer, messageTopicRefer)
    }
    return false
  }

  private func removeCreatingMessageId(_ message: V2NIMMessage) {
    if let clientId = message.messageClientId {
      creatingTopicMessageIds.remove(clientId)
    }
  }

  private func updateCurrentTopic(_ topic: V2NIMTopic) {
    self.topic = topic
    (delegate as? TopicChatViewModelOutput)?.onTopicChanged(topic)
    tryAutoNamePendingTopic()
  }

  private func notifyCurrentTopicRemovedIfNeeded() {
    guard !didNotifyCurrentTopicRemoved else {
      return
    }
    didNotifyCurrentTopicRemoved = true
    (delegate as? TopicChatViewModelOutput)?.onCurrentTopicRemoved?()
  }

  private func isSameTopic(_ left: V2NIMTopicRefer, _ right: V2NIMTopicRefer) -> Bool {
    left.conversationId == right.conversationId &&
      left.topicId == right.topicId &&
      left.createTime == right.createTime
  }

  private func isSameTopic(_ left: V2NIMTopic, _ right: V2NIMTopicRefer) -> Bool {
    left.conversationId == right.conversationId &&
      left.topicId == right.topicId &&
      left.createTime == right.createTime
  }

  private func isSameTopic(_ left: V2NIMTopic, _ right: V2NIMTopic) -> Bool {
    left.conversationId == right.conversationId &&
      left.topicId == right.topicId &&
      left.createTime == right.createTime
  }

  private func isPendingAutoNameTopic(_ topic: V2NIMTopic) -> Bool {
    guard let conversationId = pendingAutoNameConversationId,
          topic.conversationId == conversationId else {
      return false
    }
    guard let message = pendingAutoNameMessage else {
      return false
    }
    if let topicRefer = pendingAutoNameTopicRefer {
      return isSameTopic(topic, topicRefer)
    }
    if let messageClientId = message.messageClientId,
       !messageClientId.isEmpty,
       let topicMessageClientId = topic.messageClientId,
       !topicMessageClientId.isEmpty {
      return messageClientId == topicMessageClientId
    }
    if let messageServerId = message.messageServerId,
       !messageServerId.isEmpty,
       let topicMessageServerId = topic.messageServerId,
       !topicMessageServerId.isEmpty {
      return messageServerId == topicMessageServerId
    }
    return true
  }

  // MARK: - Auto Naming

  private func defaultTopicName(for message: V2NIMMessage) -> String {
    let text = compactTopicText(message.text)
    if message.messageType == .MESSAGE_TYPE_TEXT, !text.isEmpty {
      return String(text.prefix(20))
    }

    let summary = ChatMessageHelper.conversationListSummary(message)
      .trimmingCharacters(in: .whitespacesAndNewlines)
    if !summary.isEmpty {
      return String(summary.prefix(20))
    }

    return sessionName
  }

  private func compactTopicText(_ text: String?) -> String {
    (text ?? "")
      .components(separatedBy: .whitespacesAndNewlines)
      .filter { !$0.isEmpty }
      .joined(separator: " ")
  }

  private func syncTopicFromMessage(_ message: V2NIMMessage) {
    guard topic == nil,
          let topicRefer = message.topicRefer else {
      return
    }
    pendingAutoNameTopicRefer = topicRefer
    topicRepo.getTopicByRefer(topicRefer) { [weak self] topic, _ in
      guard let topic = topic else {
        return
      }
      self?.updateCurrentTopic(topic)
    }
  }

  private func loadPendingTopicIfNeeded() {
    guard topic == nil,
          let conversationId = pendingAutoNameConversationId else {
      return
    }
    let option = V2NIMTopicListOption()
    option.conversationId = conversationId
    option.limit = 20
    option.direction = .QUERY_DIRECTION_DESC
    option.beginTime = 0
    option.endTime = 0
    topicRepo.getTopicListByOption(option) { [weak self] result, _ in
      guard let self,
            self.topic == nil else {
        return
      }
      if let matchedTopic = result?.topicList.first(where: { self.isPendingAutoNameTopic($0) }) {
        self.updateCurrentTopic(matchedTopic)
      }
    }
  }

  private func tryAutoNamePendingTopic() {
    guard let currentTopic = topic,
          let firstMessage = pendingAutoNameMessage,
          !isAutoNamingTopic else {
      return
    }
    if let topicRefer = pendingAutoNameTopicRefer,
       !isSameTopic(currentTopic, topicRefer) {
      return
    }
    let existingName = currentTopic.topicName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard existingName.isEmpty else {
      clearPendingAutoName()
      return
    }
    let params = V2NIMUpdateTopicParams()
    params.topic = currentTopic
    params.topicName = defaultTopicName(for: firstMessage)
    isAutoNamingTopic = true
    topicRepo.updateTopic(params) { [weak self] updatedTopic, _ in
      self?.isAutoNamingTopic = false
      if let updatedTopic = updatedTopic {
        self?.clearPendingAutoName()
        self?.updateCurrentTopic(updatedTopic)
      }
    }
  }

  private func clearPendingAutoName() {
    pendingAutoNameMessage = nil
    pendingAutoNameTopicRefer = nil
    pendingAutoNameConversationId = nil
    isAutoNamingTopic = false
  }

  private func clearPendingAutoNameIfSame(_ message: V2NIMMessage) {
    guard pendingAutoNameMessage?.messageClientId == message.messageClientId else {
      return
    }
    clearPendingAutoName()
  }

  // MARK: - Message Cache

  private func appendMessageClientIdIfNeeded(_ message: V2NIMMessage) {
    guard let messageClientId = message.messageClientId,
          !messageClientIds.contains(messageClientId) else {
      return
    }
    messageClientIds.append(messageClientId)
  }

  private func updateHistoryAnchor(_ message: V2NIMMessage) {
    if oldestTopicMessage == nil || message.createTime < (oldestTopicMessage?.createTime ?? 0) {
      oldestTopicMessage = message
    }
    if newestTopicMessage == nil || message.createTime > (newestTopicMessage?.createTime ?? 0) {
      newestTopicMessage = message
    }
  }

  private func uniqueTopicMessages(_ messages: [V2NIMMessage]) -> [V2NIMMessage] {
    var result = [V2NIMMessage]()
    var keys = Set<String>()
    for message in messages {
      let key = topicMessageKey(message)
      if keys.contains(key) {
        continue
      }
      keys.insert(key)
      result.append(message)
    }
    return result
  }

  private func topicMessageKey(_ message: V2NIMMessage) -> String {
    if let clientId = message.messageClientId, !clientId.isEmpty {
      return "client:\(clientId)"
    }
    if let serverId = message.messageServerId, !serverId.isEmpty {
      return "server:\(serverId)"
    }
    return "time:\(message.createTime)-type:\(String(describing: message.messageType))"
  }

  // MARK: - Topic History

  open func loadTopicData(_ completion: @escaping (Error?, NSInteger, NSInteger, Int) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    messages.removeAll()
    messageClientIds.removeAll()
    delegate?.tableViewReload()
    oldestTopicMessage = nil
    newestTopicMessage = nil
    olderTopicAnchorMessage = nil
    hasMoreOlderTopicMessages = false
    hasMoreNewerTopicMessages = false
    isHistoryChat = false

    guard topic != nil else {
      completion(nil, 0, 0, 0)
      return
    }

    getTopicHistory(order: .QUERY_DIRECTION_DESC, anchorMessage: nil) { [weak self] error, count, loaded in
      completion(error, count, 0, 0)
      if count > 0 {
        self?.loadMoreWithMessage(loaded)
      }
    }
  }

  open func getTopicHistory(order: V2NIMQueryDirection,
                            anchorMessage: V2NIMMessage?,
                            _ completion: @escaping (Error?, NSInteger, [V2NIMMessage]) -> Void) {
    guard let currentTopic = topic else {
      completion(nil, 0, [])
      return
    }

    let option = V2NIMTopicMessageListOption()
    option.topic = currentTopic
    option.limit = 100
    option.anchorMessage = anchorMessage
    option.direction = order
    option.sortOrder = .SORT_ORDER_ASC
    option.beginTime = 0
    option.endTime = 0

    topicRepo.getTopicMessageList(option) { [weak self] result, error in
      let rawMessages = result?.replyList ?? []
      let loaded = self?.uniqueTopicMessages(rawMessages).sorted { $0.createTime < $1.createTime } ?? []
      self?.appendTopicMessages(loaded, order: order, result: result)
      completion(error, loaded.count, loaded)
    }
  }

  private func appendTopicMessages(_ loaded: [V2NIMMessage],
                                   order: V2NIMQueryDirection,
                                   result: V2NIMTopicMessageListResult?) {
    if order == .QUERY_DIRECTION_DESC {
      olderTopicAnchorMessage = result?.anchorMessage ?? loaded.first
      hasMoreOlderTopicMessages = result?.hasMore ?? false
    } else {
      newestTopicMessage = result?.anchorMessage ?? loaded.last ?? newestTopicMessage
      hasMoreNewerTopicMessages = result?.hasMore ?? !loaded.isEmpty
    }
    for msg in loaded {
      appendMessageClientIdIfNeeded(msg)
      updateHistoryAnchor(msg)

      if ChatMessageHelper.isAISender(msg) {
        setErrorText(msg)
      }

      if messages.contains(where: { $0.message?.messageClientId == msg.messageClientId }) == false {
        insertToMessages(modelFromMessage(message: msg))
      }
    }
    if !loaded.isEmpty {
      addTimeForHistoryMessage()
    }
  }

  override open func loadData(_ completion: @escaping (Error?, NSInteger, NSInteger, Int) -> Void) {
    loadTopicData(completion)
  }

  override open func dropDownRemoteRefresh(_ completion: @escaping (Error?, NSInteger, [V2NIMMessage]) -> Void) {
    guard hasMoreOlderTopicMessages else {
      completion(nil, 0, [])
      return
    }
    let anchorMessage = olderTopicAnchorMessage ?? oldestTopicMessage ?? messages.first?.message
    getTopicHistory(order: .QUERY_DIRECTION_DESC, anchorMessage: anchorMessage) { [weak self] error, count, loaded in
      completion(error, count, loaded)
      if count > 0 {
        self?.loadMoreWithMessage(loaded)
      }
    }
  }

  override open func pullRemoteRefresh(_ completion: @escaping (Error?, NSInteger, [V2NIMMessage]) -> Void) {
    guard hasMoreNewerTopicMessages || newestTopicMessage != nil || messages.last?.message != nil else {
      completion(nil, 0, [])
      return
    }
    let anchorMessage = newestTopicMessage ?? messages.last?.message
    getTopicHistory(order: .QUERY_DIRECTION_ASC, anchorMessage: anchorMessage) { [weak self] error, count, loaded in
      completion(error, count, loaded)
      if count > 0 {
        self?.loadMoreWithMessage(loaded)
      }
    }
  }

  // MARK: - Topic Send

  override open func sendMessage(message: V2NIMMessage,
                                 conversationId: String? = nil,
                                 params: V2NIMSendMessageParams? = nil,
                                 _ completion: @escaping (V2NIMMessage?, Error?, UInt) -> Void) {
    let requestedConversationId = conversationId ?? ChatRepo.conversationId
    let currentConversationId = ChatRepo.conversationId
    let isCurrentTopicTarget = requestedConversationId == currentConversationId ||
      requestedConversationId.hasPrefix(currentConversationId + "|")

    // Forwarding can target a normal conversation. Only use the Topic API for
    // the current bot conversation; other targets must use the base sender.
    guard isCurrentTopicTarget else {
      super.sendMessage(message: message,
                        conversationId: requestedConversationId,
                        params: params,
                        completion)
      return
    }

    let finalConversationId = currentConversationId
    let topicParams = V2NIMSendTopicMessageParams()
    topicParams.sendMessageParams = params
    if topic == nil {
      if let clientId = message.messageClientId {
        creatingTopicMessageIds.insert(clientId)
      }
      pendingAutoNameMessage = message
      pendingAutoNameTopicRefer = nil
      pendingAutoNameConversationId = finalConversationId
      topicParams.createTopicParams = V2NIMCreateTopicParams()
    }

    topicRepo.sendTopicMessage(message: message,
                               conversationId: finalConversationId,
                               topic: topic,
                               params: topicParams) { [weak self] result, error, progress in
      if IMKitConfigCenter.shared.enableAntiSpamTipMessage {
        self?.checkAntiSpam(result: result)
      }
      if let msg = result?.message {
        if self?.pendingAutoNameMessage?.messageClientId == message.messageClientId {
          self?.pendingAutoNameMessage = msg
          self?.pendingAutoNameTopicRefer = msg.topicRefer
        }
        self?.syncTopicFromMessage(msg)
        self?.tryAutoNamePendingTopic()
        if self?.topic == nil {
          self?.loadPendingTopicIfNeeded()
        }
      }
      if error != nil {
        if let error = error {
          // Topic sending bypasses ChatRepo's failure fan-out. Forward the
          // failure here so the message can leave the loading state.
          DispatchQueue.main.async { [weak self] in
            self?.sendMessageFailed(message, error)
          }
        }
        self?.removeCreatingMessageId(message)
        self?.clearPendingAutoNameIfSame(message)
      } else if let sentMessage = result?.message {
        // Keep the direct Topic API on the same terminal-state path as normal
        // message sending when its callback arrives before the SDK listener.
        DispatchQueue.main.async { [weak self] in
          self?.sendMsgSuccess(sentMessage)
        }
      }
      completion(result?.message ?? message, error, progress)
    }
  }

  /// Topic anti-spam tips are transient UI feedback and must not be inserted
  /// into the parent conversation or the Topic message list.
  override open func insertTipMessage(_ text: String,
                                      _ createTime: TimeInterval? = nil,
                                      _ conversationId: String? = nil,
                                      _ senderId: String? = nil) {
    guard (conversationId ?? ChatRepo.conversationId) == ChatRepo.conversationId else {
      return
    }
    let notify: () -> Void = { [weak self] in
      if let output = self?.delegate as? TopicChatViewModelOutput {
        output.onTopicTipMessage?(text)
      }
    }
    if Thread.isMainThread {
      notify()
    } else {
      DispatchQueue.main.async(execute: notify)
    }
  }

  override open func replyMessageWithThread(message: V2NIMMessage,
                                            replyMessage: V2NIMMessage,
                                            aiUserAccid: String? = nil,
                                            _ completion: @escaping (V2NIMMessage?, Error?) -> Void) {
    guard let currentTopic = topic else {
      guard let topicRefer = replyMessage.topicRefer ??
        message.topicRefer ?? pendingAutoNameTopicRefer else {
        sendMessage(message: message) { sentMessage, error, _ in
          completion(sentMessage, error)
        }
        return
      }
      topicRepo.getTopicByRefer(topicRefer) { [weak self] resolvedTopic, error in
        guard let self,
              let resolvedTopic else {
          completion(nil, error)
          return
        }
        self.updateCurrentTopic(resolvedTopic)
        let params = self.getReplyMessageParams(aiUserAccid, replyMessage, message)
        self.topicRepo.replyTopicMessage(message: message,
                                         replyMessage: replyMessage,
                                         topic: resolvedTopic,
                                         params: params) { result, replyError, _ in
          completion(result?.message, replyError)
        }
      }
      return
    }
    let params = getReplyMessageParams(aiUserAccid, replyMessage, message)
    topicRepo.replyTopicMessage(message: message,
                                replyMessage: replyMessage,
                                topic: currentTopic,
                                params: params) { result, error, _ in
      completion(result?.message, error)
    }
  }

  // MARK: - Reply / Revoke

  override open func getReplyMessage(message: V2NIMMessage) -> MessageModel? {
    var replyId: String?
    let replyDic = ChatMessageHelper.getReplyDictionary(message: message)
    replyId = replyDic?["idClient"] as? String

    if shouldShowThreadReply(message),
       let threadId = message.threadReply?.messageClientId, !threadId.isEmpty {
      replyId = threadId
    }

    guard let replyId = replyId, !replyId.isEmpty else {
      return nil
    }

    for model in messages {
      if model.message?.messageClientId == replyId, model.isRevoked == false {
        return model
      }
    }

    let model = MessageTextModel(message: nil)
    if let replySenderId = replySenderId(message: message, replyDic: replyDic) {
      model.fullName = replySenderId
    }
    return model
  }

  override open func getReplyMessage(message: V2NIMMessage,
                                     _ completion: @escaping (MessageModel?) -> Void) {
    var replyId: String?
    let replyDic = ChatMessageHelper.getReplyDictionary(message: message)
    replyId = replyDic?["idClient"] as? String

    if shouldShowThreadReply(message),
       let threadId = message.threadReply?.messageClientId, !threadId.isEmpty {
      replyId = threadId
    }

    guard let replyId = replyId, !replyId.isEmpty else {
      completion(nil)
      return
    }

    for model in messages {
      if model.message?.messageClientId == replyId, !model.isRevoked {
        completion(model)
        return
      }
    }

    let refer = messageRefer(message: message, replyDic: replyDic)
    chatRepo.getMessageListByRefers([refer]) { [weak self] messages, _ in
      if let message = messages?.first {
        self?.modelFromMessage(message: message) { model in
          completion(model)
        }
      } else {
        completion(nil)
      }
    }
  }

  override open func revokeMessage(message: V2NIMMessage, _ completion: @escaping (Error?) -> Void) {
    var muta = [String: Any]()

    if let serverExt = getDictionaryFromJSONString(message.serverExtension ?? "") as? [String: Any] {
      muta = serverExt
    }

    if shouldShowThreadReply(message),
       let threadReply = message.threadReply,
       message.threadReply?.messageClientId?.isEmpty == false {
      muta[keyReplyMsgKey] = ChatMessageHelper.createReplyDic(threadReply)
    }

    muta[revokeLocalMessage] = true
    muta[revokeLocalMessageTime] = Date().timeIntervalSince1970
    if message.messageType == .MESSAGE_TYPE_TEXT {
      muta[revokeLocalMessageContent] = message.text
    }

    if message.messageType == .MESSAGE_TYPE_CUSTOM {
      if let title = NECustomUtils.titleOfRichText(message.attachment), !title.isEmpty {
        muta[revokeLocalMessageTitle] = title
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

  override open func shouldShowThreadReply(_ message: V2NIMMessage?) -> Bool {
    guard let message = message,
          let threadReply = message.threadReply,
          let replyClientId = threadReply.messageClientId,
          !replyClientId.isEmpty else {
      return false
    }
    guard let threadRoot = message.threadRoot else {
      return true
    }
    return !isSameMessageRefer(threadRoot, threadReply)
  }

  private func isSameMessageRefer(_ left: V2NIMMessageRefer, _ right: V2NIMMessageRefer) -> Bool {
    if let leftClientId = left.messageClientId,
       let rightClientId = right.messageClientId,
       !leftClientId.isEmpty,
       leftClientId == rightClientId {
      return true
    }
    if let leftServerId = left.messageServerId,
       let rightServerId = right.messageServerId,
       !leftServerId.isEmpty,
       leftServerId == rightServerId,
       left.createTime == right.createTime {
      return true
    }
    return false
  }

  @discardableResult
  override open func deleteMessageModel(_ message: V2NIMMessage) -> (deleteIndexs: [Int], reloadIndexs: [Int]) {
    guard let messageClientId = message.messageClientId, !messageClientId.isEmpty else {
      return ([], [])
    }
    return deleteMessageModel(messageClientId)
  }

  override open func revokeMessageUpdateUI(_ message: V2NIMMessage) {
    super.revokeMessageUpdateUI(message)
  }

  override func replyMessageId(_ message: V2NIMMessage?) -> String? {
    guard let message = message else {
      return nil
    }
    if shouldShowThreadReply(message),
       let threadId = message.threadReply?.messageClientId,
       !threadId.isEmpty {
      return threadId
    }
    if let remoteExt = getDictionaryFromJSONString(message.serverExtension ?? ""),
       let yxReplyMsg = remoteExt[keyReplyMsgKey] as? [String: Any] {
      return yxReplyMsg["idClient"] as? String
    }
    return nil
  }

  private func replySenderId(message: V2NIMMessage, replyDic: [String: Any]?) -> String? {
    if shouldShowThreadReply(message),
       let senderId = message.threadReply?.senderId,
       !senderId.isEmpty {
      return senderId
    }
    return replyDic?["from"] as? String
  }

  private func messageRefer(message: V2NIMMessage, replyDic: [String: Any]?) -> V2NIMMessageRefer {
    let refer = ChatMessageHelper.createMessageRefer(replyDic)
    guard shouldShowThreadReply(message),
          let threadReply = message.threadReply else {
      return refer
    }
    if let senderId = threadReply.senderId, !senderId.isEmpty {
      refer.senderId = senderId
    }
    if let receiverId = threadReply.receiverId, !receiverId.isEmpty {
      refer.receiverId = receiverId
    }
    if let messageClientId = threadReply.messageClientId, !messageClientId.isEmpty {
      refer.messageClientId = messageClientId
    }
    if let messageServerId = threadReply.messageServerId, !messageServerId.isEmpty {
      refer.messageServerId = messageServerId
    }
    refer.conversationType = threadReply.conversationType
    if let conversationId = threadReply.conversationId, !conversationId.isEmpty {
      refer.conversationId = conversationId
    }
    refer.createTime = threadReply.createTime
    return refer
  }

  // MARK: - Message Listener

  override open func onSendMessage(_ message: V2NIMMessage) {
    guard isCurrentTopicMessage(message) else {
      return
    }
    syncTopicFromMessage(message)
    appendMessageClientIdIfNeeded(message)
    updateHistoryAnchor(message)
    switch message.sendingState {
    case .MESSAGE_SENDING_STATE_SENDING:
      sendingMsg(message)
    case .MESSAGE_SENDING_STATE_FAILED:
      sendMsgFailed(message, nil)
      removeCreatingMessageId(message)
      clearPendingAutoNameIfSame(message)
    case .MESSAGE_SENDING_STATE_SUCCEEDED:
      sendMsgSuccess(message)
      removeCreatingMessageId(message)
    default:
      break
    }
  }

  override open func sendMessageFailed(_ message: V2NIMMessage, _ error: NSError) {
    guard isCurrentTopicMessage(message) else {
      return
    }
    removeCreatingMessageId(message)
    clearPendingAutoNameIfSame(message)
    sendMsgFailed(message, error)
  }

  override open func onReceiveMessages(_ messages: [V2NIMMessage]) {
    let filtered = messages.filter { isCurrentTopicMessage($0) }
    if filtered.isEmpty {
      return
    }

    for msg in filtered {
      if !(msg.messageServerId?.isEmpty == false), msg.messageType != .MESSAGE_TYPE_CUSTOM {
        continue
      }
      if let messageClientId = msg.messageClientId, messageClientIds.contains(messageClientId) {
        continue
      }
      appendMessageClientIdIfNeeded(msg)
      updateHistoryAnchor(msg)

      if ChatMessageHelper.isAISender(msg) {
        setErrorText(msg)
      }

      if isHistoryChat {
        delegate?.onRecvMessages(filtered, [])
        return
      }

      modelFromMessage(message: msg) { [weak self] model in
        ChatMessageHelper.addTimeMessage(model, self?.messages.last)
        self?.downloadAudioFile([model])
        self?.loadReply(model) {
          if let index = self?.insertToMessages(model) {
            self?.delegate?.onRecvMessages([msg], [IndexPath(row: index, section: 0)])
            self?.loadMoreWithMessage([msg])
            if let textModel = model as? MessageTextModel {
              self?.autoTranslateIfNeeded(model: textModel)
            }
          }
        }
      }
    }
  }

  override open func onReceiveMessagesModified(_ messages: [V2NIMMessage]) {
    let filtered = messages.filter { isCurrentTopicMessage($0) }
    if filtered.isEmpty {
      return
    }
    for msg in filtered {
      for (index, model) in self.messages.enumerated() {
        if let model = model as? MessageContentModel,
           model.message?.messageClientId == msg.messageClientId {
          model.resetMessage(msg)
          if index > 0 {
            ChatMessageHelper.addTimeMessage(model, self.messages[index - 1])
          }
          delegate?.getMessageModel?(model: model)
          self.messages[index] = model
          delegate?.onModefiedMessage(IndexPath(row: index, section: 0))
          break
        }
      }
    }
  }

  override open func onMessageRevokeNotifications(_ revokeNotifications: [V2NIMMessageRevokeNotification]) {
    let filtered = revokeNotifications.filter { notification in
      guard let messageRefer = notification.messageRefer else {
        return false
      }
      return messages.contains { model in
        guard let currentMessage = model.message else {
          return false
        }
        return isSameMessage(currentMessage, messageRefer)
      }
    }
    guard !filtered.isEmpty else {
      return
    }
    super.onMessageRevokeNotifications(filtered)
  }

  override open func onMessageDeletedNotifications(_ messageDeletedNotification: [V2NIMMessageDeletedNotification]) {
    let filtered = messageDeletedNotification.filter { notification in
      guard let messageClientId = notification.messageRefer.messageClientId else {
        return false
      }
      return messages.contains {
        $0.message?.messageClientId == messageClientId || replyMessageId($0.message) == messageClientId
      }
    }
    guard !filtered.isEmpty else {
      return
    }
    super.onMessageDeletedNotifications(filtered)
  }

  // MARK: - Topic Listener

  open func onTopicAdded(_ topic: V2NIMTopic) {
    guard self.topic == nil,
          pendingAutoNameMessage != nil,
          isPendingAutoNameTopic(topic) else {
      return
    }
    updateCurrentTopic(topic)
  }

  open func onTopicsRemoved(_ topics: [V2NIMTopicRefer]) {
    guard let currentTopic = topic else {
      return
    }
    if topics.contains(where: { $0.conversationId == ChatRepo.conversationId && $0.topicId == currentTopic.topicId }) {
      if isRemovingCurrentTopic {
        return
      }
      notifyCurrentTopicRemovedIfNeeded()
    }
  }

  open func onTopicUpdated(_ topic: V2NIMTopic) {
    guard let currentTopic = self.topic,
          isSameTopic(currentTopic, topic) else {
      return
    }
    updateCurrentTopic(topic)
  }

  // MARK: - Topic Actions

  open func updateTopicName(_ topicName: String,
                            _ completion: @escaping (V2NIMTopic?, NSError?) -> Void) {
    guard let currentTopic = topic else {
      completion(nil, nil)
      return
    }
    let params = V2NIMUpdateTopicParams()
    params.topic = currentTopic
    params.topicName = topicName
    topicRepo.updateTopic(params) { [weak self] topic, error in
      if let topic = topic {
        self?.updateCurrentTopic(topic)
      }
      completion(topic, error)
    }
  }

  open func removeCurrentTopic(_ completion: @escaping (NSError?) -> Void) {
    guard let currentTopic = topic else {
      completion(nil)
      return
    }
    isRemovingCurrentTopic = true
    didNotifyCurrentTopicRemoved = false
    let params = V2NIMRemoveTopicsParams()
    params.topicList = [currentTopic]
    topicRepo.removeTopics(params) { [weak self] error in
      if error != nil {
        self?.isRemovingCurrentTopic = false
      } else {
        self?.isRemovingCurrentTopic = false
        self?.notifyCurrentTopicRemovedIfNeeded()
      }
      completion(error)
    }
  }

  private func isSameMessage(_ message: V2NIMMessage, _ refer: V2NIMMessageRefer) -> Bool {
    if let messageClientId = message.messageClientId,
       let referClientId = refer.messageClientId,
       !messageClientId.isEmpty,
       messageClientId == referClientId {
      return true
    }
    if let messageServerId = message.messageServerId,
       let referServerId = refer.messageServerId,
       !messageServerId.isEmpty,
       messageServerId == referServerId,
       message.createTime == refer.createTime {
      return true
    }
    return message.conversationId == refer.conversationId && message.createTime == refer.createTime
  }
}
