// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECommonKit
import NECoreIMKit
import NECoreKit
import NIMSDK
// import NEKitContact

@objc
public enum LoadMessageDirection: Int {
  case old = 1
  case new
}

@objc
public protocol ChatViewModelDelegate: NSObjectProtocol {
  func onRecvMessages(_ messages: [NIMMessage])
  func willSend(_ message: NIMMessage)
  func send(_ message: NIMMessage, didCompleteWithError error: Error?)
  func send(_ message: NIMMessage, progress: Float)
  func didReadedMessageIndexs()
  func onDeleteMessage(_ message: NIMMessage, atIndexs: [IndexPath], reloadIndex: [IndexPath])
  func onRevokeMessage(_ message: NIMMessage, atIndexs: [IndexPath])
  func onAddMessagePin(_ message: NIMMessage, atIndexs: [IndexPath])
  func onRemoveMessagePin(_ message: NIMMessage, atIndexs: [IndexPath])
  func updateDownloadProgress(_ message: NIMMessage, atIndex: IndexPath, progress: Float)
  func remoteUserEditing()
  func remoteUserEndEditing()
  func didLeaveTeam()
  func didDismissTeam()
  func didRefreshTable()

  @objc optional
  func getMessageModel(model: MessageModel)
}

let revokeLocalMessage = "revoke_message_local"
let revokeLocalMessageContent = "revoke_message_local_content"
let removePinMessageNoti = "remove_pin_message_noti"

