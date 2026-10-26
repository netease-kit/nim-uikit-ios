// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NIMSDK

public let atAllKey = "ait_all"
public let yxAitMsg = "yxAitMsg"
public let AtMessageChangeNoti = "at_message_change_noti"

@objcMembers
open class AtMessageModel: NSObject {
  public var messageId: String?
  public var messageTime: NSNumber?
}

@objcMembers
open class AtMEMessageRecord: NSObject {
  public var atMessages = [String: NSNumber]()
  public var lastTime: NSNumber?
  public var isRead = false
}

@objcMembers
open class NEAtMessageManager: NSObject, NEIMKitClientListener, NEChatListener {
  public static var instance: NEAtMessageManager?
  private let workQueue = DispatchQueue(label: "AtMessageWorkQueue")
  private let lock = NSLock()
  private var atMessageDic = [String: AtMEMessageRecord]()
  private var currentAccid = ""

  private func cacheFilePath(in documentsDirectory: URL) -> URL {
    documentsDirectory
      .appendingPathComponent(imkitDir)
      .appendingPathComponent("\(currentAccid)_at_message_cloud.plist")
  }

  private func legacyCacheFilePath(in documentsDirectory: URL) -> URL {
    documentsDirectory
      .appendingPathComponent(imkitDir)
      .appendingPathComponent("\(currentAccid)_at_message.plist")
  }

  override private init() {
    super.init()
    ChatRepo.shared.addChatListener(self)
    IMKitClient.instance.addLoginListener(self)
  }

  deinit {
    ChatRepo.shared.removeChatListener(self)
    IMKitClient.instance.removeLoginListener(self)
  }

  /// 初始化
  public static func setupInstance() {
    if NEAtMessageManager.instance == nil {
      NEAtMessageManager.instance = NEAtMessageManager()
    }
  }

  /// 登录状态变更
  /// - Parameter status: 登录状态
  open func onLoginStatus(_ status: V2NIMLoginStatus) {
    workQueue.async { [weak self] in
      guard let self else { return }
      if status == .LOGIN_STATUS_LOGINED {
        NEALog.infoLog(self.className(), desc: "login ok")
        self.currentAccid = IMKitClient.instance.account()
        self.setMessageDic([:])
        self.loadCacheFromDocument()
      } else if status == .LOGIN_STATUS_LOGOUT {
        let hadRecords = !self.getMessageDic().isEmpty
        self.currentAccid = ""
        self.setMessageDic([:])
        if hadRecords {
          self.atMessageChangeNoti()
        }
      }
    }
  }

  /// 数据同步回调
  /// - Parameter type: 同步类型
  /// - Parameter state: 同步状态
  /// - Parameter error: 错误信息
  open func onDataSync(_ type: V2NIMDataSyncType, state: V2NIMDataSyncState, error: V2NIMError?) {
    if state == .DATA_SYNC_STATE_COMPLETED {
      if currentAccid.count <= 0 {
        currentAccid = IMKitClient.instance.account()
      }
    } else if state == .DATA_SYNC_STATE_SYNCING {
      NEALog.infoLog(className(), desc: "roaming messages start")
    } else if state == .DATA_SYNC_STATE_WAITING {
      NEALog.infoLog(className(), desc: "roaming messages waitting")
    }
  }

  /// 获取当前at消息内存缓存
  private func getMessageDic() -> [String: AtMEMessageRecord] {
    lock.lock()
    let result = atMessageDic
    lock.unlock()
    return result
  }

  private func copiedMessageDic() -> [String: AtMEMessageRecord] {
    lock.lock()
    var result = [String: AtMEMessageRecord]()
    for (conversationId, record) in atMessageDic {
      let recordCopy = AtMEMessageRecord()
      recordCopy.isRead = record.isRead
      recordCopy.lastTime = record.lastTime
      recordCopy.atMessages = record.atMessages
      result[conversationId] = recordCopy
    }
    lock.unlock()
    return result
  }

  /// 设置at消息缓存
  /// - Parameter dic: at消息缓存
  private func setMessageDic(_ dic: [String: AtMEMessageRecord]) {
    lock.lock()
    atMessageDic = dic
    lock.unlock()
  }

