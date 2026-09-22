// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NIMSDK

@objc
public protocol BotSubSessionListViewModelDelegate: NSObjectProtocol {
  func onBotSubSessionListReload()
}

public struct BotSubSessionItem {
  public let topic: V2NIMTopic
  public var summary: String?
  public var updateTime: TimeInterval
  public var hasUnread: Bool
}

@objcMembers
open class BotSubSessionListViewModel: NSObject, NETopicListener, NEChatListener, NEConversationListener, NELocalConversationListener {
  public weak var delegate: BotSubSessionListViewModelDelegate?
  public let topicRepo = TopicRepo.shared
  public let chatRepo = ChatRepo.shared
  public let conversationRepo = ConversationRepo.shared
  public let localConversationRepo = LocalConversationRepo.shared
  public var topicList = [V2NIMTopic]()
  public var displayTopicList = [V2NIMTopic]()
  public var topicSummaryMap = [UInt64: String]()
  public var topicSummaryTimeMap = [UInt64: TimeInterval]()
  public var topicLatestMessageFromSelfMap = [UInt64: Bool]()
  public var conversationId = ""
  public var sessionId = ""
  public var keyword = ""
  public var conversationReadTime: TimeInterval = 0
  private var summaryRequestVersion = 0
  private let maxSummaryLength = 30
  private let pageLimit = 100

  override public init() {
    super.init()
    topicRepo.addTopicListener(self)
    chatRepo.addChatListener(self)
    conversationRepo.addConversationListener(self)
    localConversationRepo.addLocalConversationListener(self)
  }

  deinit {
    topicRepo.removeTopicListener(self)
    chatRepo.removeChatListener(self)
    conversationRepo.removeConversationListener(self)
    localConversationRepo.removeLocalConversationListener(self)
  }

  open func loadData(conversationId: String,
                     sessionId: String,
                     _ completion: @escaping (NSError?) -> Void) {
    self.conversationId = conversationId
    self.sessionId = sessionId

    loadAllTopics(nextToken: nil, accumulator: []) { [weak self] list, error in
      guard let self else {
        completion(error)
        return
      }
      if error == nil {
        self.topicList = self.sortedTopics(list)
      } else {
        self.topicList.removeAll()
      }
      self.refreshConversationReadTime()
      self.reloadAllSummaries()
      self.applyFilter()
      self.delegate?.onBotSubSessionListReload()
      completion(error)
    }
  }

  open func item(at index: Int) -> BotSubSessionItem? {
    guard index >= 0, index < displayTopicList.count else {
      return nil
    }
    let topic = displayTopicList[index]
    return BotSubSessionItem(topic: topic,
                             summary: topicSummaryMap[topic.topicId],
                             updateTime: topicSummaryTimeMap[topic.topicId] ?? normalizedTimestamp(TimeInterval(topic.updateTime)),
                             hasUnread: hasUnread(topic: topic))
  }

  open func updateKeyword(_ keyword: String) {
    self.keyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
    applyFilter()
    delegate?.onBotSubSessionListReload()
  }

  open func refreshListStateIfNeeded() {
    guard !topicList.isEmpty else {
      return
    }
    refreshConversationReadTime()
  }

  open func onReceiveMessages(_ messages: [V2NIMMessage]) {
    let currentConversationMessages = messages.filter { $0.conversationId == conversationId }
    guard !currentConversationMessages.isEmpty else {
      return
    }
    let topicIds = collectTopicIds(from: currentConversationMessages)
    refreshTopicsIfNeeded(topicIds, refreshUnread: true)
  }

  open func onSendMessage(_ message: V2NIMMessage) {
    guard message.sendingState == .MESSAGE_SENDING_STATE_SUCCEEDED else {
      return
    }
    refreshTopicsIfNeeded(collectTopicIds(from: [message]), refreshUnread: false)
  }

  open func sendMessageFailed(_ message: V2NIMMessage, _ error: NSError) {
    refreshTopicsIfNeeded(collectTopicIds(from: [message]), refreshUnread: false)
  }

  open func onMessageDeletedNotifications(_ messageDeletedNotification: [V2NIMMessageDeletedNotification]) {
    let isCurrentConversation = messageDeletedNotification.contains { notification in
      notification.messageRefer.conversationId == conversationId
    }
    guard isCurrentConversation else {
      return
    }
    // 删除通知只携带消息引用，不包含 topicId；重新加载摘要才能准确处理
    // “最后一条消息被删除”以及删除后新的最近消息两种情况。
    reloadAllSummaries()
  }

