// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECommonKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK

@objc
public protocol ChatViewModelDelegate: NSObjectProtocol {
  func onRecvMessages(_ messages: [V2NIMMessage])
  func sending(_ message: V2NIMMessage)
  func sendSuccess(_ message: V2NIMMessage)
  @objc optional func send(_ message: V2NIMMessage, progress: Float)
  func onLoadMoreWithMessage(_ indexs: [IndexPath])
  func onDeleteMessage(_ messages: [V2NIMMessage], deleteIndexs: [IndexPath], reloadIndex: [IndexPath])
  func onRevokeMessage(_ message: V2NIMMessage, atIndexs: [IndexPath])
  func onMessagePinStatusChange(_ message: V2NIMMessage?, atIndexs: [IndexPath])
  func remoteUserEditing()
  func remoteUserEndEditing()
  func didLeaveTeam()
  func didDismissTeam()
  func tableViewReload()

  @objc optional func showErrorToast(error: Error?)
  @objc optional func getMessageModel(model: MessageModel)
  @objc optional func selectedMessagesChanged(_ count: Int)
}

@objcMembers
open class ChatViewModel: NSObject, NEChatListener, NENotiListener {
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
  public var isReplying = false
  public let messagPageNum: Int = 100
  public var anchor: V2NIMMessage?

  public var isHistoryChat = false

  public var filterInviteSet = Set<String>()

