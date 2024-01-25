// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
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
open class NEAtMessageManager: NSObject, NIMChatManagerDelegate, NIMLoginManagerDelegate {
  public static var instance: NEAtMessageManager?
  private let workQueue = DispatchQueue(label: "AtMessageWorkQueue")
  private let lock = NSLock()
  private var atMessageDic = [String: AtMEMessageRecord]()
  private var currentAccid = ""

  override private init() {
    super.init()
    NIMSDK.shared().chatManager.add(self)
    NIMSDK.shared().loginManager.add(self)
  }

  deinit {
    NIMSDK.shared().chatManager.remove(self)
    NIMSDK.shared().loginManager.remove(self)
  }

  public static func setupInstance() {
    NEAtMessageManager.instance = NEAtMessageManager()
  }

  open func onLogin(_ step: NIMLoginStep) {
    if step == .loginOK {
      NELog.infoLog(className(), desc: "login ok")
      currentAccid = NIMSDK.shared().loginManager.currentAccount()
      weak var weakSelf = self
      let newDic = [String: AtMEMessageRecord]()
      setMessageDic(newDic)
      workQueue.async {
        weakSelf?.loadCacheFromDocument()
      }
    } else if step == .syncing {
      NELog.infoLog(className(), desc: "roaming messages start")
    } else if step == .syncOK {
      NELog.infoLog(className(), desc: "roaming messages finish")
      if currentAccid.count <= 0 {
        currentAccid = NIMSDK.shared().loginManager.currentAccount()
      }
      startFilterRoamingMessagesTask()
    }
  }

  open func onRecvRevokeMessageNotification(_ notification: NIMRevokeMessageNotification) {
    guard let msg = notification.message else {
      return
    }
    removeRevokeAtMessage(messages: [msg])
  }

  private func getMessageDic() -> [String: AtMEMessageRecord] {
    lock.lock()
    let result = atMessageDic
    lock.unlock()
    return result
  }

  private func setMessageDic(_ dic: [String: AtMEMessageRecord]) {
    lock.lock()
    atMessageDic = dic
    lock.unlock()
  }

  open func isAtCurrentUser(sessionId: String) -> Bool {
    let dic = getMessageDic()
    NELog.infoLog(className(), desc: "session id : \(sessionId)")
    NELog.infoLog(className(), desc: "dic : \(dic)")
    if let model = dic[sessionId], model.isRead == false {
      return true
    }
    return false
  }

  open func clearAtRecord(_ sessionId: String) {
    weak var weakSelf = self
    workQueue.async {
      guard let dic = weakSelf?.getMessageDic() else {
        return
      }
      if let model = dic[sessionId] {
        model.isRead = true
        model.atMessages.removeAll()
        weakSelf?.setMessageDic(dic)
        weakSelf?.writeCacheToDocument(dictionary: dic)
      }
    }
  }

  open func filterAtMessage(messages: [NIMMessage]) {
    NELog.infoLog(className(), desc: "at manager filterAtMessage : \(messages.count)")
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

  open func removeRevokeAtMessage(messages: [NIMMessage]) {
    weak var weakSelf = self
    workQueue.async {
      weakSelf?.removeRevokeAtMessageInWorkqueue(messages: messages)
    }
  }

  open func startFilterRoamingMessagesTask() {
    weak var weakSelf = self
    workQueue.async {
      weakSelf?.startFilterRoamingMessagesTaskInWorkqueue()
    }
  }

  private func removeRevokeAtMessageInWorkqueue(messages: [NIMMessage]) {
    let currentAccid = NIMSDK.shared().loginManager.currentAccount()
    weak var weakSelf = self
    var isAtMessageChange = false
    var temDic = getMessageDic()
    messages.forEach { message in
      if message.status == .read {
        return
      }
      if let remoteExt = message.remoteExt, let dic = remoteExt[yxAitMsg] as? [String: AnyObject] {
        if dic[atAllKey] != nil, message.from != currentAccid {
          isAtMessageChange = weakSelf?.removeRecord(message: message, record: &temDic) ?? false
          return
        }
        if dic[currentAccid] != nil {
          isAtMessageChange = weakSelf?.removeRecord(message: message, record: &temDic) ?? false
          return
        }
      }
    }
    if isAtMessageChange == true {
      atMessageChangeNoti()
    }
  }

  @discardableResult
  private func filterAtMessageInWorkqueue(messages: [NIMMessage]) -> Bool {
    let currentAccid = NIMSDK.shared().loginManager.currentAccount()
    weak var weakSelf = self
    var isExistAtMessage = false
    var temDic = getMessageDic()

    messages.forEach { message in
      if message.status == .read {
        return
      }
      if let remoteExt = message.remoteExt, let dic = remoteExt[yxAitMsg] as? [String: AnyObject] {
        if dic[atAllKey] != nil, message.from != currentAccid {
          weakSelf?.addAtRecord(message: message, record: &temDic)
          isExistAtMessage = true
          return
        }
        if dic[currentAccid] != nil {
          weakSelf?.addAtRecord(message: message, record: &temDic)
          isExistAtMessage = true
          return
        }
      }
    }
    setMessageDic(temDic)
    return isExistAtMessage
  }

  private func startFilterRoamingMessagesTaskInWorkqueue() {
    let sessions = NIMSDK.shared().conversationManager.allRecentSessions()
    NELog.infoLog(className(), desc: "startFilterRoamingMessagesTaskInWorkqueue session count : \(sessions?.count ?? 0)")
    var temDic = getMessageDic()
    weak var weakSelf = self
    var isExistAtMessage = false
    print("recent session filter at message")
    sessions?.forEach { recentSession in
      if recentSession.unreadCount <= 0 {
        return
      }
      if let session = recentSession.session {
        let messages = NIMSDK.shared().conversationManager.messages(in: session, message: nil, limit: 100)
        messages?.forEach { message in
          if message.status == .read {
            return
          }
          if let remoteExt = message.remoteExt, let dic = remoteExt[yxAitMsg] as? [String: AnyObject] {
            if dic[atAllKey] != nil, message.from != currentAccid {
              weakSelf?.addAtRecord(message: message, record: &temDic)
              isExistAtMessage = true
              return
            }
            if dic[currentAccid] != nil {
              weakSelf?.addAtRecord(message: message, record: &temDic)
              isExistAtMessage = true
              return
            }
          }
        }
      }
    }
    if isExistAtMessage == true {
      writeCacheToDocument(dictionary: temDic)
      setMessageDic(temDic)
      atMessageChangeNoti()
    }
  }

  private func writeCacheToDocument(dictionary: [String: AtMEMessageRecord]) {
    if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
      let filePath = documentsDirectory.appendingPathComponent("NEIMUIKit/\(currentAccid)_at_message.plist")
      NELog.infoLog(className(), desc: "writeCacheToDocument path : \(filePath)")
      do {
        var jsonObject = [String: Any]()
        dictionary.forEach { (key: String, value: AtMEMessageRecord) in
          if let jsonValue = value.yx_modelToJSONObject() {
            jsonObject[key] = jsonValue
          }
        }

        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
        try jsonData.write(to: filePath)
      } catch {
        NELog.infoLog(className(), desc: "write cache error : \(error.localizedDescription)")
      }
    }
  }