  open func onMessageRevokeNotifications(_ revokeNotifications: [V2NIMMessageRevokeNotification]) {
    let messageRefers = revokeNotifications.compactMap { notification -> V2NIMMessageRefer? in
      guard let messageRefer = notification.messageRefer,
            messageRefer.conversationId == conversationId else {
        return nil
      }
      return messageRefer
    }
    guard !messageRefers.isEmpty else {
      return
    }
    chatRepo.getMessageListByRefers(messageRefers) { [weak self] messages, _ in
      guard let self else {
        return
      }
      let topicIds = self.collectTopicIds(from: messages ?? [])
      self.refreshTopicsIfNeeded(topicIds, refreshUnread: false)
    }
  }

  open func onReceiveMessagesModified(_ messages: [V2NIMMessage]) {
    let topicIds = collectTopicIds(from: messages)
    refreshTopicsIfNeeded(topicIds, refreshUnread: false)
  }

  open func onClearHistoryNotifications(_ clearHistoryNotification: [V2NIMClearHistoryNotification]) {
    guard clearHistoryNotification.contains(where: { $0.conversationId == conversationId }) else {
      return
    }
    reloadAllSummaries()
  }

  open func applyFilter() {
    guard !keyword.isEmpty else {
      displayTopicList = sortedTopics(topicList)
      return
    }
    let key = keyword.lowercased()
    displayTopicList = sortedTopics(topicList.filter { topic in
      let name = topic.topicName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      return name.lowercased().contains(key)
    })
  }

  private func loadAllTopics(nextToken: String?,
                             accumulator: [V2NIMTopic],
                             _ completion: @escaping ([V2NIMTopic], NSError?) -> Void) {
    let option = V2NIMTopicListOption()
    option.conversationId = conversationId
    option.limit = pageLimit
    option.direction = .QUERY_DIRECTION_DESC
    option.beginTime = 0
    option.endTime = 0
    option.nextToken = nextToken
    topicRepo.getTopicListByOption(option) { [weak self] result, error in
      guard let self else {
        completion(accumulator, error)
        return
      }
      if let error {
        completion(accumulator, error)
        return
      }
      let pageList = result?.topicList ?? []
      let merged = accumulator + pageList
      if result?.hasMore == true, let nextToken = result?.nextToken, !nextToken.isEmpty {
        self.loadAllTopics(nextToken: nextToken, accumulator: merged, completion)
      } else {
        completion(merged, nil)
      }
    }
  }

  open func loadSummaries() {
    reloadAllSummaries()
  }

  open func loadSummaries(for topics: [V2NIMTopic]) {
    loadSummaries(for: topics, invalidatePending: false)
  }

  private func reloadAllSummaries() {
    loadSummaries(for: topicList, invalidatePending: true)
  }

  private func loadSummaries(for topics: [V2NIMTopic], invalidatePending: Bool) {
    if invalidatePending {
      summaryRequestVersion += 1
    }
    let currentVersion = summaryRequestVersion
    if invalidatePending {
      topicSummaryMap.removeAll()
      topicSummaryTimeMap.removeAll()
      topicLatestMessageFromSelfMap.removeAll()
    }
    guard !topics.isEmpty else {
      delegate?.onBotSubSessionListReload()
      return
    }

    let lock = NSLock()
    var nextIndex = 0
    let workerCount = min(3, topics.count)

    func loadNext() {
      lock.lock()
      guard nextIndex < topics.count else {
        lock.unlock()
        return
      }
      let topic = topics[nextIndex]
      nextIndex += 1
      lock.unlock()

      func applySummary(_ message: V2NIMMessage?) {
        guard currentVersion == summaryRequestVersion else {
          return
        }
        if updateSummary(topic: topic, message: message) {
          applyFilter()
          delegate?.onBotSubSessionListReload()
        }
        loadNext()
      }

      guard let messageRefer = messageRefer(for: topic) else {
        NEALog.errorLog(
          ModuleName + " " + className(),
          desc: #function + ", invalid root message refer, topicId: \(topic.topicId)"
        )
        applySummary(nil)
        return
      }

      chatRepo.getLocalThreadMessageList(messageRefer: messageRefer) { [weak self] result, error in
        guard let self,
              currentVersion == self.summaryRequestVersion else {
          return
        }
        if let error {
          NEALog.errorLog(
            ModuleName + " " + className(),
            desc: #function + ", topicId: \(topic.topicId), error: \(error)"
          )
          applySummary(nil)
          return
        }

        var localMessages = result?.replyList ?? []
        if let rootMessage = result?.message {
          localMessages.append(rootMessage)
        }
        applySummary(self.latestMessage(from: localMessages))
      }
    }

    for _ in 0 ..< workerCount {
      loadNext()
    }
  }