@objcMembers
public class ChatViewModel: NSObject, ChatRepoMessageDelegate, NIMChatManagerDelegate,
  NIMConversationManagerDelegate, NIMSystemNotificationManagerDelegate, ChatExtendProviderDelegate, FriendProviderDelegate {
  public var team: NIMTeam?
  public var session: NIMSession
  public var messages = [MessageModel]()
  public weak var delegate: ChatViewModelDelegate?
  public var newUserInfoDic = [String: User]()
  // 上拉时间戳
  private var newMsg: NIMMessage?
  // 下拉时间戳
  private var oldMsg: NIMMessage?

  public var repo = ChatRepo.shared
  public var operationModel: MessageContentModel?
  private var userInfo = [String: User]()
  public var isReplying = false
  public let messagPageNum: UInt = 100
  private let className = "ChatViewModel"
  // 可信时间戳
  public var credibleTimestamp: TimeInterval = 0
  public var anchor: NIMMessage?

  public var isHistoryChat = false

  public var filterInviteSet = Set<String>()

  public var deletingMsgDic = Set<String>()

  init(session: NIMSession) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", sessionId:" + session.sessionId)
    self.session = session
    anchor = nil
    super.init()
    repo.addChatDelegate(delegate: self)
    repo.addContactDelegate(delegate: self)
    repo.addSessionDelegate(delegate: self)
    repo.addSystemNotificationDelegate(delegate: self)
    repo.addChatExtendDelegate(delegate: self)
    addObserver()
  }

  init(session: NIMSession, anchor: NIMMessage?) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", sessionId:" + session.sessionId)
    self.session = session
    self.anchor = anchor
    super.init()
    if anchor != nil {
      isHistoryChat = true
    }
    repo.addChatDelegate(delegate: self)
    repo.addContactDelegate(delegate: self)
    repo.addSessionDelegate(delegate: self)
    repo.addSystemNotificationDelegate(delegate: self)
    repo.addChatExtendDelegate(delegate: self)
    addObserver()
  }

  func addObserver() {
    NotificationCenter.default.addObserver(self, selector: #selector(updateFriendInfo), name: NotificationName.updateFriendInfo, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(removePinNoti), name: Notification.Name(removePinMessageNoti), object: nil)
  }

  func removePinNoti(_ noti: Notification) {
    if let message = noti.object as? NIMMessage {
      removeLocalPinMessage(message)
      delegate?.didRefreshTable()
    }
  }

  public func sendTextMessage(text: String, remoteExt: [String: Any]?, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", text.count: \(text.count)")
    if text.count <= 0 {
      return
    }
    repo.sendMessage(
      message: MessageUtils.textMessage(text: text, remoteExt: remoteExt),
      session: session,
      completion
    )
  }

  func updateFriendInfo(notification: Notification) {
    if let user = notification.object as? User,
       let uid = user.userId {
      newUserInfoDic[uid] = user
    }
  }

  public func sendTextMessage(text: String, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", text.count: \(text.count)")
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
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", filePath:" + filePath)
    repo.sendMessage(
      message: MessageUtils.audioMessage(filePath: filePath),
      session: session,
      completion
    )
  }

  public func sendImageMessage(image: UIImage, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", image.size: \(image.size)")
    // TODO:
    repo.sendMessage(
      message: MessageUtils.imageMessage(image: image),
      session: session,
      completion
    )
  }

  public func sendVideoMessage(url: URL, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", url.path:" + url.path)
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

  public func sendLocationMessage(_ model: ChatLocaitonModel, _ completion: @escaping (Error?) -> Void) {
    let message = MessageUtils.locationMessage(model.lat, model.lng, model.title, model.address)
    repo.sendMessage(message: message, session: session, completion)
  }

  public func sendFileMessage(filePath: String, displayName: String?, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", filePath:")
    repo.sendMessage(
      message: MessageUtils.fileMessage(filePath: filePath, displayName: displayName),
      session: session,
      completion
    )
  }

  public func sendFileMessage(data: Data, displayName: String?, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", filePath:")
    repo.sendMessage(
      message: MessageUtils.fileMessage(data: data, displayName: displayName),
      session: session,
      completion
    )
  }

  // 动态查询历史消息解决方案
  public func getMessagesModelDynamically(_ order: NIMMessageSearchOrder, message: NIMMessage?,
                                          _ completion: @escaping (Error?, NSInteger, [MessageModel]?)
                                            -> Void) {
    let param = NIMGetMessagesDynamicallyParam()
    param.limit = messagPageNum
    param.session = session
    param.order = order
    if let msg = message {
      if order == .desc {
        param.endTime = msg.timestamp
      } else {
        param.startTime = msg.timestamp
      }
      param.anchorClientId = msg.messageId
      param.anchorServerId = msg.serverID
    }
    weak var weakSelf = self
    repo.getMessagesDynamically(param) { error, isReliable, messages in
      if let messageArray = messages, messageArray.count > 0 {
        var count = 0
        var datas = messageArray
        var readMsg: NIMMessage?
        if order == .desc {
          weakSelf?.oldMsg = messageArray.last
          readMsg = messageArray.first
        } else {
          readMsg = messageArray.last
          weakSelf?.newMsg = messageArray.last
        }
        for (i, msg) in datas.enumerated() {
          if let object = msg.messageObject as? NIMNotificationObject {
            if let content = object.content as? NIMTeamNotificationContent, content.operationType == .invite {
              if weakSelf?.filterInviteSet.contains(msg.messageId) == true {
                continue
              } else {
                weakSelf?.filterInviteSet.insert(msg.messageId)
              }
            }
          }
          print("message text : ", msg.text as Any)
          if let model = weakSelf?.modelFromMessage(message: msg), NotificationMessageUtils.isDiscussSeniorTeamUpdateCustomNoti(message: msg) == false {
            weakSelf?.filterRevokeMessage([model])
            if order == .desc {
              if weakSelf?.addTimeForHistoryMessage(msg) == true {
                count += 1
              }
              count += 1
              weakSelf?.messages.insert(model, at: 0)

              // 第一条消息默认显示时间
              if i == datas.count - 1 {
                let timeText = String.stringFromDate(date: Date(timeIntervalSince1970: msg.timestamp))
                let model = MessageTipsModel(message: nil,
                                             initType: .time,
                                             initText: timeText)
                weakSelf?.messages.insert(model, at: 0)
              }
            } else {
              if weakSelf?.addTimeMessage(msg) == true {
                count += 1
              }
              count += 1
              weakSelf?.messages.append(model)
            }
          }
        }
        completion(error, count, weakSelf?.messages)

        if weakSelf?.session.sessionType == .P2P {
          if let nearMsg = readMsg {
            weakSelf?.markRead(messages: [nearMsg]) { error in
              NELog.infoLog(
                ModuleName + " " + (weakSelf?.className ?? "ChatViewModel"),
                desc: "CALLBACK markRead " + (error?.localizedDescription ?? "no error")
              )
            }
          }
        } else if weakSelf?.session.sessionType == .team {
          weakSelf?.markRead(messages: messageArray) { error in
            NELog.infoLog(
              ModuleName + " " + (weakSelf?.className ?? "ChatViewModel"),
              desc: "CALLBACK markRead " + (error?.localizedDescription ?? "no error")
            )
          }
          weakSelf?.refreshReceipts(messages: messageArray)
        }
      } else {
        completion(error, 0, weakSelf?.messages)
      }
    }
  }

  public func queryRoamMsgHasMoreTime_v2(_ completion: @escaping (Error?, NSInteger, NSInteger, Int) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    weak var weakSelf = self
    // 记录可信时间戳
    if anchor == nil {
      weakSelf?.getMessagesModelDynamically(.desc, message: nil) { error, count, models in
        NELog.infoLog(
          ModuleName + " " + self.className,
          desc: "CALLBACK getMessageHistory " + (error?.localizedDescription ?? "no error")
        )
        completion(error, count, 0, 0)
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
      weakSelf?.getMessagesModelDynamically(.desc, message: weakSelf?.anchor) { error, value, models in
        moreEnd = value
        if error != nil {
          err = error
        }
        if let ms = models {
          historyDatas.append(contentsOf: ms)
        }
        print("drop down remote refresh : ", historyDatas.count)
        if let anchorMessage = weakSelf?.anchor {
          let model = self.modelFromMessage(message: anchorMessage)
          weakSelf?.filterRevokeMessage([model])
          if NotificationMessageUtils.isDiscussSeniorTeamUpdateCustomNoti(message: anchorMessage) == false {
            weakSelf?.messages.append(model)
          }
        }
        weakSelf?.getMessagesModelDynamically(.asc, message: weakSelf?.anchor) { error, value, models in
          NELog.infoLog(
            ModuleName + " " + self.className,
            desc: "CALLBACK pullRemoteRefresh " + (error?.localizedDescription ?? "no error")
          )
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
      }

      group.notify(queue: DispatchQueue.main, execute: {
        completion(err, moreEnd, newEnd, historyDatas.count)
      })
    }
  }

  // 查询本地历史消息
  public func getMessageHistory(_ message: NIMMessage?,
                                _ completion: @escaping (Error?, NSInteger, [MessageModel]?)
                                  -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId:" + (message?.messageId ?? "nil"))
    ChatProvider.shared.getMessageHistory(
      session: session,
      message: message,
      limit: messagPageNum
    ) { [weak self] error, messages in
      if let messageArray = messages, messageArray.count > 0 {
        self?.oldMsg = messageArray.first
        for msg in messageArray {
          if let model = self?.modelFromMessage(message: msg), NotificationMessageUtils.isDiscussSeniorTeamUpdateCustomNoti(message: msg) == false {
            self?.addTimeMessage(msg)
            self?.filterRevokeMessage([model])
            self?.messages.append(model)
          }
        }
        completion(error, messageArray.count, self?.messages)
//                mark read
        self?.markRead(messages: messageArray) { error in
          NELog.infoLog(
            ModuleName + " " + (self?.className ?? "ChatViewModel"),
            desc: "CALLBACK markRead " + (error?.localizedDescription ?? "no error")
          )
//          print("mark read \(error?.localizedDescription)")
        }

      } else {
        completion(error, 0, self?.messages)
      }
    }
  }

  // 查询更多本地历史消息
  public func getMoreMessageHistory(_ completion: @escaping (Error?, NSInteger, [MessageModel]?)
    -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
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
            if let model = self?.modelFromMessage(message: msg), NotificationMessageUtils.isDiscussSeniorTeamUpdateCustomNoti(message: msg) == false {
              self?.addTimeForHistoryMessage(msg)
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
          NELog.infoLog(
            ModuleName + " " + (weakSelf?.className ?? "ChatViewModel"),
            desc: "CALLBACK markRead " + (error?.localizedDescription ?? "no error")
          )
//          print("mark read \(error?.localizedDescription)")
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
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", direction: \(direction.rawValue)")
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
            if let model = weakSelf?.modelFromMessage(message: msg), NotificationMessageUtils.isDiscussSeniorTeamUpdateCustomNoti(message: msg) == false {
              weakSelf?.addTimeForHistoryMessage(msg)
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
                    ModuleName + " " + (weakSelf?.className ?? "ChatViewModel"),
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
    // 首次会话下拉，没有锚点消息，需要手动设置锚点消息
    if oldMsg == nil {
      for msg in messages {
        if let mmsg = msg.message {
          oldMsg = mmsg
          break
        }
      }
    }
    getMessagesModelDynamically(.desc, message: oldMsg, completion)
    NELog.infoLog(ModuleName + " " + className, desc: #function)
  }

  // 上拉获取最新消息
  public func pullRemoteRefresh(_ completion: @escaping (Error?, NSInteger, [MessageModel]?)
    -> Void) {
    getMessagesModelDynamically(.asc, message: newMsg, completion)
    NELog.infoLog(ModuleName + " " + className, desc: #function)
  }

  // 搜索历史记录查询的本地消息
  public func searchMessageHistory(direction: LoadMessageDirection, startTime: TimeInterval,
                                   endTime: TimeInterval,
                                   _ completion: @escaping (Error?, NSInteger, [MessageModel]?)
                                     -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", direction: \(direction.rawValue)")
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
            if let model = weakSelf?.modelFromMessage(message: msg), NotificationMessageUtils.isDiscussSeniorTeamUpdateCustomNoti(message: msg) == false {
              weakSelf?.addTimeMessage(msg)
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
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId:" + message.messageId)
    return credibleTimestamp <= 0 || message.timestamp >= credibleTimestamp
  }

  public func markRead(messages: [NIMMessage], _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messages.count: \(messages.count)")
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
    repo.markMessageRead(session) { error in
      if error != nil {
        NELog.errorLog(
          ModuleName + " " + (weakself?.className ?? "ChatViewModel"),
          desc: "❌markReadInSession failed,error = \(error!)"
        )
      }
    }
  }

  private func markReadInP2P(messages: [NIMMessage], _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messages.count: \(messages.count)")
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
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messages.count: \(messages.count)")
    var receipts = [NIMMessageReceipt]()
    for message in messages {
      let receiptEnable = message.setting?.teamReceiptEnabled ?? false
      if receiptEnable, !message.isTeamReceiptSended {
        let receipt = NIMMessageReceipt(message: message)
        receipts.append(receipt)
      }
    }
    let receiptsChunk = receipts.chunk(50)
    for receipt in receiptsChunk {
      repo.markTeamMessageRead(param: receipt) { error, failedReceipts in
        print("!! chatViewModel markReadInTeam error:\(String(describing: error))")
        completion(error)
      }
    }
  }

  public func deleteMessage(message: NIMMessage, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId:" + message.messageId)
    if deletingMsgDic.contains(message.messageId) {
      return
    }
    deletingMsgDic.insert(message.messageId)
    if message.serverID.count <= 0 {
      repo.deleteMessage(message: message)
      deleteMessageUpdateUI(message)
      deletingMsgDic.remove(message.messageId)
      completion(nil)
      return
    }
    weak var weakSelf = self
    repo.deleteServerMessage(message: message, ext: nil) { error in
      if error == nil {
        weakSelf?.deleteMessageUpdateUI(message)
      } else {
        completion(error)
      }
      weakSelf?.deletingMsgDic.remove(message.messageId)
    }
  }

  public func replyMessage(_ message: NIMMessage, _ target: NIMMessage,
                           _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId:" + message.messageId)
    repo.replyMessage(message, target) { error in
      completion(error)
    }
  }

  public func replyMessageWithoutThread(message: NIMMessage,
                                        target: NIMMessage,
                                        _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId:" + message.messageId)
    repo.replyMessageWithoutThread(message: message, session: session, target: target) { error in
      completion(error)
    }
  }

  public func revokeMessage(message: NIMMessage, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId:" + message.messageId)
    repo.revokeMessage(message: message) { error in
      if error == nil {
        self.revokeMessageUpdateUI(message)
      }
      completion(error)
    }
  }

  public func resendMessage(message: NIMMessage) -> NSError? {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId:" + message.messageId)
    return repo.resendMessage(message: message)
  }

  public func getUserInfo(userId: String) -> User? {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", userId:" + userId)
    return repo.getUserInfo(userId: userId)
  }

  public func getTeamMember(userId: String, teamId: String) -> NIMTeamMember? {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", userId:" + userId)
    return repo.getTeamMemberList(userId: userId, teamId: teamId)
  }

  public func onReceive(_ notification: NIMCustomSystemNotification) {
    NELog.infoLog(
      ModuleName + " " + className,
      desc: #function + ", notification.description:" + notification.description
    )
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

  // MARK: FriendProviderDelegate

  public func onFriendChanged(user: User) {
    if let uid = user.userId {
      newUserInfoDic[uid] = user
      delegate?.didRefreshTable()
    }
  }

  public func onUserInfoChanged(user: User) {
    if let uid = user.userId {
      newUserInfoDic[uid] = user
      delegate?.didRefreshTable()
    }
  }

  public func onBlackListChanged() {}

  //    MARK: NIMChatManagerDelegate

  // 收到消息
  public func onRecvMessages(_ messages: [NIMMessage]) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messages.count: \(messages.count)")
    var count = 0
    for msg in messages {
      if msg.session?.sessionId == session.sessionId {
        if msg.serverID.count <= 0, msg.messageType != .custom {
          continue
        }
        if msg.isDeleted == true {
          continue
        }
        if NotificationMessageUtils.isDiscussSeniorTeamUpdateCustomNoti(message: msg) {
          continue
        }
        if let object = msg.messageObject as? NIMNotificationObject {
          if let content = object.content as? NIMTeamNotificationContent, content.operationType == .invite {
            if filterInviteSet.contains(msg.messageId) {
              continue
            } else {
              filterInviteSet.insert(msg.messageId)
            }
          }
        }
        /* 后续解散群离开群弹框优化
         if msg.messageType == .notification, session.sessionType == .team {
           if team?.clientCustomInfo?.contains(discussTeamKey) == true {
             return
           }
           let value = NotificationMessageUtils.isTeamLeaveOrDismiss(message: msg)
           if value.isLeave == true {
             delegate?.didLeaveTeam()
           } else if value.isDismiss == true {
             delegate?.didDismissTeam()
           }

         }*/
        count += 1
        // 自定义消息处理
        newMsg = msg
        addTimeMessage(msg)
        let model = modelFromMessage(message: msg)
        self.messages.append(model)
      }
    }
    if count > 0 { delegate?.onRecvMessages(messages) }
  }

  public func willSend(_ message: NIMMessage) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId:" + message.messageId)
    print("\(#function)")

    if message.session?.sessionId != session.sessionId {
      return
    }
    // 自定义消息发送之前的处理
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
      let model = modelFromMessage(message: message)
      filterRevokeMessage([model])
      messages.append(model)
    }

    delegate?.willSend(message)
  }

  public func send(_ message: NIMMessage, progress: Float) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId: " + message.messageId)
    print("\(#function)  progress\(progress)")
    delegate?.send(message, progress: progress)
  }

  open func send(_ message: NIMMessage, didCompleteWithError error: Error?) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId: " + message.messageId)
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
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId: " + pinItem.messageId)
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
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId: " + pinItem.messageId)
    var index = -1
    for (i, model) in messages.enumerated() {
      if pinItem.messageServerID == model.message?.serverID {
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
      delegate?.onRemoveMessagePin(msg, atIndexs: [IndexPath(row: index, section: 0)])
    }
  }

  public func onNotifySyncStickTopSessions(_ response: NIMSyncStickTopSessionResponse) {}

  public func onNotifyAddStickTopSession(_ newInfo: NIMStickTopSessionInfo) {}

  public func onNotifyRemoveStickTopSession(_ removedInfo: NIMStickTopSessionInfo) {}