  /// 判断是否是当前用户
  ///  - Parameter conversationId: 会话id
  ///  - Returns: 是否是当前用户
  open func isAtCurrentUser(conversationId: String) -> Bool {
    let dic = getMessageDic()

    if let model = dic[conversationId], model.isRead == false {
      NEALog.infoLog(className(), desc: "read == false")
      return true
    }
    return false
  }

  /// 清理at消息记录
  /// - Parameter conversationId: 会话id
  open func clearAtRecord(_ conversationId: String) {
    NEALog.infoLog(className(), desc: "clearAtRecord session id : \(conversationId)")
    weak var weakSelf = self
    workQueue.async {
      guard let dic = weakSelf?.copiedMessageDic() else {
        return
      }
      if let model = dic[conversationId], !model.isRead || !model.atMessages.isEmpty {
        model.isRead = true
        model.atMessages.removeAll()
        weakSelf?.setMessageDic(dic)
        weakSelf?.writeCacheToDocument(dictionary: dic)
        weakSelf?.atMessageChangeNoti()
      }
    }
  }

  /// 过滤 at 消息
  /// - Parameter messages: 消息列表
  open func filterAtMessage(messages: [V2NIMMessage]) {
    NEALog.infoLog(className(), desc: "at manager filterAtMessage : \(messages.count)")
    guard IMKitConfigCenter.shared.enableAtMessage, !messages.isEmpty else { return }
    weak var weakSelf = self
    workQueue.async {
      if let result = weakSelf?.filterAtMessageInWorkqueue(messages: messages), result == true {
        weakSelf?.atMessageChangeNoti()
        if let dic = weakSelf?.getMessageDic() {
          weakSelf?.writeCacheToDocument(dictionary: dic)
        }
      }
    }
  }

  /// 开启遍历漫游消息任务
  open func startFilterRoamingMessagesTask() {
    weak var weakSelf = self
    workQueue.async {
      weakSelf?.startFilterRoamingMessagesTaskInWorkqueue()
    }
  }

  @discardableResult
  private func filterAtMessageInWorkqueue(messages: [V2NIMMessage]) -> Bool {
    let currentAccid = IMKitClient.instance.account()
    weak var weakSelf = self
    var isExistAtMessage = false
    var temDic = copiedMessageDic()

    for message in messages {
      if let serverExtension = message.serverExtension,
         let remoteExt = NECommonUtil.getDictionaryFromJSONString(serverExtension),
        let dic = remoteExt[yxAitMsg] as? [String: Any] {
        if dic[atAllKey] != nil, message.senderId != currentAccid {
          if weakSelf?.addAtRecordWithCompare(message: message, record: &temDic) == true {
            isExistAtMessage = true
          }
          continue
        }
        if dic[currentAccid] != nil {
          if weakSelf?.addAtRecordWithCompare(message: message, record: &temDic) == true {
            isExistAtMessage = true
          }
          continue
        }
      }
    }
    setMessageDic(temDic)
    return isExistAtMessage
  }