  private func loadCacheFromDocument() {
    NELog.infoLog(className(), desc: "loadCacheFromDocument")
    if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
      weak var weakSelf = self
      let documentDir = documentsDirectory.appendingPathComponent("NEIMUIKit/")
      if FileManager.default.fileExists(atPath: documentDir.path) == false {
        do {
          try FileManager.default.createDirectory(at: documentDir, withIntermediateDirectories: false)
        } catch {
          NELog.infoLog(className(), desc: "create dir error : \(error.localizedDescription)")
        }
      }
      let filePath = documentDir.appendingPathComponent("\(currentAccid)_at_message.plist")
      if FileManager.default.fileExists(atPath: filePath.path) == false {
        let success = FileManager.default.createFile(atPath: filePath.absoluteString, contents: nil)
        NELog.infoLog(className(), desc: "create file success:  \(success) path: \(filePath.absoluteString)")
      } else {
        do {
          let data = try Data(contentsOf: filePath)
          if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: Any]] {
            var temdDic = weakSelf?.getMessageDic()
            jsonObject.forEach { (key: String, value: [String: Any]) in
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
            }
          }
        } catch {
          NELog.infoLog(className(), desc: "convert to message data to json object error : \(error.localizedDescription)")
        }
      }
    }
  }

  private func removeRecord(message: NIMMessage, record: inout [String: AtMEMessageRecord]) -> Bool {
    var didRemove = false
    if let atMeRecord = record[message.session?.sessionId ?? ""] {
      if atMeRecord.atMessages[message.messageId] != nil {
        atMeRecord.atMessages.removeValue(forKey: message.messageId)
        if atMeRecord.atMessages.count <= 0 {
          atMeRecord.isRead = true
          didRemove = true
        }
      }
    }
    return didRemove
  }

  private func addAtRecord(message: NIMMessage, record: inout [String: AtMEMessageRecord]) {
    if let atMeRecord = record[message.session?.sessionId ?? ""] {
      let lastTime = atMeRecord.lastTime?.doubleValue ?? 0
      if lastTime < message.timestamp {
        let atMessage = AtMessageModel()
        atMessage.messageId = message.messageId
        atMessage.messageTime = NSNumber(value: message.timestamp)
        atMeRecord.lastTime = NSNumber(value: message.timestamp)
        atMeRecord.atMessages[message.messageId] = NSNumber(value: message.timestamp)
        atMeRecord.isRead = false
        if let sessionId = message.session?.sessionId {
          record[sessionId] = atMeRecord
        }
      }
    } else {
      let atMeRecord = AtMEMessageRecord()
      let atMessage = AtMessageModel()
      atMessage.messageId = message.messageId
      atMessage.messageTime = NSNumber(value: message.timestamp)
      atMeRecord.lastTime = NSNumber(value: message.timestamp)
      atMeRecord.atMessages[message.messageId] = NSNumber(value: message.timestamp)
      atMeRecord.isRead = false
      if let sessionId = message.session?.sessionId {
        record[sessionId] = atMeRecord
      }
    }
  }

  private func atMessageChangeNoti(_ isCurrentThread: Bool = false) {
    if isCurrentThread == false {
      DispatchQueue.main.async {
        NotificationCenter.default.post(name: Notification.Name(AtMessageChangeNoti), object: nil)
      }
    } else {
      NotificationCenter.default.post(name: Notification.Name(AtMessageChangeNoti), object: nil)
    }
  }

  open func onRecvMessages(_ messages: [NIMMessage]) {
    filterAtMessage(messages: messages)
  }
}