//    MARK: collection

  func addColletion(_ message: NIMMessage,
                    completion: @escaping (NSError?, NIMCollectInfo?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId: " + message.messageId)
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
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    guard let msg = notification.message else {
      return
    }

    revokeMessageUpdateUI(msg)
  }

  public func onRecvMessageReceipts(_ receipts: [NIMMessageReceipt]) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", receipts.count: \(receipts.count)")
    print(
      "chatViewModel:   :\(receipts.count) messageId:\(receipts.first?.messageId) messageId:\(receipts.first?.timestamp)"
    )
    delegate?.didReadedMessageIndexs()
  }

  public func avalibleOperationsForMessage(_ model: MessageContentModel?) -> [OperationItem]? {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", pinAccount: " + (model?.pinAccount ?? "nil"))
    var pinItem = OperationItem.pinItem()
    var items = [OperationItem]()

    if model?.message?.deliveryState == .failed || model?.message?.deliveryState == .delivering, model?.message?.messageType != .rtcCallRecord {
      switch model?.message?.messageType {
      case .text:
        items.append(contentsOf: [
          OperationItem.copyItem(),
          OperationItem.deleteItem(),
        ])
        return items
      case .audio, .video, .image, .location, .file:
        items.append(contentsOf: [
          OperationItem.deleteItem(),
        ])
        return items
      default:
        break
      }

      return nil
    }
    switch model?.message?.messageType {
    case .location:
      if let isPin = model?.isPined, isPin {
        pinItem = OperationItem.removePinItem()
      }
      items.append(contentsOf: [
        OperationItem.replayItem(),
        OperationItem.forwardItem(),
        pinItem,
        OperationItem.deleteItem(),
      ])
    case .text:
      if let isPin = model?.isPined, isPin {
        pinItem = OperationItem.removePinItem()
      }
      items = [
        OperationItem.copyItem(),
        OperationItem.replayItem(),
        OperationItem.forwardItem(),
        pinItem,
        OperationItem.deleteItem(),
      ]

    case .image, .video, .file:
      if let isPin = model?.isPined, isPin {
        pinItem = OperationItem.removePinItem()
      }
      items = [
        OperationItem.replayItem(),
        OperationItem.forwardItem(),
        pinItem,
        OperationItem.deleteItem(),
      ]
    case .audio:
      if let isPin = model?.isPined, isPin {
        pinItem = OperationItem.removePinItem()
      }
      items = [
        OperationItem.replayItem(),
        pinItem,
        OperationItem.deleteItem(),
      ]
    case .rtcCallRecord:
      items = [OperationItem.deleteItem()]

    default:
      if let isPin = model?.isPined, isPin {
        pinItem = OperationItem.removePinItem()
      }
      items = [
        OperationItem.replayItem(),
        pinItem,
        OperationItem.deleteItem(),
      ]
    }

    if model?.message?.from == NIMSDK.shared().loginManager.currentAccount(), model?.message?.messageType != .rtcCallRecord {
      items.append(OperationItem.recallItem())
    }
    return items
  }

  private func indexPathsForTeamMarkRead(_ receipts: [NIMMessageReceipt]) -> [IndexPath] {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", receipts.count: \(receipts.count)")
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
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", receipts.count: \(receipts.count)")
    var updateIndexs = [IndexPath]()