  @discardableResult
  private func updateSummary(topic: V2NIMTopic, message: V2NIMMessage?) -> Bool {
    let summary = summaryText(for: message)
    let previousSummary = topicSummaryMap[topic.topicId]
    let previousTime = topicSummaryTimeMap[topic.topicId]
    let previousFromSelf = topicLatestMessageFromSelfMap[topic.topicId]
    topicSummaryMap[topic.topicId] = summary
    if let message {
      topicSummaryTimeMap[topic.topicId] = normalizedTimestamp(message.createTime)
      topicLatestMessageFromSelfMap[topic.topicId] = message.senderId == IMKitClient.instance.account()
    } else {
      topicSummaryTimeMap.removeValue(forKey: topic.topicId)
      topicLatestMessageFromSelfMap.removeValue(forKey: topic.topicId)
    }
    let currentTime = topicSummaryTimeMap[topic.topicId]
    let currentFromSelf = topicLatestMessageFromSelfMap[topic.topicId]
    return previousSummary != summary || previousTime != currentTime || previousFromSelf != currentFromSelf
  }

  private func latestMessage(from messages: [V2NIMMessage]?) -> V2NIMMessage? {
    messages?.max { left, right in
      left.createTime < right.createTime
    }
  }

  private func messageRefer(for topic: V2NIMTopic) -> V2NIMMessageRefer? {
    guard let messageClientId = topic.messageClientId,
          !messageClientId.isEmpty,
          let messageServerId = topic.messageServerId,
          !messageServerId.isEmpty else {
      return nil
    }

    let referConversationId = topic.conversationId.flatMap { $0.isEmpty ? nil : $0 } ?? conversationId
    let conversationType = V2NIMConversationIdUtil.conversationType(referConversationId)
    guard !referConversationId.isEmpty,
          conversationType != .CONVERSATION_TYPE_UNKNOWN,
          let senderId = conversationSenderId(referConversationId),
          !senderId.isEmpty,
          let receiverId = V2NIMConversationIdUtil.conversationTargetId(referConversationId),
          !receiverId.isEmpty,
          topic.messageTime > 0 else {
      return nil
    }

    let messageRefer = V2NIMMessageRefer()
    messageRefer.messageClientId = messageClientId
    messageRefer.messageServerId = messageServerId
    messageRefer.conversationId = referConversationId
    messageRefer.conversationType = conversationType
    messageRefer.senderId = senderId
    messageRefer.receiverId = receiverId
    messageRefer.createTime = normalizedTimestamp(TimeInterval(topic.messageTime))
    return messageRefer
  }

  private func conversationSenderId(_ conversationId: String) -> String? {
    let parts = conversationId.split(separator: "|", omittingEmptySubsequences: false)
    guard parts.count == 3 else {
      return nil
    }
    return String(parts[0])
  }

  private func collectTopicIds(from messages: [V2NIMMessage]) -> Set<UInt64> {
    let topicIdsInList = currentTopicIdSet()
    let topicIds = messages.compactMap { message -> UInt64? in
      guard message.conversationId == conversationId,
            let topicRefer = message.topicRefer,
            topicIdsInList.contains(topicRefer.topicId) else {
        return nil
      }
      return topicRefer.topicId
    }
    return Set(topicIds)
  }

  private func refreshTopicsIfNeeded(_ topicIds: Set<UInt64>, refreshUnread: Bool) {
    guard !topicIds.isEmpty else {
      return
    }
    let topics = topicList.filter { topicIds.contains($0.topicId) }
    guard !topics.isEmpty else {
      return
    }
    if refreshUnread {
      refreshConversationReadTime()
    }
    loadSummaries(for: topics)
  }

  private func currentTopicIdSet() -> Set<UInt64> {
    Set(topicList.map(\.topicId))
  }

  private func sortedTopics(_ topics: [V2NIMTopic]) -> [V2NIMTopic] {
    topics.sorted { left, right in
      sortTime(for: left) > sortTime(for: right)
    }
  }

  private func sortTime(for topic: V2NIMTopic) -> TimeInterval {
    let updateTime = normalizedTimestamp(TimeInterval(topic.updateTime))
    let summaryTime = normalizedTimestamp(topicSummaryTimeMap[topic.topicId] ?? 0)
    return max(updateTime, summaryTime)
  }

  open func summaryText(for message: V2NIMMessage?) -> String {
    guard let message else {
      return ""
    }
    let text = summaryBaseText(for: message).trimmingCharacters(in: .whitespacesAndNewlines)
    if text.isEmpty {
      return ""
    }
    return String(text.prefix(maxSummaryLength))
  }

  open func topicDisplayName(_ topic: V2NIMTopic) -> String {
    topic.topicName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
  }

