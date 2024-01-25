// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECommonKit
import NECoreIMKit
import NECoreKit
import NIMSDK

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
  func onTeamMemberChange(team: NIMTeam)

  @objc optional func showErrorToast(error: Error?)
  @objc optional func getMessageModel(model: MessageModel)
  @objc optional func selectedMessagesChanged(_ count: Int)
}

let revokeLocalMessage = "revoke_message_local"
let revokeLocalMessageContent = "revoke_message_local_content"
let removePinMessageNoti = "remove_pin_message_noti"

@objcMembers
open class ChatViewModel: NSObject, ChatRepoMessageDelegate, NIMChatManagerDelegate,
  NIMConversationManagerDelegate, NIMSystemNotificationManagerDelegate, ChatExtendProviderDelegate, FriendProviderDelegate, NIMTeamManagerDelegate {
  public var team: NIMTeam?
  /// 当前成员的群成员对象类
  public var teamMember: NIMTeamMember?
  public var session: NIMSession
  public var messages = [MessageModel]()
  public weak var delegate: ChatViewModelDelegate?

  // 多选选中的消息
  public var selectedMessages = [NIMMessage]() {
    didSet {
      delegate?.selectedMessagesChanged?(selectedMessages.count)
    }
  }

  // 上拉时间戳
  private var newMsg: NIMMessage?
  // 下拉时间戳
  private var oldMsg: NIMMessage?

  public var repo = ChatRepo.shared
  public var operationModel: MessageContentModel?
  public var isReplying = false
  public let messagPageNum: UInt = 100

  // 可信时间戳
  public var credibleTimestamp: TimeInterval = 0
  public var anchor: NIMMessage?

  public var isHistoryChat = false

  public var filterInviteSet = Set<String>()

  public var deletingMsgDic = Set<String>()

  init(session: NIMSession) {
    NELog.infoLog(ModuleName + " ChatViewModel", desc: #function + ", sessionId:" + session.sessionId)
    self.session = session
    anchor = nil
    super.init()
    repo.addChatDelegate(delegate: self)
    repo.addContactDelegate(delegate: self)
    repo.addSessionDelegate(delegate: self)
    repo.addSystemNotificationDelegate(delegate: self)
    repo.addChatExtendDelegate(delegate: self)
    repo.addTeamDelegate(delegate: self)
    addObserver()
  }

  init(session: NIMSession, anchor: NIMMessage?) {
    NELog.infoLog(ModuleName + " ChatViewModel", desc: #function + ", sessionId:" + session.sessionId)
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
    repo.addTeamDelegate(delegate: self)
    addObserver()
  }

  func addObserver() {
    NotificationCenter.default.addObserver(self, selector: #selector(removePinNoti), name: Notification.Name(removePinMessageNoti), object: nil)
  }

  func removePinNoti(_ noti: Notification) {
    if let message = noti.object as? NIMMessage {
      removeLocalPinMessage(message)
      delegate?.didRefreshTable()
    }
  }

  /// 发送文本消息（当前会话）
  open func sendTextMessage(text: String, remoteExt: [String: Any]?, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", text.count: \(text.count)")
    if text.count <= 0 {
      return
    }
    repo.sendMessage(
      message: MessageUtils.textMessage(text: text, remoteExt: remoteExt),
      session: session,
      completion
    )
  }

  /// 发送文本消息（当前会话）
  open func sendTextMessage(text: String, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", text.count: \(text.count)")
    if text.count <= 0 {
      return
    }
    repo.sendMessage(
      message: MessageUtils.textMessage(text: text),
      session: session,
      completion
    )
  }

  /// 发送文本消息（非当前会话）
  open func sendTextMessage(text: String, session: NIMSession, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", text.count: \(text.count)")
    if text.count <= 0 {
      return
    }
    repo.sendMessage(
      message: MessageUtils.textMessage(text: text),
      session: session,
      completion
    )
  }

  open func sendAudioMessage(filePath: String, _ completion: @escaping (Error?) -> Void) {
    if ChatDeduplicationHelper.instance.isRecordAudioSended(path: filePath) == true {
      NELog.infoLog(ModuleName + " " + className(), desc: #function + ",duplicate send audio at filePath:" + filePath)
      return
    }
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", filePath:" + filePath)
    repo.sendMessage(
      message: MessageUtils.audioMessage(filePath: filePath),
      session: session,
      completion
    )
  }

  open func sendImageMessage(image: UIImage, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", image.size: \(image.size)")
    repo.sendMessage(
      message: MessageUtils.imageMessage(image: image),
      session: session,
      completion
    )
  }

  open func sendImageMessage(data: Data, ext: String, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", image data count: \(data.count)")
    repo.sendMessage(
      message: MessageUtils.imageMessage(data: data, ext: ext),
      session: session,
      completion
    )
  }

  open func sendImageMessage(path: String, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", image path: \(path)")
    repo.sendMessage(
      message: MessageUtils.imageMessage(path: path),
      session: session,
      completion
    )
  }

  open func sendVideoMessage(url: URL, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ",video url.path:" + url.path)
    weak var weakSelf = self

    convertVideoToMP4(videoURL: url) { url, error in
      if let p = url?.path, let s = weakSelf?.session {
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

  open func sendLocationMessage(_ model: ChatLocaitonModel, _ completion: @escaping (Error?) -> Void) {
    let message = MessageUtils.locationMessage(model.lat, model.lng, model.title, model.address)
    repo.sendMessage(message: message, session: session, completion)
  }

  open func sendFileMessage(filePath: String, displayName: String?, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", filePath:\(filePath)")
    repo.sendMessage(
      message: MessageUtils.fileMessage(filePath: filePath, displayName: displayName),
      session: session,
      completion
    )
  }

  open func sendFileMessage(data: Data, displayName: String?, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", data.count:\(data.count)")
    repo.sendMessage(
      message: MessageUtils.fileMessage(data: data, displayName: displayName),
      session: session,
      completion
    )
  }

  /// 发送自定义消息(当前会话)
  open func sendCustomMessage(attachment: NIMCustomAttachment,
                              remoteExt: [String: Any]?,
                              apnsConstent: String?,
                              _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", apnsConstent:\(String(describing: apnsConstent))")
    repo.sendMessage(
      message: MessageUtils.customMessage(attachment: attachment,
                                          remoteExt: remoteExt,
                                          apnsContent: apnsConstent),
      session: session,
      completion
    )
  }

  /// 发送自定义消息
  open func sendCustomMessage(attachment: NIMCustomAttachment,
                              remoteExt: [String: Any]?,
                              apnsConstent: String?,
                              session: NIMSession,
                              _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", apnsConstent:\(String(describing: apnsConstent))")
    repo.sendMessage(
      message: MessageUtils.customMessage(attachment: attachment,
                                          remoteExt: remoteExt,
                                          apnsContent: apnsConstent),
      session: session,
      completion
    )
  }

  open func sendBlackListTip(_ errorSession: NIMSession?, _ message: NIMMessage) {
//        if DeduplicationHelper.instance.isBlackTipSended(messageId: message.messageId) == true {
//            NELog.infoLog(ModuleName + " " + className(), desc: #function + "sendBlackListTip")
//            return
//        }
    guard let eSession = errorSession else {
      return
    }
    NELog.infoLog(ModuleName + " " + className(), desc: #function + "sendBlackListTip")
    let content = chatLocalizable("black_list_tip")
    let tip = NIMMessage()
    let object = NIMTipObject(attach: nil, callbackExt: nil)
    tip.messageObject = object
    tip.text = content
    let setting = NIMMessageSetting()
    setting.shouldBeCounted = false
    tip.setting = setting
    repo.saveMessageToDB(tip, eSession) { [weak self] error in
      NELog.infoLog(ModuleName + " " + (self?.className() ?? ""), desc: #function + "save black tip list tip result \(error?.localizedDescription ?? "")")
      if let model = self?.modelFromMessage(message: tip) {
        self?.messages.append(model)
        if let currentSid = self?.session.sessionId, let errorSid = errorSession?.sessionId, currentSid == errorSid {
          self?.delegate?.willSend(tip)
        }
      }
    }
  }

  // 动态查询历史消息解决方案
  open func getMessagesModelDynamically(_ order: NIMMessageSearchOrder, message: NIMMessage?,
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
        var readMsg: NIMMessage?
        if order == .desc {
          weakSelf?.oldMsg = messageArray.last
          readMsg = messageArray.first
        } else {
          readMsg = messageArray.last
          weakSelf?.newMsg = messageArray.last
        }
        for msg in messageArray {
          // 是否需要进行重复消息过滤
          var needFilter = msg.serverID.isEmpty
          if let object = msg.messageObject as? NIMNotificationObject,
             let content = object.content as? NIMTeamNotificationContent,
             content.operationType == .invite {
            needFilter = true
          }

          if needFilter {
            if weakSelf?.filterInviteSet.contains(msg.messageId) == true {
              continue
            } else {
              weakSelf?.filterInviteSet.insert(msg.messageId)
            }
          }

          print("message text : ", msg.text as Any)
          if let model = weakSelf?.modelFromMessage(message: msg), NotificationMessageUtils.isDiscussSeniorTeamUpdateCustomNoti(message: msg) == false {
            weakSelf?.filterRevokeMessage([model])
            if order == .desc {
              weakSelf?.addTimeForHistoryMessage(model)
              weakSelf?.messages.insert(model, at: 0)
              count += 1
            } else {
              if let last = weakSelf?.messages.last {
                ChatMessageHelper.addTimeMessage(model, last)
              }
              weakSelf?.messages.append(model)
              count += 1
            }
          }
        }

        // 第一条消息默认显示时间
        if let firstModel = weakSelf?.messages.first,
           let msg = firstModel.message {
          let timeText = String.stringFromDate(date: Date(timeIntervalSince1970: msg.timestamp))
          firstModel.timeContent = timeText
        }
        weakSelf?.checkAudioFile(messages: weakSelf?.messages)
        completion(error, count, weakSelf?.messages)

        if weakSelf?.session.sessionType == .P2P {
          if let nearMsg = readMsg {
            weakSelf?.markRead(messages: [nearMsg]) { error in
              NELog.infoLog(
                ModuleName + " " + (weakSelf?.className() ?? "ChatViewModel"),
                desc: "CALLBACK markRead " + (error?.localizedDescription ?? "no error")
              )
            }
          }
        } else if weakSelf?.session.sessionType == .team {
          weakSelf?.markRead(messages: messageArray) { error in
            NELog.infoLog(
              ModuleName + " " + (weakSelf?.className() ?? "ChatViewModel"),
              desc: "CALLBACK markRead " + (error?.localizedDescription ?? "no error")
            )
          }
          weakSelf?.refreshReceipts(messages: messageArray)
        }

        let group = DispatchGroup()
        for msg in messageArray {
          if let object = msg.messageObject as? NIMNotificationObject,
             let content = object.content as? NIMTeamNotificationContent {
            let targetIDs = content.targetIDs ?? []
            targetIDs.forEach { uid in
              if ChatUserCache.getUserInfo(uid) == nil {
                group.enter()
                ChatUserCache.getUserInfo(uid) { _, _ in
                  group.leave()
                }
              }
            }
          }
        }

        group.notify(queue: .main) {
          weakSelf?.delegate?.didRefreshTable()
        }

      } else {
        weakSelf?.checkAudioFile(messages: weakSelf?.messages)
        completion(error, 0, weakSelf?.messages)
      }
    }
  }

  open func queryRoamMsgHasMoreTime_v2(_ completion: @escaping (Error?, NSInteger, NSInteger, Int) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function)
    weak var weakSelf = self
    // 记录可信时间戳
    if anchor == nil {
      weakSelf?.getMessagesModelDynamically(.desc, message: nil) { error, count, models in
        NELog.infoLog(
          ModuleName + " " + self.className(),
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
            ModuleName + " " + self.className(),
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
  open func getMessageHistory(_ message: NIMMessage?,
                              _ completion: @escaping (Error?, NSInteger, [MessageModel]?)
                                -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId:" + (message?.messageId ?? "nil"))
    ChatProvider.shared.getMessageHistory(
      session: session,
      message: message,
      limit: messagPageNum
    ) { [weak self] error, messages in
      if let messageArray = messages, messageArray.count > 0 {
        self?.oldMsg = messageArray.first
        for msg in messageArray {
          if let model = self?.modelFromMessage(message: msg), NotificationMessageUtils.isDiscussSeniorTeamUpdateCustomNoti(message: msg) == false {
            if let last = self?.messages.last {
              ChatMessageHelper.addTimeMessage(model, last)
            }
            self?.filterRevokeMessage([model])
            self?.messages.append(model)
          }
        }
        completion(error, messageArray.count, self?.messages)
        // mark read
        self?.markRead(messages: messageArray) { error in
          NELog.infoLog(
            ModuleName + " " + (self?.className() ?? "ChatViewModel"),
            desc: "CALLBACK markRead " + (error?.localizedDescription ?? "no error")
          )
        }

      } else {
        completion(error, 0, self?.messages)
      }
    }
  }

  // 查询更多本地历史消息
  open func getMoreMessageHistory(_ completion: @escaping (Error?, NSInteger, [MessageModel]?)
    -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function)
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
              self?.addTimeForHistoryMessage(model)
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
            ModuleName + " " + (weakSelf?.className() ?? "ChatViewModel"),
            desc: "CALLBACK markRead " + (error?.localizedDescription ?? "no error")
          )
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
  open func getRemoteHistoryMessage(direction: LoadMessageDirection, updateCredible: Bool,
                                    option: NIMHistoryMessageSearchOption,
                                    _ completion: @escaping (Error?, NSInteger,
                                                             [MessageModel]?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", direction: \(direction.rawValue)")
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
              weakSelf?.addTimeForHistoryMessage(model)
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
                    ModuleName + " " + (weakSelf?.className() ?? "ChatViewModel"),
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
  open func dropDownRemoteRefresh(_ completion: @escaping (Error?, NSInteger, [MessageModel]?)
    -> Void) {
    // 首次会话下拉，没有锚点消息 || 锚点消息被删除，需要手动设置锚点消息
    if oldMsg == nil || !messages.contains(where: { $0.message?.messageId == oldMsg?.messageId }) {
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

    getMessagesModelDynamically(.desc, message: oldMsg, completion)
    NELog.infoLog(ModuleName + " " + className(), desc: #function)
  }

  // 上拉获取最新消息
  open func pullRemoteRefresh(_ completion: @escaping (Error?, NSInteger, [MessageModel]?)
    -> Void) {
    getMessagesModelDynamically(.asc, message: newMsg, completion)
    NELog.infoLog(ModuleName + " " + className(), desc: #function)
  }

  // 搜索历史记录查询的本地消息
  open func searchMessageHistory(direction: LoadMessageDirection, startTime: TimeInterval,
                                 endTime: TimeInterval,
                                 _ completion: @escaping (Error?, NSInteger, [MessageModel]?)
                                   -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", direction: \(direction.rawValue)")
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
              ChatMessageHelper.addTimeMessage(model, weakSelf?.messages.last)
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
  open func isMessageCredible(message: NIMMessage) -> Bool {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId:" + message.messageId)
    return credibleTimestamp <= 0 || message.timestamp >= credibleTimestamp
  }

  open func markRead(messages: [NIMMessage], _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messages.count: \(messages.count)")
    if session.sessionType == .P2P {
      markReadInP2P(messages: messages, completion)
    } else if session.sessionType == .team {
      markReadInTeam(messages: messages, completion)
    }
    // mark session read
    weak var weakself = self
    repo.markMessageRead(session) { error in
      if error != nil {
        NELog.errorLog(
          ModuleName + " " + (weakself?.className() ?? "ChatViewModel"),
          desc: "❌markReadInSession failed,error = \(error!)"
        )
      }
    }
  }

  // 单人会话消息已读标记
  private func markReadInP2P(messages: [NIMMessage], _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messages.count: \(messages.count)")
    for message in messages.reversed() {
      if message.isReceivedMsg {
        let param = NIMMessageReceipt(message: message)
        repo.markP2pMessageRead(param: param, completion)
        break
      }
    }
    completion(nil)
  }

  // 群消息已读标记
  private func markReadInTeam(messages: [NIMMessage], _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messages.count: \(messages.count)")
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

  // 删除消息
  open func deleteMessage(_ completion: @escaping (Error?) -> Void) {
    guard let message = operationModel?.message else {
      NELog.errorLog(ModuleName + " " + className(), desc: #function + ", message is nil")
      return
    }
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId:" + message.messageId)

    // 已撤回的消息不能删除
    if operationModel?.isRevoked == true {
      return
    }

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

    if message.serverID == "0" {
      repo.deleteMessage(message: message)
      deleteMessageUpdateUI(message)
      weakSelf?.deletingMsgDic.remove(message.messageId)
      completion(nil)
      return
    }

    repo.deleteServerMessage(message: message, ext: nil) { error in
      if error == nil {
        weakSelf?.deleteMessageUpdateUI(message)
      } else {
        completion(error)
      }
      weakSelf?.deletingMsgDic.remove(message.messageId)
    }
  }

  open func deleteMessages(messages: [NIMMessage], _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", message count:\(messages.count)")
    var localMsgs = [NIMMessage]()
    var remoteMsgs = [NIMMessage]()
    for msg in messages {
      if deletingMsgDic.contains(msg.messageId) {
        continue
      }
      deletingMsgDic.insert(msg.messageId)
      if msg.serverID.count <= 0 {
        localMsgs.append(msg)
      } else {
        remoteMsgs.append(msg)
      }
    }

    localMsgs.forEach { msg in
      repo.deleteMessage(message: msg)
      deleteMessageUpdateUI(msg)
      deletingMsgDic.remove(msg.messageId)
    }

    weak var weakSelf = self
    repo.deleteRemoteMessages(messages: remoteMsgs, exts: nil) { error in
      if error == nil {
        remoteMsgs.forEach { msg in
          weakSelf?.deleteMessageUpdateUI(msg)
          weakSelf?.deletingMsgDic.remove(msg.messageId)
        }
      } else {
        completion(error)
      }
    }
  }

  // 回复消息
  open func replyMessage(_ message: NIMMessage, _ target: NIMMessage,
                         _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId:" + message.messageId)
    repo.replyMessage(message, target) { error in
      completion(error)
    }
  }

  open func replyMessageWithoutThread(message: NIMMessage,
                                      target: NIMMessage,
                                      _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId:" + message.messageId)
    repo.replyMessageWithoutThread(message: message, session: session, target: target) { error in
      completion(error)
    }
  }

  // 撤回消息
  open func revokeMessage(message: NIMMessage, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId:" + message.messageId)
    repo.revokeMessage(message: message) { error in
      if error == nil {
        self.revokeMessageUpdateUI(message)
      }
      completion(error)
    }
  }

  // 消息重发
  @discardableResult
  open func resendMessage(message: NIMMessage) -> NSError? {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId:" + message.messageId)
    ChatDeduplicationHelper.instance.clearCache()
    return repo.resendMessage(message: message)
  }

  // 从本地获取用户信息
  open func getUserInfo(userId: String) -> NEKitUser? {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", userId:" + userId)
    return repo.getUserInfo(userId: userId)
  }

  // 获取指定的群成员
  open func getTeamMember(userId: String, teamId: String) -> NIMTeamMember? {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", userId:" + userId)
    return repo.getTeamMemberList(userId: userId, teamId: teamId)
  }

  // 系统通知回调
  // 自定义系统通知回调
  open func onReceive(_ notification: NIMCustomSystemNotification) {
    NELog.infoLog(
      ModuleName + " " + className(),
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

  open func onFriendChanged(user: NEKitUser) {
    ChatUserCache.updateUserInfo(user)
  }

  open func onUserInfoChanged(user: NEKitUser) {
    ChatUserCache.updateUserInfo(user)
  }

  open func onBlackListChanged() {}

  //    MARK: NIMChatManagerDelegate

  // 收到消息
  open func onRecvMessages(_ messages: [NIMMessage]) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messages.count: \(messages.count), first.messageID: \(messages.first?.messageId ?? "")")
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
        let model = modelFromMessage(message: msg)
        ChatMessageHelper.addTimeMessage(model, self.messages.last)
        self.messages.append(model)
      }
    }
    if count > 0 { delegate?.onRecvMessages(messages) }
  }

  open func willSend(_ message: NIMMessage) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId:" + message.messageId)
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
      let model = modelFromMessage(message: message)
      ChatMessageHelper.addTimeMessage(model, messages.last)
      filterRevokeMessage([model])
      messages.append(model)
    }

    delegate?.willSend(message)
  }

  // 发送消息进度回调
  open func send(_ message: NIMMessage, progress: Float) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + message.messageId)
    print("\(#function)  progress\(progress)")
    delegate?.send(message, progress: progress)
  }

  // 发送消息完成回调
  open func send(_ message: NIMMessage, didCompleteWithError error: Error?) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + message.messageId)
    print("\(#function) message deliveryState:\(message.deliveryState) error:\(error)")
    for (i, msg) in messages.enumerated() {
      if message.messageId == msg.message?.messageId {
        messages[i].message = message
        break
      }
    }
    // 判断发送失败原因是否是因为在黑名单中
    if error != nil {
      if let err = error as NSError? {
        if err.code == inBlackListCode {
          weak var weakSelf = self
          DispatchQueue.main.async {
            weakSelf?.sendBlackListTip(message.session, message)
          }
        }
      }
    }

    delegate?.send(message, didCompleteWithError: error)
  }