//      find messages that need to update UI
    var i = messages.count - 1
    for model in messages.reversed() {
      if let msg = model.message, msg.isRemoteRead {
        updateIndexs.append(IndexPath(row: i, section: 0))
        break
      } else {
        updateIndexs.append(IndexPath(row: i, section: 0))
        i -= 1
      }
    }
    return updateIndexs
  }

  // history message insert message at first of messages, send message add last of messages
  @discardableResult
  private func addTimeMessage(_ message: NIMMessage) -> Bool {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId: " + message.messageId)
    if NotificationMessageUtils.isDiscussSeniorTeamNoti(message: message) {
      return false
    }

    let lastTs = messages.last?.message?.timestamp ?? 0.0
    let curTs = message.timestamp
    let dur = curTs - lastTs
    if (dur / 60) > 5 {
      messages.append(timeModel(message))
      return true
    }
    return false
  }

  private func addTimeForHistoryMessage(_ message: NIMMessage) -> Bool {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId: " + message.messageId)
    if NotificationMessageUtils.isDiscussSeniorTeamNoti(message: message) {
      return false
    }

    let firstTs = messages.first?.message?.timestamp ?? 0.0
    let curTs = message.timestamp
    let dur = firstTs - curTs
    if (dur / 60) > 5 {
      let timeText = String.stringFromDate(date: Date(timeIntervalSince1970: firstTs))
      let model = MessageTipsModel(message: nil,
                                   initType: .time,
                                   initText: timeText)
      messages.insert(model, at: 0)
      return true
    }
    return false
  }

  private func timeModel(_ message: NIMMessage) -> MessageModel {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId: " + message.messageId)
    let curTs = message.timestamp
    let timeText = String.stringFromDate(date: Date(timeIntervalSince1970: curTs))
    let model = MessageTipsModel(message: nil,
                                 initType: .time,
                                 initText: timeText)
    return model
  }

  private func tipsModel(_ message: NIMMessage) -> MessageModel {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId: " + message.messageId)
    let model = MessageTipsModel(message: message)
    return model
  }

  private func modelFromMessage(message: NIMMessage) -> MessageModel {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId: " + message.messageId)
    var model: MessageModel
    print("message type : ", message.messageType.rawValue)
    switch message.messageType {
    case .video:
      model = MessageVideoModel(message: message)
    case .text:
      model = MessageTextModel(message: message)
    case .image:
      model = MessageImageModel(message: message)
    case .audio:
      model = MessageAudioModel(message: message)
    case .notification, .tip:
      model = MessageTipsModel(message: message)
    case .file:
      model = MessageFileModel(message: message)
    case .custom:
      model = MessageCustomModel(message: message)
    case .location:
      model = MessageLocationModel(message: message)
    case .rtcCallRecord:
      model = MessageCallRecordModel(message: message)
    default:
      // 未识别的消息类型，默认为文本消息类型，text为未知消息
      message.text = "未知消息"
      model = MessageContentModel(message: message)
    }
    if let uid = message.from {
      let user = getUserInfo(userId: uid)
      var fullName = uid
      var shortName = uid
      if let nickName = user?.userInfo?.nickName {
        fullName = nickName
        shortName = nickName
      }
      model.avatar = user?.userInfo?.avatarUrl
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
      model.shortName = getShortName(name: shortName, length: 2)
    }
    model.replyedModel = getReplyMessageWithoutThread(message: message)
    if let pin = repo.searchMessagePinHistory(message) {
      model.isPined = true
      model.pinAccount = pin.accountID
      let pinID = pin.accountID ?? NIMSDK.shared().loginManager.currentAccount()
      model.pinShowName = getShowName(userId: pinID, teamId: session.sessionId)
    } else {
      model.isPined = false
    }
    delegate?.getMessageModel?(model: model)
    return model
  }

  public func getReplyMessage(message: NIMMessage) -> MessageModel? {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId: " + message.messageId)
    guard let id = message.repliedMessageId, id.count > 0 else {
      return nil
    }
    if let m = ConversationProvider.shared.messagesInSession(session, messageIds: [id])?
      .first {
      let model = modelFromMessage(message: m)
      model.isReplay = true
      return model
    }
    let message = NIMMessage()
    let model = modelFromMessage(message: message)
    model.isReplay = true
    return model
  }

  public func getReplyMessageWithoutThread(message: NIMMessage) -> MessageModel? {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId: " + message.messageId)

    var replyId: String? = message.repliedMessageId
    if let yxReplyMsg = message.remoteExt?[keyReplyMsgKey] as? [String: Any] {
      replyId = yxReplyMsg["idClient"] as? String
    }

    guard let id = replyId, !id.isEmpty else {
      return nil
    }

    if let m = ConversationProvider.shared.messagesInSession(session, messageIds: [id])?
      .first {
      let model = modelFromMessage(message: m)
      model.isReplay = true
      return model
    }
    let message = NIMMessage()
    let model = modelFromMessage(message: message)
    model.isReplay = true
    return model
  }

  private func getUserInfo(_ userId: String, _ completion: @escaping (User?, NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", userId: " + userId)
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

//    获取展示的用户名字，p2p： 备注 > 昵称 > ID  team: 备注 > 群昵称 > 昵称 > ID
  func getShowName(userId: String, teamId: String?, _ showAlias: Bool = true) -> String {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", userId: " + userId)
    let user = getUserInfo(userId: userId)
    var fullName = userId
    if let nickName = user?.userInfo?.nickName {
      fullName = nickName
    }
    if let tID = teamId, session.sessionType == .team {
      // team
      let teamMember = getTeamMember(userId: userId, teamId: tID)
      if let teamNickname = teamMember?.nickname {
        fullName = teamNickname
      }
    }
    if showAlias, let alias = user?.alias {
      fullName = alias
    }
    return fullName
  }