  private func summaryBaseText(for message: V2NIMMessage) -> String {
    ChatMessageHelper.conversationListSummary(message)
  }

  open func markTopicRead(_ topic: V2NIMTopic?) {
    refreshConversationReadTime()
  }

  open func markAllCurrentTopicsRead() {
    clearConversationUnread()
  }

  open func hasUnread(topic: V2NIMTopic) -> Bool {
    guard let latestTime = topicSummaryTimeMap[topic.topicId] else {
      return false
    }
    if topicLatestMessageFromSelfMap[topic.topicId] == true {
      return false
    }
    let normalizedReadTime = normalizedTimestamp(conversationReadTime)
    return normalizedReadTime > 0 && latestTime > normalizedReadTime
  }

  private func normalizedTimestamp(_ time: TimeInterval) -> TimeInterval {
    if time > 10_000_000_000 {
      return time / 1000.0
    }
    return time
  }

  open func clearConversationUnread() {
    if NIMSDK.shared().v2Option?.enableV2CloudConversation == false {
      localConversationRepo.clearUnreadCountByIds([conversationId]) { [weak self] _, _ in
        self?.refreshConversationReadTime()
      }
      return
    }
    conversationRepo.clearUnreadCountByIds([conversationId]) { [weak self] _, _ in
      self?.refreshConversationReadTime()
    }
  }

  open func refreshConversationReadTime() {
    if NIMSDK.shared().v2Option?.enableV2CloudConversation == false {
      localConversationRepo.getConversationReadTime(conversationId) { [weak self] time, _ in
        self?.conversationReadTime = self?.normalizedTimestamp(time ?? 0) ?? 0
        self?.delegate?.onBotSubSessionListReload()
      }
      return
    }
    conversationRepo.getConversationReadTime(conversationId) { [weak self] time, _ in
      self?.conversationReadTime = self?.normalizedTimestamp(time ?? 0) ?? 0
      self?.delegate?.onBotSubSessionListReload()
    }
  }

  open func onTotalUnreadCountChanged(_ unreadCount: Int) {}

  open func onLocalTotalUnreadCountChanged(_ unreadCount: Int) {}

  open func onConversationReadTimeUpdated(_ conversationId: String, _ readTime: TimeInterval) {
    guard conversationId == self.conversationId else {
      return
    }
    refreshUnreadStateIfCurrentConversation()
  }

  open func onLocalConversationReadTimeUpdated(_ conversationId: String, _ readTime: TimeInterval) {
    guard conversationId == self.conversationId else {
      return
    }
    refreshUnreadStateIfCurrentConversation()
  }

  open func updateTopicName(topic: V2NIMTopic,
                            topicName: String,
                            _ completion: @escaping (V2NIMTopic?, NSError?) -> Void) {
    let params = V2NIMUpdateTopicParams()
    params.topic = topic
    params.topicName = topicName
    topicRepo.updateTopic(params, completion)
  }

  open func removeTopic(topic: V2NIMTopic,
                        _ completion: @escaping (NSError?) -> Void) {
    let params = V2NIMRemoveTopicsParams()
    params.topicList = [topic]
    topicRepo.removeTopics(params, completion)
  }

  open func onTopicAdded(_ topic: V2NIMTopic) {
    guard topic.conversationId == conversationId else {
      return
    }
    topicList.removeAll { $0.topicId == topic.topicId }
    topicList.append(topic)
    topicList = sortedTopics(topicList)
    loadSummaries(for: [topic])
    applyFilter()
    delegate?.onBotSubSessionListReload()
  }

  open func onTopicsRemoved(_ topics: [V2NIMTopicRefer]) {
    let removedIds = Set(topics.filter { $0.conversationId == conversationId }.map(\.topicId))
    if removedIds.isEmpty {
      return
    }
    topicList.removeAll { removedIds.contains($0.topicId) }
    for removedId in removedIds {
      topicSummaryMap.removeValue(forKey: removedId)
      topicSummaryTimeMap.removeValue(forKey: removedId)
      topicLatestMessageFromSelfMap.removeValue(forKey: removedId)
    }
    applyFilter()
    delegate?.onBotSubSessionListReload()
  }

  open func onTopicUpdated(_ topic: V2NIMTopic) {
    guard topic.conversationId == conversationId else {
      return
    }
    if let index = topicList.firstIndex(where: { $0.topicId == topic.topicId }) {
      topicList[index] = topic
      topicList = sortedTopics(topicList)
      loadSummaries(for: [topic])
      applyFilter()
      delegate?.onBotSubSessionListReload()
    }
  }

  private func refreshUnreadStateIfCurrentConversation() {
    guard !conversationId.isEmpty else {
      return
    }
    refreshConversationReadTime()
  }
}
