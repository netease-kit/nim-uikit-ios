
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEKitCoreIM
import NIMSDK
import NEKitChat
import NEKitCommon
import NEKitCore
// import NEKitContact

public enum LoadMessageDirection: Int {
  case old = 0
  case new
}

public protocol ChatViewModelDelegate: AnyObject {
  func onRecvMessages(_ messages: [NIMMessage])
  func willSend(_ message: NIMMessage)
  func send(_ message: NIMMessage, didCompleteWithError error: Error?)
  func send(_ message: NIMMessage, progress: Float)
  func didReadedMessageIndexs()
  func onDeleteMessage(_ message: NIMMessage, atIndexs: [IndexPath])
  func onRevokeMessage(_ message: NIMMessage, atIndexs: [IndexPath])
  func onAddMessagePin(_ message: NIMMessage, atIndexs: [IndexPath])
  func onRemoveMessagePin(_ message: NIMMessage, atIndexs: [IndexPath])
  func updateDownloadProgress(_ message: NIMMessage, atIndex: IndexPath, progress: Float)
  func remoteUserEditing()
  func remoteUserEndEditing()
}

public class ChatViewModel: NSObject, ChatRepoMessageDelegate, NIMChatManagerDelegate,
  NIMConversationManagerDelegate, NIMSystemNotificationManagerDelegate, ChatExtendProviderDelegate {
  public var session: NIMSession
  public var messages: [MessageModel] = .init()
  public weak var delegate: ChatViewModelDelegate?
  // 上拉时间戳
  private var newMsg: NIMMessage?
  // 下拉时间戳
  private var oldMsg: NIMMessage?

  public var repo: ChatRepo = .init()
  public var operationModel: MessageContentModel?
  private var userInfo = [String: User]()
  public var isReplying = false
  public let messagPageNum: UInt = 100
  private let className = "ChatViewModel"
  // 可信时间戳
  public var credibleTimestamp: TimeInterval = 0
  public var anchor: NIMMessage?

  public var isHistoryChat = false

  init(session: NIMSession) {
    self.session = session
    anchor = nil
    super.init()
    repo.addChatDelegate(delegate: self)
    repo.addSessionDelegate(delegate: self)
    repo.addSystemNotificationDelegate(delegate: self)
    repo.addChatExtendDelegate(delegate: self)
  }

  init(session: NIMSession, anchor: NIMMessage?) {
    self.session = session
    self.anchor = anchor
    super.init()
    if anchor != nil {
      isHistoryChat = true
    }
    repo.addChatDelegate(delegate: self)
    repo.addSessionDelegate(delegate: self)
    repo.addSystemNotificationDelegate(delegate: self)
    repo.addChatExtendDelegate(delegate: self)
  }

  public func sendTextMessage(text: String, _ completion: @escaping (Error?) -> Void) {
    if text.count <= 0 {
      return
    }
    repo.sendMessage(
      message: MessageUtils.textMessage(text: text),
      session: session,
      completion
    )
  }

  public func sendAudioMessage(filePath: String, _ completion: @escaping (Error?) -> Void) {
    repo.sendMessage(
      message: MessageUtils.audioMessage(filePath: filePath),
      session: session,
      completion
    )
  }

  public func sendImageMessage(image: UIImage, _ completion: @escaping (Error?) -> Void) {
    // TODO:
    repo.sendMessage(
      message: MessageUtils.imageMessage(image: image),
      session: session,
      completion
    )
  }

  public func sendVideoMessage(url: URL, _ completion: @escaping (Error?) -> Void) {
    weak var weakSelf = self
    VideoFormatConvert
      .convertToMP4(with: url, avQuality: AVAssetExportPresetHighestQuality) { path, image in
        if let p = path, let s = weakSelf?.session {
          weakSelf?.repo.sendMessage(
            message: MessageUtils.videoMessage(filePath: p),
            session: s,
            completion
          )
        } else {
          NELog.errorLog("chat veiw model", desc: "convert mov to mp4 failed")
        }
      }
  }

  public func queryRoamMsgHasMoreTime(_ completion: @escaping (Error?, NSInteger,
                                                               [MessageModel]?) -> Void) {
//        NIMIncompleteSessionInfo
    weak var weakSelf = self
    repo.getIncompleteSessionInfo(session: session) { error, sessionInfos in
      if error == nil {
        let sessionInfo = sessionInfos?.first
        // 记录可信时间戳
        weakSelf?.credibleTimestamp = sessionInfo?.timestamp ?? 0
        if weakSelf?.anchor == nil {
          weakSelf?.getMessageHistory(self.oldMsg, completion)

        } else {
          // 有锚点消息，从两个方向拉去消息
          weakSelf?.newMsg = weakSelf?.anchor
          weakSelf?.oldMsg = weakSelf?.anchor
          weakSelf?.dropDownRemoteRefresh(completion)
          weakSelf?.pullRemoteRefresh(completion)
        }
      }
    }
  }

  public func queryRoamMsgHasMoreTime_v2(_ completion: @escaping (Error?, NSInteger, NSInteger,
                                                                  [MessageModel]?, Int) -> Void) {
    weak var weakSelf = self
    repo.getIncompleteSessionInfo(session: session) { error, sessionInfos in
      if error == nil {
        let sessionInfo = sessionInfos?.first
        // 记录可信时间戳
        weakSelf?.credibleTimestamp = sessionInfo?.timestamp ?? 0
        if weakSelf?.anchor == nil {
          weakSelf?.getMessageHistory(self.newMsg) { error, value, models in
            completion(error, value, 0, models, 0)
          }
        } else {
          // 有锚点消息，从两个方向拉去消息
          weakSelf?.newMsg = weakSelf?.anchor
          weakSelf?.oldMsg = weakSelf?.anchor

          let group = DispatchGroup()

          var moreEnd = 0
          var newEnd = 0
          var historyDatas = [MessageModel]()
          var newDatas = [MessageModel]()

          var err: Error?

          group.enter()
          weakSelf?.dropDownRemoteRefresh { error, value, models in

            moreEnd = value
            if error != nil {
              err = error
            }
            if let ms = models {
              historyDatas.append(contentsOf: ms)
            }
            print("drop down remote refresh : ", historyDatas.count)
            group.leave()
          }

          group.enter()
          weakSelf?.pullRemoteRefresh { error, value, models in
            newEnd = value
            if err != nil {
              err = error
            }
            if let ms = models {
              newDatas.append(contentsOf: ms)
            }
            print("pull remote refresh : ", newDatas.count)
            group.leave()
          }

          group.notify(queue: DispatchQueue.main, execute: {
            var finalDatas = [MessageModel]()
            finalDatas.append(contentsOf: historyDatas)
            if let anchorMessage = weakSelf?.anchor {
              let model = self.modelFromMessage(message: anchorMessage)
              weakSelf?.messages.insert(model, at: historyDatas.count)
              finalDatas.append(model)
            }
            finalDatas.append(contentsOf: newDatas)
            completion(err, moreEnd, newEnd, finalDatas, historyDatas.count)
          })
        }
      }
    }
  }

  // 查询本地历史消息
  public func getMessageHistory(_ message: NIMMessage?,
                                _ completion: @escaping (Error?, NSInteger, [MessageModel]?)
                                  -> Void) {
    ChatProvider.shared.getMessageHistory(
      session: session,
      message: message,
      limit: messagPageNum
    ) { [weak self] error, messages in
      if let messageArray = messages, messageArray.count > 0 {
        self?.oldMsg = messageArray.first
        for msg in messageArray {
          self?.addTimeMessage(msg)
          if let model = self?.modelFromMessage(message: msg) {
            self?.messages.append(model)
          }
        }
        completion(error, messageArray.count, self?.messages)
//                mark read
        self?.markRead(messages: messageArray) { error in
          print("mark read \(error?.localizedDescription)")
        }

      } else {
        completion(error, 0, self?.messages)
      }
    }
  }

  // 查询更多本地历史消息
  public func getMoreMessageHistory(_ completion: @escaping (Error?, NSInteger, [MessageModel]?)
    -> Void) {
    weak var weakSelf = self

    let messageParam = oldMsg ?? newMsg

    ChatProvider.shared.getMessageHistory(
      session: session,
      message: messageParam,
      limit: messagPageNum
    ) { [weak self] error, messages in
      if let messageArray = messages, messageArray.count > 0 {
        weakSelf?.oldMsg = messageArray.first

        // 如果可信就使用本次请求数据，如果不可信就去远端拉去数据，并更新可信时间戳
        let isCredible = weakSelf?
          .isMessageCredible(message: messageArray.first ?? NIMMessage())
        if let isTrust = isCredible, isTrust {
          for msg in messageArray.reversed() {
            self?.addTimeForHistoryMessage(msg)
            if let model = self?.modelFromMessage(message: msg) {
              self?.messages.insert(model, at: 0)
            }
          }
          completion(error, messageArray.count, self?.messages)
        } else {
          let option = NIMHistoryMessageSearchOption()
          option.startTime = 0
          option.endTime = self?.oldMsg?.timestamp ?? 0
          option.limit = self?.messagPageNum ?? 100
          option.sync = true
          weakSelf?.getRemoteHistoryMessage(
            direction: .old,
            updateCredible: true,
            option: option,
            completion
          )
        }

        weakSelf?.markRead(messages: messageArray) { error in
          print("mark read \(error?.localizedDescription)")
        }

      } else {
        if let messageArray = messages, messageArray.isEmpty,
           weakSelf?.credibleTimestamp ?? 0 > 0 {
          // 如果远端拉倒了信息 就去更新可信时间戳，拉不到就不更新。
          let option = NIMHistoryMessageSearchOption()
          option.startTime = 0
          option.endTime = self?.oldMsg?.timestamp ?? 0
          option.limit = self?.messagPageNum ?? 100
          weakSelf?.getRemoteHistoryMessage(
            direction: .old,
            updateCredible: true,
            option: option,
            completion
          )
        } else {
          completion(error, 0, self?.messages)
        }
      }
    }
  }

  // 查询远端历史消息
  public func getRemoteHistoryMessage(direction: LoadMessageDirection, updateCredible: Bool,
                                      option: NIMHistoryMessageSearchOption,
                                      _ completion: @escaping (Error?, NSInteger,
                                                               [MessageModel]?) -> Void) {
    weak var weakSelf = self
    repo.getHistoryMessage(session: session, option: option) { error, messages in
      if error == nil {
        if let messageArray = messages, messageArray.count > 0 {
          if direction == .old {
            weakSelf?.oldMsg = messageArray.last
          } else {
            weakSelf?.newMsg = messageArray.first
          }
          for msg in messageArray {
            weakSelf?.addTimeForHistoryMessage(msg)
            if let model = weakSelf?.modelFromMessage(message: msg) {
              weakSelf?.messages.insert(model, at: 0)
            }
          }

          if let updateMessage = messageArray.first, updateCredible {
            // 更新可信时间戳
            weakSelf?.credibleTimestamp = updateMessage.timestamp
            weakSelf?.repo
              .updateIncompleteSessions(messages: [updateMessage]) { error, recentSessions in
                if error != nil {
                  NELog.errorLog(
                    weakSelf?.className ?? "ChatViewModel",
                    desc: "❌updateIncompleteSessions failed，error = \(error!)"
                  )
                }
              }
          }
          completion(error, messageArray.count, weakSelf?.messages)

        } else {
          completion(error, 0, weakSelf?.messages)
        }

      } else {
        completion(error, 0, nil)
      }
    }
  }

  // 下拉获取历史消息
  public func dropDownRemoteRefresh(_ completion: @escaping (Error?, NSInteger, [MessageModel]?)
    -> Void) {
    // completion(nil, true, nil)
    let option = NIMHistoryMessageSearchOption()
    option.startTime = 0
    option.endTime = oldMsg?.timestamp ?? 0
    option.limit = messagPageNum
    option.sync = true
    let isCredible = isMessageCredible(message: oldMsg ?? NIMMessage())
    if isCredible { // 继续拉去本地消息
      getMoreMessageHistory(completion)
    } else {
      // 不可信拉去远端消息
      getRemoteHistoryMessage(
        direction: .old,
        updateCredible: false,
        option: option,
        completion
      )
    }
  }

  // 上拉获取最新消息
  public func pullRemoteRefresh(_ completion: @escaping (Error?, NSInteger, [MessageModel]?)
    -> Void) {
    let option = NIMHistoryMessageSearchOption()
    option.startTime = newMsg?.timestamp ?? 0
    option.endTime = 0
    option.limit = messagPageNum
    let isCredible = isMessageCredible(message: newMsg ?? NIMMessage())
    if isCredible {
      if anchor != nil {
        // 搜索历史记录进入
        searchMessageHistory(
          direction: .new,
          startTime: newMsg?.timestamp ?? 0,
          endTime: 0,
          completion
        )
      }

    } else {
      getRemoteHistoryMessage(
        direction: .new,
        updateCredible: false,
        option: option,
        completion
      )
    }
  }

  // 搜索历史记录查询的本地消息
  public func searchMessageHistory(direction: LoadMessageDirection, startTime: TimeInterval,
                                   endTime: TimeInterval,
                                   _ completion: @escaping (Error?, NSInteger, [MessageModel]?)
                                     -> Void) {
    let option = NIMMessageSearchOption()
    option.startTime = startTime
    option.endTime = endTime
    option.order = .asc
    option.limit = messagPageNum
    weak var weakSelf = self

    repo.searchMessages(session, option: option) { error, messages in
      if error == nil {
        if let messageArray = messages, messageArray.count > 0 {
          if direction == .old {
            weakSelf?.oldMsg = messageArray.first
          } else {
            weakSelf?.newMsg = messageArray.last
          }
          for msg in messageArray {
            weakSelf?.addTimeMessage(msg)
            if let model = weakSelf?.modelFromMessage(message: msg) {
              weakSelf?.messages.append(model)
            }
          }
          completion(error, messageArray.count, weakSelf?.messages)
        } else {
          completion(error, 0, weakSelf?.messages)
        }
      } else {
        completion(error, 0, nil)
      }
    }
  }

  // 判断消息是否可信
  public func isMessageCredible(message: NIMMessage) -> Bool {
    credibleTimestamp <= 0 || message.timestamp >= credibleTimestamp
  }

  public func markRead(messages: [NIMMessage], _ completion: @escaping (Error?) -> Void) {
//        if self.getMessageRead() {
//            if self.session.sessionType == .P2P {
//                self.markReadInP2P(messages: messages, completion)
//            }else if self.session.sessionType == .team {
//                self.markReadInTeam(messages: messages, completion)
//            }
//        }
    if session.sessionType == .P2P {
      markReadInP2P(messages: messages, completion)
    } else if session.sessionType == .team {
      markReadInTeam(messages: messages, completion)
    }
//        mark session read
    weak var weakself = self
    repo.markReadInSession(session) { error in
      if error != nil {
        NELog.errorLog(
          weakself?.className() ?? "ChatViewModel",
          desc: "❌markReadInSession failed,error = \(error!)"
        )
      }
    }
  }

  private func markReadInP2P(messages: [NIMMessage], _ completion: @escaping (Error?) -> Void) {
    for message in messages.reversed() {
      if message.isReceivedMsg {
        let param = NIMMessageReceipt(message: message)
        repo.markP2pMessageRead(param: param, completion)
        break
      }
    }
    completion(nil)
  }

  private func markReadInTeam(messages: [NIMMessage], _ completion: @escaping (Error?) -> Void) {
    var receipts = [NIMMessageReceipt]()
    for message in messages {
      let receiptEnable = message.setting?.teamReceiptEnabled ?? false
      if receiptEnable, !message.isTeamReceiptSended {
        let receipt = NIMMessageReceipt(message: message)
        receipts.append(receipt)
      }
    }
    repo.markTeamMessageRead(param: receipts) { error, failedReceipts in
      print("!! chatViewModel markReadInTeam error:\(error)")
      completion(error)
    }
  }

  public func deleteMessage(message: NIMMessage) {
    repo.deleteMessage(message: message)
    deleteMessageUpdateUI(message)
  }

  public func replyMessage(_ message: NIMMessage, _ target: NIMMessage,
                           _ completion: @escaping (Error?) -> Void) {
    repo.replyMessage(message, target) { error in
      completion(error)
    }
  }

  public func revokeMessage(message: NIMMessage, _ completion: @escaping (Error?) -> Void) {
    repo.revokeMessage(message: message) { error in
      if error == nil {
        self.revokeMessageUpdateUI(message)
      }
      completion(error)
    }
  }

  public func resendMessage(message: NIMMessage) -> NSError? {
    repo.resendMessage(message: message)
  }

  public func getUserInfo(userId: String) -> User? {
    repo.getUserInfo(userId: userId)
  }

  public func getTeamMember(userId: String, teamId: String) -> NIMTeamMember? {
    repo.getTeamMemberList(userId: userId, teamId: teamId)
  }

  public func onReceive(_ notification: NIMCustomSystemNotification) {
    print("on receive custom noti : ", notification)
    if session.sessionType != .P2P {
      return
    }
    if session.sessionId != notification.sender {
      return
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

  //    MARK: NIMChatManagerDelegate

  // 收到消息
  public func onRecvMessages(_ messages: [NIMMessage]) {
    print("\(#function) 1messages:\(messages.count)")

    for msg in messages {
      if msg.session?.sessionId == session.sessionId {
        // 自定义消息处理
        if msg.messageType == .custom {
        } else {
          newMsg = msg
          addTimeMessage(msg)
          self.messages.append(modelFromMessage(message: msg))
        }
      }
    }
    delegate?.onRecvMessages(messages)
  }

  public func willSend(_ message: NIMMessage) {
    print("\(#function)")
    if message.session?.sessionId != session.sessionId {
      return
    }
    // 自定义消息发送之前的处理
    if message.messageType == .custom {
    } else {
      if newMsg == nil {
        newMsg = message
      }

      var isResend = false
      for (i, msg) in messages.enumerated() {
        if message.messageId == msg.message?.messageId {
          messages[i].message = message
          isResend = true
          break
        }
      }

      if !isResend {
        addTimeMessage(message)
        messages.append(modelFromMessage(message: message))
      }

      delegate?.willSend(message)
    }
  }

  public func send(_ message: NIMMessage, progress: Float) {
    print("\(#function)  progress\(progress)")
    delegate?.send(message, progress: progress)
  }

  public func send(_ message: NIMMessage, didCompleteWithError error: Error?) {
    print("\(#function) message deliveryState:\(message.deliveryState) error:\(error)")
    for (i, msg) in messages.enumerated() {
      if message.messageId == msg.message?.messageId {
        messages[i].message = message
        break
      }
    }
    delegate?.send(message, didCompleteWithError: error)
  }

//    MARK: ChatExtendProviderDelegate

  public func onNotifyAddMessagePin(pinItem: NIMMessagePinItem) {
    var index = -1
    for (i, model) in messages.enumerated() {
      if pinItem.messageServerID == model.message?.serverID {
        messages[i].isPined = true
        let pinID = pinItem.accountID ?? NIMSDK.shared().loginManager.currentAccount()
        messages[i].pinAccount = pinID
        messages[i].pinShowName = getShowName(userId: pinID, teamId: session.sessionId)
        index = i
        break
      }
    }
    if index >= 0, let msg = messages[index].message {
      delegate?.onAddMessagePin(msg, atIndexs: [IndexPath(row: index, section: 0)])
    }
  }

  public func onNotifyRemoveMessagePin(pinItem: NIMMessagePinItem) {
    var index = -1
    for (i, model) in messages.enumerated() {
      if pinItem.messageServerID == model.message?.serverID {
        messages[i].isPined = false
        messages[i].pinAccount = nil
        messages[i].pinShowName = nil
        index = i
        break
      }
    }
    if index >= 0, let msg = messages[index].message {
      delegate?.onRemoveMessagePin(msg, atIndexs: [IndexPath(row: index, section: 0)])
    }
  }

  public func onNotifySyncStickTopSessions(_ response: NIMSyncStickTopSessionResponse) {}

  public func onNotifyAddStickTopSession(_ newInfo: NIMStickTopSessionInfo) {}

  public func onNotifyRemoveStickTopSession(_ removedInfo: NIMStickTopSessionInfo) {}

//    MARK: collection

  func addColletion(_ message: NIMMessage,
                    completion: @escaping (NSError?, NIMCollectInfo?) -> Void) {
    let param = NIMAddCollectParams()
    var string: String?
    if message.messageType == .text {
      string = message.text
      param.type = 1024
    } else {
      switch message.messageType {
      case .audio:
        if let obj = message.messageObject as? NIMAudioObject {
          string = obj.url
        }
        param.type = message.messageType.rawValue
      case .image:
        if let obj = message.messageObject as? NIMImageObject {
          string = obj.url
        }
        param.type = message.messageType.rawValue
      case .video:
        if let obj = message.messageObject as? NIMVideoObject {
          string = obj.url
        }
        param.type = message.messageType.rawValue
      default:
        param.type = 0
      }
      param.data = string ?? ""
    }
    param.uniqueId = message.serverID
    repo.collectMessage(param, completion)
  }

//    MARK: revoke

  public func onRecvRevokeMessageNotification(_ notification: NIMRevokeMessageNotification) {
    guard let msg = notification.message else {
      return
    }
    revokeMessageUpdateUI(msg)
  }

  public func onRecvMessageReceipts(_ receipts: [NIMMessageReceipt]) {
    print(
      "chatViewModel: receipts:\(receipts.count) messageId:\(receipts.first?.messageId) messageId:\(receipts.first?.timestamp)"
    )
    delegate?.didReadedMessageIndexs()
  }

  public func avalibleOperationsForMessage(_ model: MessageContentModel?) -> [OperationItem]? {
    var pinItem = OperationItem.pinItem()
    var items = [OperationItem]()
    switch model?.message?.messageType {
    case .text:
      if let isPin = model?.isPined, isPin {
        pinItem = OperationItem.removePinItem()
      }
      items = [
        OperationItem.copyItem(),
        OperationItem.replayItem(),
        OperationItem.forwardItem(),
        pinItem,
//        OperationItem.selectItem(),
//        OperationItem.collectionItem(),
        OperationItem.deleteItem(),
      ]

    case .image, .video:
      if let isPin = model?.isPined, isPin {
        pinItem = OperationItem.removePinItem()
      }
      items = [
        OperationItem.replayItem(),
        OperationItem.forwardItem(),
        pinItem,
//        OperationItem.selectItem(),
//        OperationItem.collectionItem(),
        OperationItem.deleteItem(),
      ]
    case .audio:
      if let isPin = model?.isPined, isPin {
        pinItem = OperationItem.removePinItem()
      }
      items = [
        OperationItem.replayItem(),
        pinItem,
//        OperationItem.selectItem(),
//        OperationItem.collectionItem(),
        OperationItem.deleteItem(),
      ]

    default:
      if let isPin = model?.isPined, isPin {
        pinItem = OperationItem.removePinItem()
      }
      items = [
        OperationItem.replayItem(),
        pinItem,
//        OperationItem.selectItem(),
//        OperationItem.collectionItem(),
        OperationItem.deleteItem(),
      ]
    }

    if model?.message?.from == NIMSDK.shared().loginManager.currentAccount() {
      items.append(OperationItem.recallItem())
    }
    return items
  }

  private func indexPathsForTeamMarkRead(_ receipts: [NIMMessageReceipt]) -> [IndexPath] {
    var indexs = [IndexPath]()
//      find messages that need to update UI
    for receipt in receipts {
      for (i, model) in messages.enumerated() {
        if model.message?.messageId == receipt.messageId {
          indexs.append(IndexPath(row: i, section: 0))
        }
      }
    }
    print("mark read indexs:\(indexs)")
    return indexs
  }

  private func indexPathsForP2PMarkRead(_ receipts: [NIMMessageReceipt]) -> [IndexPath] {
    var updateIndexs = [IndexPath]()
//      find messages that need to update UI
    var i = messages.count - 1
    for model in messages.reversed() {
      if let msg = model.message, msg.isRemoteRead {
        updateIndexs.append(IndexPath(row: i, section: 0))
        break
      } else {
        updateIndexs.append(IndexPath(row: i, section: 0))
        i = i - 1
      }
    }
    return updateIndexs
  }

  // history message insert message at first of messages, send message add last of messages
  private func addTimeMessage(_ message: NIMMessage) {
    let lastTs = messages.last?.message?.timestamp ?? 0.0
    let curTs = message.timestamp
    let dur = curTs - lastTs
    if (dur / 60) > 5 {
      messages.append(timeModel(message))
    }
  }

  private func addTimeForHistoryMessage(_ message: NIMMessage) {
    let firstTs = messages.first?.message?.timestamp ?? 0.0
    let curTs = message.timestamp
    let dur = firstTs - curTs
    if (dur / 60) > 5 {
      let model = MessageTipsModel(message: message)
      model.type = .time
      model.text = String.stringFromDate(date: Date(timeIntervalSince1970: firstTs))
      messages.insert(model, at: 0)
    }
  }

  private func timeModel(_ message: NIMMessage) -> MessageModel {
    let curTs = message.timestamp
    let model = MessageTipsModel(message: message)
    model.type = .time
    model.text = String.stringFromDate(date: Date(timeIntervalSince1970: curTs))
    return model
  }

  private func tipsModel(_ message: NIMMessage) -> MessageModel {
    let model = MessageTipsModel(message: message)
    return model
  }

  private func modelFromMessage(message: NIMMessage) -> MessageModel {
    var model: MessageModel
    switch message.messageType {
    case .video:
      model = MessageVideoModel(message: message)
    case .text:
      model = MessageTextModel(message: message)
    case .image:
      model = MessageImageModel(message: message)
    case .audio:
      model = MessageAudioModel(message: message)
//                    case .video:
//                        <#code#>
//                    case .location:
//                        <#code#>
    case .notification:
      model = MessageTipsModel(message: message)
//                    case .file:
//                        <#code#>
    case .tip:
      model = MessageTipsModel(message: message)
//                    case .robot:
//                        <#code#>
//                    case .rtcCallRecord:
//                        <#code#>
//                    case .custom:
//                        <#code#>
    default:
      model = MessageContentModel(message: message)
    }
    if let uid = message.from {
      let user = getUserInfo(userId: uid)
      var fullName = uid
      if let nickName = user?.userInfo?.nickName {
        fullName = nickName
      }
      model.avatar = user?.userInfo?.thumbAvatarUrl
      if session.sessionType == .team {
        // team
        let teamMember = getTeamMember(userId: uid, teamId: session.sessionId)
        if let teamNickname = teamMember?.nickname {
          fullName = teamNickname
        }
      }
      if let alias = user?.alias {
        fullName = alias
      }
      model.fullName = fullName
      model.shortName = fullName
        .count > 2 ? String(fullName[fullName.index(fullName.endIndex, offsetBy: -2)...]) :
        fullName
    }
    model.replyedModel = getReplyMessage(message: message)
    if let pin = repo.searchMessagePinHistory(message) {
      model.isPined = true
      model.pinAccount = pin.accountID
      let pinID = pin.accountID ?? NIMSDK.shared().loginManager.currentAccount()
      model.pinShowName = getShowName(userId: pinID, teamId: session.sessionId)
    } else {
      model.isPined = false
    }
    return model
  }

  private func getReplyMessage(message: NIMMessage) -> MessageModel? {
    guard let id = message.repliedMessageId else {
      return nil
    }
    if let message = ConversationProvider.shared.messagesInSession(session, messageIds: [id])?
      .first {
      return modelFromMessage(message: message)
    }
    return nil
  }

  private func getUserInfo(_ userId: String, _ completion: @escaping (User?, NSError?) -> Void) {
    if let user = userInfo[userId] {
      completion(user, nil)
    }
    if let user = repo.getUserInfo(userId: userId) {
      userInfo[userId] = user
      completion(user, nil)
    }

    UserInfoProvider.shared.fetchUserInfo([userId]) { [weak self] error, users in
      if let user = users?.first {
        self?.userInfo[userId] = user
        completion(user, nil)
      } else {
        completion(nil, error)
      }
    }
  }

//    获取展示的用户名字，p2p： 备注》昵称>ID  team: 备注〉群昵称》 昵称〉 ID
  private func getShowName(userId: String, teamId: String?) -> String {
    let user = getUserInfo(userId: userId)
    var fullName = userId
    if let nickName = user?.userInfo?.nickName {
      fullName = nickName
    }
//        model.avatar = user?.userInfo?.thumbAvatarUrl
    if let tID = teamId, session.sessionType == .team {
      // team
      let teamMember = getTeamMember(userId: userId, teamId: tID)
      if let teamNickname = teamMember?.nickname {
        fullName = teamNickname
      }
    }
    if let alias = user?.alias {
      fullName = alias
    }
    return fullName
  }

//    全名后几位
  private func getShortName(name: String, length: Int) -> String {
    name.count > length ? String(name[name.index(name.endIndex, offsetBy: -length)...]) : name
  }

  func deleteMessageUpdateUI(_ message: NIMMessage) {
    var index = -1
    for (i, model) in messages.enumerated() {
      if model.message?.serverID == message.serverID {
        index = i
        break
      }
    }
    var indexs = [IndexPath]()
    if index >= 0 {
//            remove time tip
      let last = index - 1
      if last >= 0, let timeModel = messages[last] as? MessageTipsModel,
         timeModel.type == .time {
        messages.removeSubrange(last ... index)
        indexs.append(IndexPath(row: last, section: 0))
        indexs.append(IndexPath(row: index, section: 0))
      } else {
        messages.remove(at: index)
        indexs.append(IndexPath(row: index, section: 0))
      }
    }
    delegate?.onDeleteMessage(message, atIndexs: indexs)
  }

  func revokeMessageUpdateUI(_ message: NIMMessage) {
    var index = -1
    for (i, model) in messages.enumerated() {
      if model.message?.serverID == message.serverID {
        index = i
        break
      }
    }
    var indexs = [IndexPath]()
    if index >= 0 {
      messages[index].isRevoked = true
      messages[index].replyedModel = nil
      indexs.append(IndexPath(row: index, section: 0))
    }
    delegate?.onRevokeMessage(message, atIndexs: indexs)
  }

  public func fetchMessageAttachment(_ message: NIMMessage, didCompleteWithError error: Error?) {
    print("featch message completion : ", error as Any)
  }

  public func fetchMessageAttachment(_ message: NIMMessage, progress: Float) {
    print("fetchMessageAttachment progress : ", progress)
    /*
     var index = -1
     for (i, model) in self.messages.enumerated() {
         if model.message?.serverID == message.serverID {
             index = i
             break
         }
     }
     if index >= 0 {
         let indexPath = IndexPath(row: index, section: 0)
         delegate?.updateDownloadProgress(message, atIndex: indexPath, progress: progress)
     } */
  }

  public func fetchMessageAttachment(_ message: NIMMessage,
                                     _ completion: @escaping (Error?) -> Void) {
    repo.downloadMessageAttachment(message, completion)
  }

  public func downLoad(_ urlString: String, _ filePath: String, _ progress: NIMHttpProgressBlock?,
                       _ completion: NIMDownloadCompleteBlock?) {
    repo.downLoadSource(urlString, filePath, progress, completion)
  }

  public func getUrls() -> [String] {
    var urls = [String]()
    messages.forEach { model in
      if model.type == .image, let message = model.message?.messageObject as? NIMImageObject {
        if let url = message.url {
          urls.append(url)
        } else {
          if let path = message.path, FileManager.default.fileExists(atPath: path) {
            urls.append(path)
          }
        }
      }
    }
    print("urls:\(urls)")
    return urls
  }

  public func forwardUserMessage(_ message: NIMMessage, _ users: [NIMUser]) {
    weak var weakSelf = self
    users.forEach { user in
      if let uid = user.userId {
        let session = NIMSession(uid, type: .P2P)
        weakSelf?.repo.makeForwardMessage(message, session)
      }
    }
  }

  public func forwardTeamMessage(_ message: NIMMessage, _ team: NIMTeam) {
    if let tid = team.teamId {
      let session = NIMSession(tid, type: .team)
      repo.makeForwardMessage(message, session)
    }
  }

  public func pinMessage(_ message: NIMMessage,
                         _ completion: @escaping (Error?, NIMMessagePinItem?, Int) -> Void) {
    let item = NIMMessagePinItem(message: message)
    repo.addMessagePin(item) { [weak self] error, pinItem in
      var index = -1
      if var messages = self?.messages {
        for (i, model) in messages.enumerated() {
          if message.messageId == model.message?.messageId {
            messages[i].isPined = true
            messages[i].pinAccount = NIMSDK.shared().loginManager.currentAccount()
            messages[i].pinShowName = self?.getShowName(
              userId: NIMSDK.shared().loginManager.currentAccount(),
              teamId: message.session?.sessionId
            )
            self?.messages = messages
            index = i
            break
          }
        }
      }
      completion(error, pinItem, index)
    }
  }

  public func removePinMessage(_ message: NIMMessage,
                               _ completion: @escaping (Error?, NIMMessagePinItem?, Int)
                                 -> Void) {
    let item = NIMMessagePinItem(message: message)
    repo.removePin(item) { [weak self] error, pinItem in
      var index = -1
      if var messages = self?.messages {
        for (i, model) in messages.enumerated() {
          if message.messageId == model.message?.messageId {
            messages[i].isPined = false
            messages[i].pinAccount = nil
            self?.messages = messages
            index = i
            break
          }
        }
      }
      completion(error, pinItem, index)
    }
  }

  public func sendInputTypingState() {
    if session.sessionType == .P2P {
      setTypingCustom(1)
    }
  }

  public func sendInputTypingEndState() {
    if session.sessionType == .P2P {
      setTypingCustom(0)
    }
  }

  func setTypingCustom(_ typing: Int) {
    let message = NIMMessage()
    if message.setting == nil {
      message.setting = NIMMessageSetting()
    }
    message.setting?.apnsEnabled = false
    message.setting?.shouldBeCounted = false
    let noti =
      NIMCustomSystemNotification(content: getJSONStringFromDictionary(["typing": typing]))

    repo.sendCustomNotification(noti, session) { error in
      if let err = error {
        print("send noti success :", err)
      }
    }
  }

  public func getHandSetEnable() -> Bool {
    repo.getEarState()
  }

  public func getMessageRead() -> Bool {
    repo.getMessageRead()
  }

//    MARK: NIMConversationManagerDelegate

//    remote
//    public func onRecvMessagesDeleted(_ messages: [NIMMessage], exts: [String : String]?) {
//        if let message = messages.first {
//            var index = -1
//            for (i, model) in self.messages.enumerated() {
//                if model.message?.serverID == message.serverID {
//                    index = i
//                    break
//                }
//            }
//            if index > 0 {
//                self.messages.remove(at: index)
//            }
//            self.delegate?.onDeleteMessage(message)
//        }
//        print("onRecvMessagesDeleted: \(messages.first) exts:\(exts)")
//    }
//
//    public func onRecvMessageDeleted(_ message: NIMMessage, ext: String?) {
//        print("onRecvMessagesDeleted: \(message) exts:\(ext)")
//    }
  deinit {
    print("deinit")
  }
}