//    MARK: ChatExtendProviderDelegate

  // 添加标记消息回调
  open func onNotifyAddMessagePin(pinItem: NIMMessagePinItem) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + pinItem.messageId)
    var index = -1
    for (i, model) in messages.enumerated() {
      if pinItem.messageServerID == model.message?.serverID {
        messages[i].isPined = true
        let pinID = pinItem.accountID ?? NIMSDK.shared().loginManager.currentAccount()
        messages[i].pinAccount = pinID
        messages[i].pinShowName = ChatUserCache.getShowName(userId: pinID, teamId: session.sessionId)
        index = i
        break
      }
    }
    if index >= 0, let msg = messages[index].message {
      delegate?.onAddMessagePin(msg, atIndexs: [IndexPath(row: index, section: 0)])
    }
  }

  // 移除标记消息回调
  open func onNotifyRemoveMessagePin(pinItem: NIMMessagePinItem) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + pinItem.messageId)
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

  open func onNotifySyncStickTopSessions(_ response: NIMSyncStickTopSessionResponse) {}

  open func onNotifyAddStickTopSession(_ newInfo: NIMStickTopSessionInfo) {}

  open func onNotifyRemoveStickTopSession(_ removedInfo: NIMStickTopSessionInfo) {}

//    MARK: collection

  func addColletion(_ message: NIMMessage,
                    completion: @escaping (NSError?, NIMCollectInfo?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + message.messageId)
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

  // 撤回消息回调
  open func onRecvRevokeMessageNotification(_ notification: NIMRevokeMessageNotification) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function)
    guard let msg = notification.message else {
      return
    }

    NELog.infoLog(ModuleName + className(), desc: #function + "messageId:\(msg.messageId), serverID:\(msg.serverID)")

    revokeMessageUpdateUI(msg)
  }

  open func onRecvMessageReceipts(_ receipts: [NIMMessageReceipt]) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", receipts.count: \(receipts.count)")
    print(
      "chatViewModel:   :\(receipts.count) messageId:\(receipts.first?.messageId) messageId:\(receipts.first?.timestamp)"
    )
    delegate?.didReadedMessageIndexs()
  }

  open func avalibleOperationsForMessage(_ model: MessageContentModel?) -> [OperationItem]? {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", pinAccount: " + (model?.pinAccount ?? "nil"))
    var items = [OperationItem]()

    /// 消息发送中的消息只能删除（文本可复制）
    if model?.message?.deliveryState == .delivering {
      switch model?.message?.messageType {
      case .text:
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
    if model?.message?.deliveryState == .failed ||
      model?.message?.messageType == .rtcCallRecord ||
      model?.message?.isBlackListed == true {
      switch model?.message?.messageType {
      case .text:
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
    switch model?.message?.messageType {
    case .location:
      items.append(contentsOf: [
        OperationItem.replayItem(),
        OperationItem.forwardItem(),
        pinItem,
        OperationItem.deleteItem(),
        OperationItem.selectItem(),
      ])
    case .text:
      items = [
        OperationItem.copyItem(),
        OperationItem.replayItem(),
        OperationItem.forwardItem(),
        pinItem,
        OperationItem.deleteItem(),
        OperationItem.selectItem(),
      ]
    case .image, .video, .file:
      items = [
        OperationItem.replayItem(),
        OperationItem.forwardItem(),
        pinItem,
        OperationItem.deleteItem(),
        OperationItem.selectItem(),
      ]
    case .audio:
      items = [
        OperationItem.replayItem(),
        pinItem,
        OperationItem.deleteItem(),
        OperationItem.selectItem(),
      ]
    case .custom:
      if let attach = NECustomAttachment.attachmentOfCustomMessage(message: model?.message) {
        if attach.customType == customRichTextType {
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
        ])
      } else {
        // 未知消息体
        items = [
          OperationItem.deleteItem(),
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

    // 自己发送且非未知消息可以撤回
    if model?.message?.from == NIMSDK.shared().loginManager.currentAccount() {
      if model?.message?.messageType == .custom,
         NECustomAttachment.dataOfCustomMessage(message: model?.message) == nil {
        return items
      }
      items.append(OperationItem.recallItem())
    }
    return items
  }

  private func indexPathsForTeamMarkRead(_ receipts: [NIMMessageReceipt]) -> [IndexPath] {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", receipts.count: \(receipts.count)")
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
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", receipts.count: \(receipts.count)")
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

  private func addTimeForHistoryMessage(_ model: MessageModel) {
    guard let first = messages.first,
          let firstMsg = first.message else {
      NELog.errorLog(ModuleName + " " + className(), desc: #function + ", model.message is nil")
      return
    }

    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + firstMsg.messageId)
    if NotificationMessageUtils.isDiscussSeniorTeamNoti(message: firstMsg) {
      return
    }

    let firstTs = firstMsg.timestamp
    let curTs = model.message?.timestamp ?? 0.0
    let dur = firstTs - curTs
    if (dur / 60) > 5 {
      let timeText = String.stringFromDate(date: Date(timeIntervalSince1970: firstTs))
      first.timeContent = timeText
    }
  }

  // 构建聊天页面UI显示model
  open func modelFromMessage(message: NIMMessage) -> MessageModel {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + message.messageId)
    let model = ChatMessageHelper.modelFromMessage(message: message)
    if let uid = message.from {
      let user = ChatUserCache.getUserInfo(uid)
      let fullName = ChatUserCache.getShowName(userId: uid, teamId: session.sessionId)
      model.avatar = user?.userInfo?.avatarUrl
      model.fullName = fullName
      model.shortName = ChatUserCache.getShortName(name: user?.showName(false) ?? "", length: 2)
    }
    model.replyedModel = getReplyMessageWithoutThread(message: message)
    if let pin = repo.searchMessagePinHistory(message) {
      model.isPined = true
      model.pinAccount = pin.accountID
      let pinID = pin.accountID ?? NIMSDK.shared().loginManager.currentAccount()
      model.pinShowName = ChatUserCache.getShowName(userId: pinID, teamId: session.sessionId)
    } else {
      model.isPined = false
    }
    delegate?.getMessageModel?(model: model)
    return model
  }

  // 查找回复消息
  open func getReplyMessage(message: NIMMessage) -> MessageModel? {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + message.messageId)
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

  open func getReplyMessageWithoutThread(message: NIMMessage) -> MessageModel? {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + message.messageId)

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

  func deleteMessageUpdateUI(_ message: NIMMessage) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + message.messageId)
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
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + message.messageId)
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

  open func fetchMessageAttachment(_ message: NIMMessage, didCompleteWithError error: Error?) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + message.messageId)
  }

  open func fetchMessageAttachment(_ message: NIMMessage, progress: Float) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + message.messageId)
  }

  open func fetchMessageAttachment(_ message: NIMMessage,
                                   _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + message.messageId)
    repo.downloadMessageAttachment(message, completion)
  }

  open func downLoad(_ urlString: String, _ filePath: String, _ progress: NIMHttpProgressBlock?,
                     _ completion: NIMDownloadCompleteBlock?) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + urlString)
    repo.downloadSource(urlString, filePath, progress, completion)
  }

  // 转发消息
  open func forwardMessage(_ forwardMessages: [NIMMessage],
                           _ session: NIMSession,
                           _ comment: String?,
                           _ completion: @escaping (Error?) -> Void) {
    for message in forwardMessages {
      if let forwardMessage = repo.makeForwardMessage(message) {
        ChatMessageHelper.clearForwardAtMark(forwardMessage)
        repo.sendForwardMessage(forwardMessage, session)
      }
    }
    if let text = comment, !text.isEmpty {
      sendTextMessage(text: text, session: session, completion)
    } else {
      completion(nil)
    }
  }

  // 合并转发消息
  open func forwardMultiMessage(_ forwardMessages: [NIMMessage],
                                _ toSession: NIMSession,
                                _ depth: Int = 0,
                                _ comment: String?,
                                _ completion: @escaping (Error?) -> Void) {
    if forwardMessages.count <= 0 {
      if let text = comment, !text.isEmpty {
        sendTextMessage(text: text, session: toSession, completion)
      } else {
        completion(nil)
      }
      return
    }

    let fromSession = session
    let header = ChatMessageHelper.buildHeader(messageCount: forwardMessages.count)
    ChatMessageHelper.buildBody(messages: forwardMessages) { body, abstracts in
      let multiForwardMsg = header + body
      let fileName = multiForwardFileName + "\(Int(Date().timeIntervalSince1970))"
      if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        let filePath = documentsDirectory.appendingPathComponent("NEIMUIKit/\(fileName)")
        if let multiForwardMsgData = multiForwardMsg.data(using: .utf8) {
          do {
            try multiForwardMsgData.write(to: filePath)
          } catch {
            completion(NSError(domain: chatLocalizable("forward_failed"), code: 414))
            print("Error writing string to file: \(error)")
            return
          }
        }

        NIMSDK.shared().resourceManager.upload(filePath.path, progress: nil) { [weak self] url, error in
          if let err = error {
            completion(err)
          } else if let url = url {
            let md5 = ChatMessageHelper.getFileChecksum(fileURL: filePath)

            // 删除本地文件
            do {
              try FileManager.default.removeItem(atPath: filePath.path)
            } catch {
              print("无法删除合并转发文件：\(error)")
            }

            var data = [String: Any]()
            data["sessionId"] = toSession.sessionId
            data["sessionName"] = ChatMessageHelper.getSessionName(session: fromSession, showAlias: false)
            data["url"] = url
            data["md5"] = md5
            data["depth"] = depth
            data["abstracts"] = abstracts

            var jsonData = [String: Any]()
            jsonData["data"] = data
            jsonData["messageType"] = "custom"
            jsonData["type"] = customMultiForwardType

            let attah = NECustomAttachment(customType: customMultiForwardType,
                                           cellHeight: customMultiForwardCellHeight,
                                           data: jsonData)
            self?.sendCustomMessage(attachment: attah,
                                    remoteExt: nil,
                                    apnsConstent: "[\(chatLocalizable("chat_history"))]",
                                    session: toSession) { error in
              if let err = error {
                completion(err)
              } else {
                if let text = comment, !text.isEmpty {
                  self?.sendTextMessage(text: text, session: toSession, completion)
                } else {
                  completion(nil)
                }
              }
            }
          }
        }
      }
    }
  }

  open func forwardUserMessage(_ users: [NIMUser],
                               _ isMultiForward: Bool,
                               _ depth: Int,
                               _ comment: String?,
                               _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messages.count: \(messages.count)")

    // 排序（发送时间正序）
    let forwardMessages = selectedMessages.sorted { msg1, msg2 in
      msg1.timestamp < msg2.timestamp
    }

    users.forEach { user in
      if let uid = user.userId {
        let session = NIMSession(uid, type: .P2P)
        if isMultiForward {
          forwardMultiMessage(forwardMessages, session, depth, comment, completion)
        } else {
          forwardMessage(forwardMessages, session, comment, completion)
        }
      }
    }
  }

  open func forwardTeamMessage(_ team: NIMTeam,
                               _ isMultiForward: Bool,
                               _ depth: Int,
                               _ comment: String?,
                               _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messages.count: \(messages.count)")
    if let tid = team.teamId {
      let session = NIMSession(tid, type: .team)
      if isMultiForward {
        forwardMultiMessage(selectedMessages, session, depth, comment, completion)
      } else {
        forwardMessage(selectedMessages, session, comment, completion)
      }
    }
  }

  // 标记消息
  open func pinMessage(_ message: NIMMessage,
                       _ completion: @escaping (Error?, NIMMessagePinItem?, Int) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + message.messageId)
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
              messages[i].pinShowName = ChatUserCache.getShowName(
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

  // 取消消息标记
  open func removePinMessage(_ message: NIMMessage,
                             _ completion: @escaping (Error?, NIMMessagePinItem?, Int)
                               -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + message.messageId)
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

  // 发送正在输入中状态
  open func sendInputTypingState() {
    NELog.infoLog(ModuleName + " " + className(), desc: #function)
    if session.sessionType == .P2P {
      setTypingCustom(1)
    }
  }

  // 发送结束输入中状态
  open func sendInputTypingEndState() {
    NELog.infoLog(ModuleName + " " + className(), desc: #function)
    if session.sessionType == .P2P {
      setTypingCustom(0)
    }
  }

  func setTypingCustom(_ typing: Int) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", typing: \(typing)")
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

  open func getHandSetEnable() -> Bool {
    NELog.infoLog(ModuleName + " " + className(), desc: #function)
    return repo.getHandsetMode()
  }

  open func getMessageRead() -> Bool {
    NELog.infoLog(ModuleName + " " + className(), desc: #function)
    return repo.getMessageRead()
  }

  // 本地保存撤回消息
  open func saveRevokeMessage(_ message: NIMMessage, _ completion: @escaping (Error?) -> Void) {
    let messageNew = NIMMessage()
    messageNew.text = chatLocalizable("message_recalled")
    var muta = [String: Any]()
    muta[revokeLocalMessage] = true
    if message.messageType == .text {
      muta[revokeLocalMessageContent] = message.text
    }
    if message.messageType == .custom {
      if let title = NECustomAttachment.titleOfRichText(message: message), !title.isEmpty {
        muta[revokeLocalMessageContent] = title
      }
      if let body = NECustomAttachment.bodyOfRichText(message: message), !body.isEmpty {
        muta[revokeLocalMessageContent] = body
      }
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

  open func filterRevokeMessage(_ messages: [MessageModel]) {
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

  // 刷新已读回执
  open func refreshReceipts(messages: [NIMMessage]) {
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

  // 多端登录删除消息
  open func onRecvMessagesDeleted(_ messages: [NIMMessage], exts: [String: String]?) {
    messages.forEach { message in
      if message.session?.sessionId != session.sessionId {
        return
      }
      if message.messageId.count <= 0 {
        return
      }
      deleteMessageUpdateUI(message)
    }
  }

  func fetchPinMessage(_ completion: @escaping () -> Void) {
    repo.fetchPinMessage(session.sessionId, session.sessionType) { error, items in
      completion()
    }
  }

  // 检查音频消息是否有附件
  open func checkAudioFile(messages: [MessageModel]?) {
    messages?.forEach { model in
      if let message = model.message {
        ChatMessageHelper.downloadAudioFile(message: message)
      }
    }
  }

  open func onTeamMemberChanged(_ team: NIMTeam) {
    if session.sessionType == .team, session.sessionId == team.teamId {
      self.team = team
      delegate?.onTeamMemberChange(team: team)
    }
  }
}