//    全名后几位
  func getShortName(name: String, length: Int) -> String {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", name: " + name)
    return name
      .count > length ? String(name[name.index(name.endIndex, offsetBy: -length)...]) : name
  }

  func deleteMessageUpdateUI(_ message: NIMMessage) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId: " + message.messageId)
    var index = -1
    var replyIndex = [Int]()
    var hasFind = false
    for (i, model) in messages.enumerated() {
      if hasFind {
        var replyId: String? = model.message?.repliedMessageId
        if let yxReplyMsg = model.message?.remoteExt?[keyReplyMsgKey] as? [String: Any] {
          replyId = yxReplyMsg["idClient"] as? String
        }

        if let id = replyId, !id.isEmpty, id == message.messageId {
          messages[i].replyText = chatLocalizable("message_not_found")
          replyIndex.append(i)
        }
      } else {
        if model.message?.messageId == message.messageId {
          index = i
          hasFind = true
        }
      }
    }

    var indexs = [IndexPath]()
    var reloadIndexs = [IndexPath]()
    if index >= 0 {
//            remove time tip
      let last = index - 1
      if last >= 0, let timeModel = messages[last] as? MessageTipsModel,
         timeModel.type == .time {
        messages.removeSubrange(last ... index)
        indexs.append(IndexPath(row: last, section: 0))
        indexs.append(IndexPath(row: index, section: 0))
        for replyIdx in replyIndex {
          reloadIndexs.append(IndexPath(row: replyIdx - 2, section: 0))
        }
      } else {
        messages.remove(at: index)
        indexs.append(IndexPath(row: index, section: 0))
        for replyIdx in replyIndex {
          reloadIndexs.append(IndexPath(row: replyIdx - 1, section: 0))
        }
      }
    }

    delegate?.onDeleteMessage(message, atIndexs: indexs, reloadIndex: reloadIndexs)
  }

  func revokeMessageUpdateUI(_ message: NIMMessage) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId: " + message.messageId)
    var index = -1
    var replyIndex = [Int]()
    var hasFind = false

    for (i, model) in messages.enumerated() {
      if hasFind {
        var replyId: String? = model.message?.repliedMessageId
        if let yxReplyMsg = model.message?.remoteExt?[keyReplyMsgKey] as? [String: Any] {
          replyId = yxReplyMsg["idClient"] as? String
        }

        if let id = replyId, !id.isEmpty, id == message.messageId {
          replyIndex.append(i)
        }
      } else {
        if model.message?.serverID == message.serverID {
          index = i
          hasFind = true
        }
      }
    }

    var indexs = [IndexPath]()
    if index >= 0 {
      messages[index].isRevoked = true
      messages[index].replyedModel = nil
      messages[index].isPined = false
      indexs.append(IndexPath(row: index, section: 0))
    }

    for replyIdx in replyIndex {
      messages[replyIdx].replyText = chatLocalizable("message_not_found")
      indexs.append(IndexPath(row: replyIdx, section: 0))
    }

    delegate?.onRevokeMessage(message, atIndexs: indexs)
  }

  public func fetchMessageAttachment(_ message: NIMMessage, didCompleteWithError error: Error?) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId: " + message.messageId)
    print("featch message completion : ", error as Any)
  }

  public func fetchMessageAttachment(_ message: NIMMessage, progress: Float) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId: " + message.messageId)
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
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId: " + message.messageId)
    repo.downloadMessageAttachment(message, completion)
  }

  public func downLoad(_ urlString: String, _ filePath: String, _ progress: NIMHttpProgressBlock?,
                       _ completion: NIMDownloadCompleteBlock?) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId: " + urlString)
    repo.downloadSource(urlString, filePath, progress, completion)
  }

  public func getUrls() -> [String] {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
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
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId: " + message.messageId)
    users.forEach { user in
      if let uid = user.userId {
        let session = NIMSession(uid, type: .P2P)
        if let forwardMessage = repo.makeForwardMessage(message) {
          clearForwardAtMark(forwardMessage)
          repo.sendForwardMessage(forwardMessage, session)
        }
      }
    }
  }

  public func forwardTeamMessage(_ message: NIMMessage, _ team: NIMTeam) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId: " + message.messageId)
    if let tid = team.teamId {
      let session = NIMSession(tid, type: .team)
      if let forwardMessage = repo.makeForwardMessage(message) {
        clearForwardAtMark(forwardMessage)
        repo.sendForwardMessage(forwardMessage, session)
      }
    }
  }

  public func pinMessage(_ message: NIMMessage,
                         _ completion: @escaping (Error?, NIMMessagePinItem?, Int) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId: " + message.messageId)
    let item = NIMMessagePinItem(message: message)
    guard let _ = NIMSDK.shared().conversationManager.messages(in: session, messageIds: [message.messageId]) else {
      return
    }

    repo.addMessagePin(item) { [weak self] error, pinItem in
      if error != nil {
        completion(error, nil, -1)
      } else {
        var index = -1
        if let messages = self?.messages {
          for (i, model) in messages.enumerated() {
            if message.messageId == model.message?.messageId, !messages[i].isPined {
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
        completion(nil, pinItem, index)
      }
    }
  }

  public func removePinMessage(_ message: NIMMessage,
                               _ completion: @escaping (Error?, NIMMessagePinItem?, Int)
                                 -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", messageId: " + message.messageId)
    guard let _ = NIMSDK.shared().conversationManager.messages(in: session, messageIds: [message.messageId]) else {
      return
    }
    let item = NIMMessagePinItem(message: message)
    weak var weakSelf = self
    repo.removeMessagePin(item) { error, pinItem in
      if error != nil {
        completion(error, nil, -1)
      } else {
        let index = weakSelf?.removeLocalPinMessage(message) ?? -1
        completion(nil, pinItem, index)
      }
    }
  }

  public func sendInputTypingState() {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    if session.sessionType == .P2P {
      setTypingCustom(1)
    }
  }

  public func sendInputTypingEndState() {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    if session.sessionType == .P2P {
      setTypingCustom(0)
    }
  }

  func setTypingCustom(_ typing: Int) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", typing: \(typing)")
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
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    return repo.getHandsetMode()
  }

  public func getMessageRead() -> Bool {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    return repo.getMessageRead()
  }

  public func saveRevokeMessage(_ message: NIMMessage, _ completion: @escaping (Error?) -> Void) {
    let messageNew = NIMMessage()
    messageNew.text = chatLocalizable("message_recalled")
    var muta = [String: Any]()
    muta[revokeLocalMessage] = true
    if message.messageType == .text {
      muta[revokeLocalMessageContent] = message.text
    }
    messageNew.timestamp = message.timestamp
    messageNew.from = message.from
    messageNew.localExt = muta
    messageNew.remoteExt = message.remoteExt
    let setting = NIMMessageSetting()
    setting.shouldBeCounted = false
    setting.isSessionUpdate = false
    messageNew.setting = setting
    repo.saveMessageToDB(messageNew, session, completion)
  }

  private func filterRevokeMessage(_ messages: [MessageModel]) {
    messages.forEach { model in
      if let isRevoke = model.message?.localExt?[revokeLocalMessage] as? Bool, isRevoke == true {
        if let content = model.message?.localExt?[revokeLocalMessageContent] as? String, content.count > 0 {
          model.isRevokedText = true
          model.message?.text = content
        }
        model.isRevoked = true
      }
    }
  }

  public func refreshReceipts(messages: [NIMMessage]) {
    if session.sessionType != .team {
      return
    }
    if repo.settingProvider.getMessageRead() == false {
      return
    }
    print("refresh team id : ", session.sessionId)
    var receiptsMessages = [NIMMessage]()
    messages.forEach { message in
      if message.setting?.teamReceiptEnabled == true {
        receiptsMessages.append(message)
      }
    }
    for receipt in receiptsMessages.chunk(50) {
      repo.refreshReceipts(receipt)
    }
  }

  @discardableResult
  private func removeLocalPinMessage(_ message: NIMMessage) -> Int {
    var index = -1

    for (i, model) in messages.enumerated() {
      if message.messageId == model.message?.messageId, messages[i].isPined {
        messages[i].isPined = false
        messages[i].pinAccount = nil
        index = i
        break
      }
    }
    return index
  }