  private func startFilterRoamingMessagesTaskInWorkqueue() {
    weak var weakSelf = self

    getAllConversation { conversations, error in
      guard error == nil else { return }
      let workingGroup = DispatchGroup()
      let workingQueue = DispatchQueue(label: "at_message_queue")
      guard var temDic = weakSelf?.copiedMessageDic() else {
        return
      }
      guard let accid = weakSelf?.currentAccid else {
        return
      }
      var isExistAtMessage = false
      for conversation in conversations {
        if conversation.type != .CONVERSATION_TYPE_TEAM {
          continue
        }
        workingGroup.enter()
        let option = V2NIMMessageListOption()
        option.limit = 100
        option.conversationId = conversation.conversationId
        option.strictMode = false
        ChatProvider.shared.getMessageList(option: option) { messages, v2Error in
          workingQueue.async {
            defer { workingGroup.leave() }
            guard v2Error == nil else { return }
            messages?.forEach { message in
              if let serverExtension = message.serverExtension, let remoteExt = NECommonUtil.getDictionaryFromJSONString(serverExtension), let dic = remoteExt[yxAitMsg] as? [String: Any] {
                if dic[atAllKey] != nil, message.isSelf == false {
                  if weakSelf?.addAtRecordWithCompare(message: message, record: &temDic) == true {
                    isExistAtMessage = true
                  }
                  return
                }
                if dic[accid] != nil {
                  if weakSelf?.addAtRecordWithCompare(message: message, record: &temDic) == true {
                    isExistAtMessage = true
                  }
                  return
                }
              }
            }
          }
        }
      }

      workingGroup.notify(queue: weakSelf?.workQueue ?? workingQueue) {
        if isExistAtMessage == true {
          weakSelf?.setMessageDic(temDic)
          weakSelf?.writeCacheToDocument(dictionary: temDic)
          weakSelf?.atMessageChangeNoti()
        }
      }
    }
  }