  public var deletingMsgDic = Set<String>()

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
    chatRepo.addChatListener(self)
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
    chatRepo.addChatListener(self)
  }

  /// 根据会话id列表清空相应会话的未读数
  public func clearUnreadCount() {
    ConversationProvider.shared.clearUnreadCountByIds([conversationId]) { result, error in
      NEALog.infoLog(ModuleName, desc: #function + " error" + (error?.localizedDescription ?? ""))
    }
  }

  /// 加载数据
  /// - Parameter completion: 完成回调
  open func loadData(_ completion: @escaping (Error?, NSInteger, NSInteger, Int) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    weak var weakSelf = self

    // 记录可信时间戳
    if anchor == nil {
      weakSelf?.getHistoryMessage(order: .QUERY_DIRECTION_DESC, message: nil) { error, count, models in
        NEALog.infoLog(
          ModuleName + " " + ChatViewModel.className(),
          desc: "CALLBACK getMessageList " + (error?.localizedDescription ?? "no error")
        )
        completion(error, count, 0, 0)
        weakSelf?.loadMoreWithMessage(models)
      }
    } else {
      // 有锚点消息，从两个方向拉去消息
      weakSelf?.newMsg = weakSelf?.anchor
      weakSelf?.oldMsg = weakSelf?.anchor

      let group = DispatchGroup()

      var moreEnd = 0
      var newEnd = 0
      var historyDatas = [V2NIMMessage]()
      var newDatas = [V2NIMMessage]()
      var loadMessages = [V2NIMMessage]()

      var err: Error?
      group.enter()
      weakSelf?.getHistoryMessage(order: .QUERY_DIRECTION_DESC, message: weakSelf?.anchor) { error, value, models in
        moreEnd = value
        if error != nil {
          err = error
        }

        historyDatas.append(contentsOf: models)
        loadMessages.append(contentsOf: historyDatas)

        group.enter()
        if let anchorMessage = weakSelf?.anchor {
          loadMessages.append(anchorMessage)
          weakSelf?.modelFromMessage(message: anchorMessage) { model in
            weakSelf?.messages.append(model)
            group.leave()
          }
        }

        group.enter()
        weakSelf?.getHistoryMessage(order: .QUERY_DIRECTION_ASC, message: weakSelf?.anchor) { error, value, models in
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

      group.notify(queue: .main) {
        completion(err, moreEnd, newEnd, historyDatas.count)
        weakSelf?.loadMoreWithMessage(loadMessages)
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
    weak var weakSelf = self
    let conversationId = weakSelf?.conversationId ?? ""
    let group = DispatchGroup()
    let sema = DispatchSemaphore(value: 0)

    DispatchQueue.global().async { [self] in

      // 群聊需要获取群昵称
      if V2NIMConversationIdUtil.conversationType(conversationId) != .CONVERSATION_TYPE_P2P {
        let userIds = messages.compactMap { $0.message?.senderId }
        loadShowName(userIds, weakSelf?.sessionId) {
          // 获取头像昵称
          for model in weakSelf?.messages ?? [] {
            if let uid = model.message?.senderId, let (fullName, userFriend) = weakSelf?.getShowName(uid) {
              model.avatar = userFriend?.user?.avatar
              model.fullName = fullName
              model.shortName = ChatMessageHelper.getShortName(userFriend?.showName(false) ?? "")
            }
          }
          sema.signal()
        }
        sema.wait()
      }

      // 查询回复
      for model in messages {
        group.enter()
        loadReply(model) {
          group.leave()
        }
      }

      // 查找标记记录
      group.enter()
      chatRepo.searchMessagePinHistory(conversationId: weakSelf?.conversationId ?? "") { [weak self] pinList, error in

        if let pinList = pinList {
          let userIds = pinList.map(\.operatorId)
          group.enter()
          self?.loadShowName(userIds, weakSelf?.sessionId) {
            for pin in pinList {
              //            if pin.updateTime < weakSelf?.messages.first?.message?.createTime ?? 0 {
              //              break
              //            }
              for model in weakSelf?.messages ?? [] {
                if model.message?.messageClientId == pin.messageRefer?.messageClientId {
                  model.isPined = true
                  model.pinAccount = pin.operatorId
                  model.pinShowName = self?.getShowName(pin.operatorId).name
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
      getMessageReceipts(messages: messageArray) { reloadIndexs, error in
        NEALog.infoLog(
          ModuleName + " " + ChatViewModel.className(),
          desc: "CALLBACK getP2PMessageReceipt " + (error?.localizedDescription ?? "no error")
        )
        group.leave()
      }

      group.notify(queue: .main) {
        weakSelf?.delegate?.tableViewReload()
      }
    }

    // 下载语音附件
    downloadAudioFile(messages)
  }

  /// 更新消息发送者的信息
  /// - Parameter accid: 发送者 accid
  func updateMessageInfo(_ accid: String?) {
    guard let accid = accid else { return }

    let (showName, user) = getShowName(accid)
    var indexPaths = [IndexPath]()
    for (i, model) in messages.enumerated() {
      // 更新消息发送者昵称和头像
      if model.message?.senderId == accid {
        model.fullName = showName
        model.shortName = ChatMessageHelper.getShortName(showName)
        model.avatar = user?.user?.avatar
        indexPaths.append(IndexPath(row: i, section: 0))
      }

      // 更新标记者昵称
      if model.isPined, model.pinAccount == accid {
        model.pinShowName = showName
        indexPaths.append(IndexPath(row: i, section: 0))
      }
    }
    delegate?.onLoadMoreWithMessage(indexPaths)
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

    weak var weakSelf = self
    chatRepo.getMessageList(option: opt) { error, messages in
      if let messageArray = messages, messageArray.count > 0 {
        let group = DispatchGroup()

        if order == .QUERY_DIRECTION_DESC {
          weakSelf?.oldMsg = messageArray.last
        } else {
          weakSelf?.newMsg = messageArray.last
        }
        for msg in messageArray {
          // 是否需要进行重复消息过滤
          var needFilter = msg.messageServerId?.isEmpty
          if let object = msg.attachment as? V2NIMMessageNotificationAttachment,
             object.type == .MESSAGE_NOTIFICATION_TYPE_TEAM_INVITE {
            needFilter = true
          }

          if needFilter == true, let messageId = msg.messageClientId {
            if weakSelf?.filterInviteSet.contains(messageId) == true {
              continue
            } else {
              weakSelf?.filterInviteSet.insert(messageId)
            }
          }

          group.enter()
          weakSelf?.modelFromMessage(message: msg) { model in
            if weakSelf?.messages.contains(where: { $0.message?.messageClientId == model.message?.messageClientId }) == false {
              weakSelf?.messages.append(model)
            }
            group.leave()
          }
        }

        group.notify(queue: .main) {
          weakSelf?.messages.sort(by: { model1, model2 in
            (model1.message?.createTime ?? 0) < (model2.message?.createTime ?? 0)
          })

          // 显示时间
          weakSelf?.addTimeForHistoryMessage()

          // 回调消息列表
          completion(error, messageArray.count, messageArray)
        }

        // 标记已读
        weakSelf?.markRead(messages: messageArray) { error in
          NEALog.infoLog(
            ModuleName + " " + ChatViewModel.className(),
            desc: "CALLBACK markRead " + (error?.localizedDescription ?? "no error")
          )
        }
      } else {
        completion(error, 0, [])
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

  /// 发送消息
  /// - Parameters:
  ///   - message: 需要发送的消息体
  ///   - conversationId: 会话id
  ///   - completion: 回调
  open func sendMessage(message: V2NIMMessage,
                        conversationId: String? = nil,
                        _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", text: \(String(describing: message.text))")

    chatRepo.sendMessage(message: message,
                         conversationId: conversationId ?? self.conversationId) { result, error, pro in
      completion(error)
    }
  }

  /// 发送文本消息
  /// - Parameters:
  ///   - text: 文本内容
  ///   - remoteExt: 扩展字段
  ///   - conversationId: 会话 id
  ///   - completion: 完成回调
  open func sendTextMessage(text: String,
                            conversationId: String? = nil,
                            remoteExt: [String: Any]?,
                            _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", text.count: \(text.count)")
    if text.count <= 0 {
      completion(nil)
      return
    }

    let message = MessageUtils.textMessage(text: text, remoteExt: remoteExt)
    sendMessage(message: message, conversationId: conversationId) { error in
      completion(error)
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
    sendMessage(message: message, conversationId: conversationId) { error in
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
    sendMessage(message: message, conversationId: conversationId) { error in
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
                             _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ",video url.path:" + url.path)
    weak var weakSelf = self

    convertVideoToMP4(videoURL: url) { url, error in
      if let path = url?.path, let conversationId = weakSelf?.conversationId {
        let message = MessageUtils.videoMessage(filePath: path, name: name, sceneName: nil, width: width, height: height, duration: duration)
        weakSelf?.sendMessage(message: message, conversationId: conversationId) { error in
          completion(error)
        }
      } else {
        NEALog.errorLog("chat veiw model", desc: "convert mov to mp4 failed")
        completion(NSError(domain: "convert mov to mp4 failed", code: 414))
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
    let message = MessageUtils.locationMessage(lat: model.lat,
                                               lng: model.lng,
                                               address: model.title + model.address)
    message.text = model.title
    sendMessage(message: message, conversationId: conversationId) { error in
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
                            _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", filePath:\(filePath)")
    let message = MessageUtils.fileMessage(filePath: filePath, displayName: displayName, sceneName: nil)
    sendMessage(message: message, conversationId: conversationId) { error in
      completion(error)
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
    sendMessage(message: message, conversationId: conversationId) { error in
      completion(error)
    }
  }

  /// 发送拉黑提示消息
  /// - Parameter errConversationId: 会话 id
  open func sendBlackListTip(_ errConversationId: String) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + "sendBlackListTip")

    let tip = MessageUtils.tipMessage(text: chatLocalizable("black_list_tip"))
    chatRepo.saveMessageToDB(message: tip, conversationId: errConversationId) { [weak self] _, error in
      if let currentSid = self?.conversationId, currentSid == errConversationId {
        self?.modelFromMessage(message: tip) { model in
          self?.messages.append(model)
          self?.delegate?.sending(tip)
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

    weak var weakSelf = self
    // 本地消息
    if !(message.messageServerId?.isEmpty == false) {
      chatRepo.deleteMessage(message: message, onlyDeleteLocal: true) { error in
        if error == nil {
          weakSelf?.deleteMessageUpdateUI([message])
          weakSelf?.deletingMsgDic.remove(messageId)
        }
        completion(error)
      }
      return
    }

    if message.messageServerId == "0" {
      chatRepo.deleteMessage(message: message, onlyDeleteLocal: true) { error in
        if error == nil {
          weakSelf?.deleteMessageUpdateUI([message])
          weakSelf?.deletingMsgDic.remove(messageId)
        }
        completion(error)
      }
      return
    }

    chatRepo.deleteMessage(message: message, onlyDeleteLocal: false) { error in
      if error == nil {
        weakSelf?.deleteMessageUpdateUI([message])
        weakSelf?.deletingMsgDic.remove(messageId)
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

    weak var weakSelf = self
    chatRepo.deleteMessages(messages: localMsgs, onlyDeleteLocal: true) { error in
      if error == nil {
        weakSelf?.deleteMessageUpdateUI(localMsgs)
        for msg in localMsgs {
          if let msgId = msg.messageClientId {
            weakSelf?.deletingMsgDic.remove(msgId)
          }
        }
      }
      completion(error)
    }

    chatRepo.deleteMessages(messages: remoteMsgs, onlyDeleteLocal: false) { error in
      if error == nil {
        weakSelf?.deleteMessageUpdateUI(remoteMsgs)
        for msg in remoteMsgs {
          if let msgId = msg.messageClientId {
            weakSelf?.deletingMsgDic.remove(msgId)
          }
        }
      }
      completion(error)
    }
  }

  /// 回复消息
  /// - Parameters:
  ///   - message: 新生成的消息
  ///   - target: 被回复的消息
  open func replyMessage(_ message: V2NIMMessage,
                         _ target: V2NIMMessage,
                         _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageClientId:\(String(describing: message.messageClientId))")
    chatRepo.replyMessage(message: message, target: target, completion)
  }

  /// 回复消息（不使用 thread ）
  /// - Parameters:
  ///   - message: 新生成的消息
  ///   - target: 被回复的消息
  open func replyMessageWithoutThread(message: V2NIMMessage,
                                      target: V2NIMMessage,
                                      _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageClientId:\(String(describing: message.messageClientId))")
    chatRepo.replyMessageWithoutThread(message: message, conversationId: conversationId, target: target) { result, error, progress in
      completion(error)
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
      if let title = NECustomAttachment.titleOfRichText(message.attachment), !title.isEmpty {
        muta[revokeLocalMessageContent] = title
      }
      if let body = NECustomAttachment.bodyOfRichText(message.attachment), !body.isEmpty {
        muta[revokeLocalMessageContent] = body
      }
    }

    let revokeParams = V2NIMMessageRevokeParams()
    revokeParams.serverExtension = getJSONStringFromDictionary(muta)
    chatRepo.revokeMessage(message: message, revokeParams: revokeParams) { error in
      if error == nil {
        self.revokeMessageUpdateUI(message)
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
                        _ showAlias: Bool = true) -> (name: String, user: NEUserWithFriend?) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", accountId:" + accountId)
    return NEFriendUserCache.shared.getShowName(accountId, showAlias)
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
    switch model?.message?.messageType {
    case .MESSAGE_TYPE_LOCATION:
      items.append(contentsOf: [
        OperationItem.replayItem(),
        OperationItem.forwardItem(),
        pinItem,
        OperationItem.deleteItem(),
        OperationItem.selectItem(),
      ])
    case .MESSAGE_TYPE_TEXT:
      items = [
        OperationItem.copyItem(),
        OperationItem.replayItem(),
        OperationItem.forwardItem(),
        pinItem,
        OperationItem.deleteItem(),
        OperationItem.selectItem(),
      ]
    case .MESSAGE_TYPE_IMAGE, .MESSAGE_TYPE_VIDEO, .MESSAGE_TYPE_FILE:
      items = [
        OperationItem.replayItem(),
        OperationItem.forwardItem(),
        pinItem,
        OperationItem.deleteItem(),
        OperationItem.selectItem(),
      ]
    case .MESSAGE_TYPE_AUDIO:
      items = [
        OperationItem.replayItem(),
        pinItem,
        OperationItem.deleteItem(),
        OperationItem.selectItem(),
      ]
    case .MESSAGE_TYPE_CUSTOM:
      if let customType = NECustomAttachment.typeOfCustomMessage(model?.message?.attachment) {
        if customType == customRichTextType {
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
          OperationItem.selectItem(),
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
    if model?.message?.isSelf == true {
      if model?.message?.messageType == .MESSAGE_TYPE_CUSTOM,
         NECustomAttachment.dataOfCustomMessage(model?.message?.attachment) == nil {
        return items
      }
      items.append(OperationItem.recallItem())
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

      if let uid = message.senderId,
         let (fullName, user) = self?.getShowName(uid) {
        model.avatar = user?.user?.avatar
        model.fullName = fullName
        model.shortName = ChatMessageHelper.getShortName(user?.showName(false) ?? ChatMessageHelper.getShortName(fullName))
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

    if let uid = message.senderId {
      let (fullName, user) = getShowName(uid)
      model.avatar = user?.user?.avatar
      model.fullName = fullName
      model.shortName = ChatMessageHelper.getShortName(user?.showName(false) ?? ChatMessageHelper.getShortName(fullName))
    }

    if let replyModel = getReplyMessageWithoutThread(message: message) {
      model.replyedModel = replyModel
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
    var replyId: String? = message.threadReply?.messageClientId
    let replyDic = ChatMessageHelper.getReplyDictionary(message: message)
    replyId = replyDic?["idClient"] as? String
    guard let replyId = replyId, !replyId.isEmpty else {
      return nil
    }

    for model in messages {
      if model.message?.messageClientId == replyId {
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
    var replyId: String? = message.threadReply?.messageClientId
    let replyDic = ChatMessageHelper.getReplyDictionary(message: message)
    replyId = replyDic?["idClient"] as? String
    guard let replyId = replyId, !replyId.isEmpty else {
      completion(nil)
      return
    }

    // 先去已加载的消息中查
    for model in messages {
      if model.message?.messageClientId == replyId {
        model.isReplay = true
        completion(model)
        return
      }
    }

    // 已加载的消息中没有则去远端查
    chatRepo.getMessageListByIds([replyId]) { [weak self] messages, error in
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
        var replyId: String? = model.message?.threadReply?.messageClientId
        if let remoteExt = getDictionaryFromJSONString(model.message?.serverExtension ?? ""),
           let yxReplyMsg = remoteExt[keyReplyMsgKey] as? [String: Any] {
          replyId = yxReplyMsg["idClient"] as? String
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
        var replyId: String? = model.message?.threadReply?.messageClientId
        if let remoteExt = getDictionaryFromJSONString(model.message?.serverExtension ?? ""),
           let yxReplyMsg = remoteExt[keyReplyMsgKey] as? [String: Any] {
          replyId = yxReplyMsg["idClient"] as? String
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

  /// 逐条转发消息
  /// - Parameters:
  ///   - forwardMessages: 需要逐条转发的消息列表
  ///   - conversationId: 转发的会话 id
  ///   - comment: 留言
  ///   - completion: 完成回调
  open func forwardMessage(_ forwardMessages: [V2NIMMessage],
                           _ conversationId: String,
                           _ comment: String?,
                           _ completion: @escaping (Error?) -> Void) {
    for message in forwardMessages {
      let forwardMessage = MessageUtils.forwardMessage(message: message)
      ChatMessageHelper.clearForwardAtMark(forwardMessage)
      chatRepo.sendMessage(message: forwardMessage, conversationId: conversationId) { result, error, pro in
      }
    }
    if let text = comment, !text.isEmpty {
      sendTextMessage(text: text, conversationId: conversationId, remoteExt: nil, completion)
    } else {
      completion(nil)
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
                                toconversationId: String,
                                users: [V2NIMUser]? = nil,
                                depth: Int = 0,
                                comment: String?,
                                _ completion: @escaping (Error?) -> Void) {
    if forwardMessages.count <= 0 {
      if let text = comment, !text.isEmpty {
        sendTextMessage(text: text, conversationId: toconversationId, remoteExt: nil, completion)
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
      if var filePath = NEPathUtils.getDirectoryForDocuments(dir: "NEIMUIKit/file/") {
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
            data["sessionId"] = V2NIMConversationIdUtil.conversationTargetId(toconversationId)
            data["url"] = url
            data["md5"] = md5
            data["depth"] = depth
            data["abstracts"] = abstracts
            data["sessionName"] = ChatMessageHelper.getSessionName(conversationId: fromSession, showAlias: false)

            var jsonData = [String: Any]()
            jsonData["data"] = data
            jsonData["messageType"] = "custom"
            jsonData["type"] = customMultiForwardType

            // 转发给好友
            if let users = users {
              for user in users {
                if let uid = user.accountId, let cid = V2NIMConversationIdUtil.p2pConversationId(uid) {
                  self?.sendCustomMessage(text: "[\(chatLocalizable("chat_history"))]",
                                          rawAttachment: getJSONStringFromDictionary(jsonData), conversationId: cid) { error in
                    if let text = comment, !text.isEmpty {
                      self?.sendTextMessage(text: text, conversationId: cid, remoteExt: nil, completion)
                    }
                    completion(error)
                  }
                }
              }
              return
            }

            // 转发到群聊
            self?.sendCustomMessage(text: "[\(chatLocalizable("chat_history"))]",
                                    rawAttachment: getJSONStringFromDictionary(jsonData), conversationId: toconversationId) { error in
              if let text = comment, !text.isEmpty {
                self?.sendTextMessage(text: text, conversationId: toconversationId, remoteExt: nil, completion)
              }
              completion(error)
            }
          }
        }
      }
    }
  }

  /// 转发消息给好友
  /// - Parameters:
  ///   - users: 好友列表
  ///   - isMultiForward: 是否是合并转发
  ///   - depth: 合并转发深度
  ///   - comment: 留言
  ///   - completion: 完成回调
  open func forwardUserMessage(_ users: [V2NIMUser],
                               _ isMultiForward: Bool,
                               _ depth: Int,
                               _ comment: String?,
                               _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messages.count: \(messages.count)")

    // 排序（发送时间正序）
    let forwardMessages = selectedMessages.sorted { msg1, msg2 in
      msg1.createTime < msg2.createTime
    }

    if isMultiForward {
      forwardMultiMessage(forwardMessages: forwardMessages,
                          toconversationId: conversationId,
                          users: users,
                          depth: depth,
                          comment: comment,
                          completion)
    } else {
      for user in users {
        if let uid = user.accountId, let conversationId = V2NIMConversationIdUtil.p2pConversationId(uid) {
          forwardMessage(forwardMessages, conversationId, comment, completion)
        }
      }
    }
  }

  /// 转发消息到群聊
  /// - Parameters:
  ///   - team: 群聊
  ///   - isMultiForward: 是否是合并转发
  ///   - depth: 合并转发深度
  ///   - comment: 留言
  ///   - completion: 完成回调
  open func forwardTeamMessage(_ team: V2NIMTeam,
                               _ isMultiForward: Bool,
                               _ depth: Int,
                               _ comment: String?,
                               _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messages.count: \(messages.count)")
    guard let conversationId = V2NIMConversationIdUtil.teamConversationId(team.teamId) else {
      return
    }

    // 排序（发送时间正序）
    let forwardMessages = selectedMessages.sorted { msg1, msg2 in
      msg1.createTime < msg2.createTime
    }

    if isMultiForward {
      forwardMultiMessage(forwardMessages: forwardMessages,
                          toconversationId: conversationId,
                          depth: depth,
                          comment: comment,
                          completion)
    } else {
      forwardMessage(selectedMessages, conversationId, comment, completion)
    }
  }

  /// 标记消息
  /// - Parameters:
  ///   - message: 消息
  ///   - completion: 完成回调
  open func addPinMessage(message: V2NIMMessage,
                          _ completion: @escaping (Error?, Int) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageClientId: \(String(describing: message.messageClientId))")
    chatRepo.addMessagePin(message: message, serverExtension: "") { [weak self] error in
      var index = -1
      if error != nil {
        completion(error, index)
      } else {
        for (i, model) in (self?.messages ?? []).enumerated() {
          if message.messageClientId == model.message?.messageClientId, !(self?.messages[i].isPined == true) {
            self?.messages[i].isPined = true
            self?.messages[i].pinAccount = IMKitClient.instance.account()
            self?.messages[i].pinShowName = self?.getShowName(IMKitClient.instance.account()).name
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
    chatRepo.removeMessagePin(messageRefer: message, serverExtension: "") { [weak self] error in
      if error != nil {
        completion(error, -1)
      } else {
        let index = self?.removeLocalPinMessage(message) ?? -1
        completion(nil, index)
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

    // 拉黑消息避免重复发送
    if message.messageType == .MESSAGE_TYPE_TIP,
       ChatDeduplicationHelper.instance.isMessageSended(messageId: message.messageClientId ?? "") {
      return
    }

    // 自定义消息发送之前的处理
    if newMsg == nil {
      newMsg = message
    }

    var isResend = false
    for (i, msg) in messages.enumerated() {
      if message.messageClientId == msg.message?.messageClientId {
        messages[i].message = message
        isResend = true
        break
      }
    }

    if !isResend {
      let model = modelFromMessage(message: message)
      ChatMessageHelper.addTimeMessage(model, messages.last)
      messages.append(model)
    }

    delegate?.sending(message)
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

    for (i, msg) in messages.enumerated() {
      if message.messageClientId == msg.message?.messageClientId {
        messages[i].message = message
        break
      }
    }

    delegate?.sendSuccess(message)
  }

  /// 消息发送失败
  /// - Parameters:
  ///   - message: 消息
  ///   - error: 错误信息
  open func sendMsgFailed(_ message: V2NIMMessage, _ error: Error?) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", error: \(String(describing: error))")

    // 判断发送失败原因是否是因为在黑名单中
    if error != nil {
      if let err = error as NSError? {
        if err.code == inBlackListCode, let conversationId = message.conversationId {
          weak var weakSelf = self
          DispatchQueue.main.async {
            weakSelf?.sendBlackListTip(conversationId)
            if conversationId == weakSelf?.conversationId {
              weakSelf?.delegate?.sendSuccess(message)
            }
          }
        }
      }
    }

    delegate?.sendSuccess(message)
  }

  //    MARK: - NEChatListener

  /// 收到消息
  /// - Parameter messages: 消息列表
  public func onReceiveMessages(_ messages: [V2NIMMessage]) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messages.count: \(messages.count), first.messageID: \(messages.first?.messageClientId ?? "")")

    for msg in messages {
      guard let messageId = msg.messageClientId,
            V2NIMConversationIdUtil.conversationTargetId(msg.conversationId ?? "") == sessionId else {
        return
      }

      if !(msg.messageServerId?.isEmpty == false), msg.messageType != .MESSAGE_TYPE_CUSTOM {
        continue
      }

      if filterInviteSet.contains(messageId) {
        continue
      } else {
        filterInviteSet.insert(messageId)
      }

      newMsg = msg

      modelFromMessage(message: msg) { [weak self] model in
        ChatMessageHelper.addTimeMessage(model, self?.messages.last)
        self?.downloadAudioFile([model])
        self?.loadReply(model) {
          self?.messages.append(model)
          self?.messages.sort { m1, m2 in
            (m1.message?.createTime ?? 0) < (m2.message?.createTime ?? 0)
          }
          self?.delegate?.onRecvMessages(messages)
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

      for model in messages {
        if let msg = model.message, msg.messageClientId == revokeNoti.messageRefer?.messageClientId {
          model.message!.localExtension = revokeNoti.serverExtension
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

          if let _ = getShowName(pinID).user {
            messages[i].pinShowName = getShowName(pinID).name
          } else {
            loadShowName([pinID], sessionId) { [weak self] in
              self?.messages[i].pinShowName = self?.getShowName(pinID).name
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

  /// 消息发送进度
  /// - Parameters:
  ///   - message: 消息
  ///   - progress: 进度
  public func sendMessageProgress(_ message: V2NIMMessage, _ progress: UInt) {
    if progress == 0 {
      // 消息即将发送
      sendingMsg(message)
    }
  }

  /// 消息发送成功
  /// - Parameter result: 成功结果
  public func sendMessageSuccess(_ result: V2NIMSendMessageResult?) {
    if let msg = result?.message {
      sendMsgSuccess(msg)
    }
  }

  /// 消息发送失败
  /// - Parameters:
  ///   - message: 消息
  ///   - error: 错误信息
  public func sendMessageFailed(_ message: V2NIMMessage, _ error: NSError) {
    sendMsgFailed(message, error)
  }
}