//    MARK: NIMConversationManagerDelegate

  // remote
  public func onRecvMessagesDeleted(_ messages: [NIMMessage], exts: [String: String]?) {
    var messageIDs = Set<String>()
    messages.forEach { message in
      if message.session?.sessionId != session.sessionId {
        return
      }
      if message.messageId.count <= 0 {
        return
      }
      messageIDs.insert(message.messageId)
    }
    if messageIDs.count > 0 {
      self.messages.removeAll { model in
        if let messageId = model.message?.messageId, messageId.count > 0 {
          if messageIDs.contains(messageId) {
            return true
          }
        }
        return false
      }
      if let lastModel = self.messages.last as? MessageTipsModel, lastModel.type == .time {
        self.messages.removeLast()
      }
      delegate?.didRefreshTable()
    }
  }

  deinit {
    print("deinit")
  }

  private func clearForwardAtMark(_ forwardMessage: NIMMessage) {
    forwardMessage.remoteExt?.removeValue(forKey: yxAtMsg)
    forwardMessage.remoteExt?.removeValue(forKey: keyReplyMsgKey)
    if forwardMessage.remoteExt?.count ?? 0 <= 0 {
      forwardMessage.remoteExt = nil
    }
  }

  func fetchPinMessage(_ completion: @escaping () -> Void) {
    repo.fetchPinMessage(session.sessionId, session.sessionType) { error, items in
      completion()
    }
  }
}