  /// at 消息记录写文件缓存
  private func writeCacheToDocument(dictionary: [String: AtMEMessageRecord]) {
    if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
      let filePath = cacheFilePath(in: documentsDirectory)
      NEALog.infoLog(className(), desc: "writeCacheToDocument path : \(filePath)")
      do {
        var jsonObject = [String: Any]()
        for (key, value) in dictionary {
          if let jsonValue = value.yx_modelToJSONObject() {
            jsonObject[key] = jsonValue
          }
        }

        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
        try jsonData.write(to: filePath)
        print("write cache success")
      } catch {
        NEALog.infoLog(className(), desc: "write cache error : \(error.localizedDescription)")
      }
    }
  }

  /// 加载本地缓存文件
  private func loadCacheFromDocument() {
    NEALog.infoLog(className(), desc: "loadCacheFromDocument")
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      return
    }

    weak var weakSelf = self
    let documentDir = documentsDirectory.appendingPathComponent(imkitDir)
    if FileManager.default.fileExists(atPath: documentDir.path) == false {
      do {
        try FileManager.default.createDirectory(at: documentDir, withIntermediateDirectories: false)
      } catch {
        NEALog.infoLog(className(), desc: "create dir error : \(error.localizedDescription)")
      }
    }

    let filePath = cacheFilePath(in: documentsDirectory)
    if FileManager.default.fileExists(atPath: filePath.path) == false {
      let success = FileManager.default.createFile(atPath: filePath.path, contents: nil)
      NEALog.infoLog(className(), desc: "create file success:  \(success) path: \(filePath.path)")
    }

    var sourceFilePath = filePath
    if let data = try? Data(contentsOf: filePath), data.isEmpty {
      let legacyFilePath = legacyCacheFilePath(in: documentsDirectory)
      if let legacyData = try? Data(contentsOf: legacyFilePath), legacyData.isEmpty == false {
        sourceFilePath = legacyFilePath
      }
    }

    do {
      let data = try Data(contentsOf: sourceFilePath)
      guard data.isEmpty == false else {
        return
      }
      if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: Any]] {
        var temdDic = weakSelf?.copiedMessageDic()
        for (key, value) in jsonObject {
          if let model = AtMEMessageRecord.yx_model(with: value) {
            temdDic?[key] = model
            if let dic = jsonObject[key], let isRead = dic[#keyPath(AtMEMessageRecord.isRead)] as? Bool {
              model.isRead = isRead
              if let atMessagesJsonObject = dic[#keyPath(AtMEMessageRecord.atMessages)] {
                if let atMessages = NSDictionary.yx_modelDictionary(with: NSDictionary.self, json: atMessagesJsonObject) as? [String: NSNumber] {
                  model.atMessages = atMessages
                }
              }
            }
          }
        }
        if let tem = temdDic {
          weakSelf?.setMessageDic(tem)
          if sourceFilePath != filePath {
            weakSelf?.writeCacheToDocument(dictionary: tem)
          }
          weakSelf?.atMessageChangeNoti()
        }
      }
    } catch {
      NEALog.infoLog(className(), desc: "convert to message data to json object error : \(error.localizedDescription)")
    }
  }

  /// 移除at记录
  /// - Parameter message: 消息
  /// - Parameter record: at 消息记录缓存
  private func removeRecord(message: V2NIMMessage, record: inout [String: AtMEMessageRecord]) -> Bool {
    var didRemove = false
    if let atMeRecord = record[message.conversationId ?? ""] {
      if atMeRecord.atMessages[message.messageClientId ?? ""] != nil {
        atMeRecord.atMessages.removeValue(forKey: message.messageClientId ?? "")
        didRemove = true
        if atMeRecord.atMessages.count <= 0 {
          atMeRecord.isRead = true
          atMeRecord.lastTime = nil
        } else {
          atMeRecord.lastTime = atMeRecord.atMessages.values.max { $0.doubleValue < $1.doubleValue }
        }
      }
    }
    return didRemove
  }

  /// 添加at消息记录(有时间错比较)
  /// - Parameter message: 消息
  /// - Parameter record: at 消息记录缓存
  private func addAtRecordWithCompare(message: V2NIMMessage, record: inout [String: AtMEMessageRecord]) -> Bool {
    guard let conversationId = message.conversationId,
          let messageClientId = message.messageClientId,
          !messageClientId.isEmpty else {
      NEALog.infoLog(className(), desc: #function + " addAtRecord conversationId nil ")
      return false
    }

    let semaphore = DispatchSemaphore(value: 0)
    var compareTimestap: Double = 0
    ConversationRepo.shared.getConversationReadTime(conversationId) { timestap, error in
      if error != nil {
        NEALog.infoLog(NEAtMessageManager.className(), desc: #function + "getConversationReadTime error : \(error?.localizedDescription ?? "")")
      }

      if let t = timestap {
        compareTimestap = t
        NEALog.infoLog(NEAtMessageManager.className(), desc: #function + "getConversationReadTime time \(t)")
      }
      semaphore.signal()
    }

    semaphore.wait()

    guard message.createTime > compareTimestap else { return false }

    let atMeRecord = record[conversationId] ?? AtMEMessageRecord()
    guard atMeRecord.atMessages[messageClientId] == nil else { return false }
    atMeRecord.isRead = false
    atMeRecord.atMessages[messageClientId] = NSNumber(value: message.createTime)
    atMeRecord.lastTime = NSNumber(value: max(atMeRecord.lastTime?.doubleValue ?? 0, message.createTime))
    record[conversationId] = atMeRecord
    return true
  }

  /// 添加at消息记录
  /// - Parameter message: 消息
  /// - Parameter record: at 消息记录缓存
  private func addAtRecord(message: V2NIMMessage, record: inout [String: AtMEMessageRecord]) {
    if let atMeRecord = record[message.conversationId ?? ""] {
      let lastTime = atMeRecord.lastTime?.doubleValue ?? 0
      if lastTime < message.createTime {
        let atMessage = AtMessageModel()
        atMessage.messageId = message.messageClientId
        atMessage.messageTime = NSNumber(value: message.createTime)
        atMeRecord.lastTime = NSNumber(value: message.createTime)
        atMeRecord.atMessages[message.messageClientId ?? ""] = NSNumber(value: message.createTime)
        atMeRecord.isRead = false
        if let conversationId = message.conversationId {
          record[conversationId] = atMeRecord
        }
      }
    } else {
      let atMeRecord = AtMEMessageRecord()
      let atMessage = AtMessageModel()
      atMessage.messageId = message.messageClientId
      atMessage.messageTime = NSNumber(value: message.createTime)
      atMeRecord.lastTime = NSNumber(value: message.createTime)
      atMeRecord.atMessages[message.messageClientId ?? ""] = NSNumber(value: message.createTime)
      atMeRecord.isRead = false
      if let conversationId = message.conversationId {
        record[conversationId] = atMeRecord
      }
    }
  }

  /// 获取at消息变更通知
  /// - Parameter isCurrentThread: 是否在当前线程发送
  private func atMessageChangeNoti(_ isCurrentThread: Bool = false) {
    if isCurrentThread == false {
      DispatchQueue.main.async {
        NotificationCenter.default.post(name: Notification.Name(AtMessageChangeNoti), object: nil)
      }
    } else {
      NotificationCenter.default.post(name: Notification.Name(AtMessageChangeNoti), object: nil)
    }
  }

  /// 获取所有会话
  ///  - Parameter conversations: 会话列表
  ///  - Parameter offset: 偏移量
  ///  - Parameter completion: 完成回调
  private func getAllConversation(_ conversations: [V2NIMConversation] = [],
                                  _ offset: Int64 = 0,
                                  _ completion: @escaping ([V2NIMConversation], NSError?) -> Void) {
    let limit = 20
    var temConversations = conversations
    ConversationProvider.shared.getConversationList(offset, limit) { [weak self] result, error in
      if let err = error {
        completion(temConversations, err)
      } else {
        if let datas = result?.conversationList {
          temConversations.append(contentsOf: datas)
        }
        if result?.finished == false, let nextToken = result?.offset {
          self?.getAllConversation(temConversations, nextToken, completion)
        } else {
          completion(temConversations, nil)
        }
      }
    }
  }

  /// 撤回消息回调
  /// - Parameter revokeNotifications:  撤回通知
  open func onMessageRevokeNotifications(_ revokeNotifications: [V2NIMMessageRevokeNotification]) {
    var messageRefers = [V2NIMMessageRefer]()
    for notification in revokeNotifications {
      if let messageRefer = notification.messageRefer {
        messageRefers.append(messageRefer)
      }
    }
    if !messageRefers.isEmpty {
      removeRevokeAtMessage(messages: messageRefers)
    }
  }

  /// 移除at消息记录
  /// - Parameter messages: 消息列表
  open func removeRevokeAtMessage(messages: [V2NIMMessageRefer]) {
    weak var weakSelf = self
    workQueue.async {
      weakSelf?.removeRevokeAtMessageInWorkqueue(messageRefers: messages)
    }
  }

  /// 遍历所有撤回消息判断是否要清除at消息标识(会发送通知通知会话列表)
  /// - Parameter messageRefers: 消息索引列表
  private func removeRevokeAtMessageInWorkqueue(messageRefers: [V2NIMMessageRefer]) {
    let currentAccid = IMKitClient.instance.account()
    weak var weakSelf = self
    var isAtMessageChange = false
    var temDic = copiedMessageDic()
    for messageRefer in messageRefers {
      if messageRefer.senderId != currentAccid {
        let removeRetResult = weakSelf?.removeRecordWithMessageref(messageRefer: messageRefer, record: &temDic)
        if removeRetResult == true {
          isAtMessageChange = true
        }
      }
    }
    if isAtMessageChange == true {
      setMessageDic(temDic)
      atMessageChangeNoti()
      weakSelf?.writeCacheToDocument(dictionary: temDic)
    }
  }

  /// 移除at记录(根据消息指针类，因为撤回的时候拿不到消息对象)
  /// - Parameter messageRefer: 消息索引
  /// - Parameter record: at 消息记录缓存
  private func removeRecordWithMessageref(messageRefer: V2NIMMessageRefer, record: inout [String: AtMEMessageRecord]) -> Bool {
    var didRemove = false
    if let atMeRecord = record[messageRefer.conversationId ?? ""] {
      if atMeRecord.atMessages[messageRefer.messageClientId ?? ""] != nil {
        atMeRecord.atMessages.removeValue(forKey: messageRefer.messageClientId ?? "")
        didRemove = true
        if atMeRecord.atMessages.count <= 0 {
          atMeRecord.isRead = true
          atMeRecord.lastTime = nil
        } else {
          atMeRecord.lastTime = atMeRecord.atMessages.values.max { $0.doubleValue < $1.doubleValue }
        }
      }
    }
    return didRemove
  }

  /// 收到消息回调
  /// - Parameter messages: 消息列表
  open func onReceiveMessages(_ messages: [V2NIMMessage]) {
    filterAtMessage(messages: messages)
  }
}
