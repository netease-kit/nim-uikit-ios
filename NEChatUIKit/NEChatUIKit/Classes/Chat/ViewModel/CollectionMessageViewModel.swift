//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open
class CollectionMessageViewModel: NSObject {
  public var collectionDatas = [CollectionMessageModel]()

  /// 消息API 单例
  let chatRepo = ChatRepo.shared

  /// 加载收藏数据
  /// - Parameter completion: 完成回调
  public func loadData(_ completion: @escaping (NSError?, Bool) -> Void) {
    let option = V2NIMCollectionOption()

    if let model = collectionDatas.last, let anchor = model.collection {
      option.anchorCollection = anchor
    } else {
      option.endTime = Date().timeIntervalSince1970
      let currentDate = Date()
      let tenYearsAgo = Calendar.current.date(byAdding: .year, value: -10, to: currentDate)
      let timeInterval = tenYearsAgo!.timeIntervalSince1970
      option.beginTime = timeInterval
    }
    option.limit = 100
    option.direction = .QUERY_DIRECTION_DESC
    chatRepo.getCollections(option) { [weak self] collections, error in
      if let error = error {
        completion(error, false)
      } else {
        if let v2Collections = collections, let models = self?.parseMessage(v2Collections) {
          self?.collectionDatas.append(contentsOf: models)
          if models.count > 0 {
            completion(nil, false)
          } else {
            completion(nil, true)
          }
        } else {
          completion(nil, true)
        }
      }
    }
  }

  /// 反序列化收藏的消息
  /// - Parameter collections: 收藏内容列表
  func parseMessage(_ collections: [V2NIMCollection]) -> [CollectionMessageModel] {
    var retArray = [CollectionMessageModel]()
    for collection in collections {
      if let dataString = collection.collectionData {
        if let dataDic = getDictionaryFromJSONString(dataString) {
          if dataDic["message"] != nil, dataDic["conversationName"] != nil {
            let model = CollectionMessageModel()
            if let messageString = dataDic["message"] as? String {
              if let message = V2NIMMessageConverter.messageDeserialization(messageString) {
                model.message = message
              }
            }
            if let conversationName = dataDic["conversationName"] as? String {
              model.conversationName = conversationName
            }
            if let avatar = dataDic["avatar"] as? String {
              model.avatar = avatar
              model.chatmodel.avatar = avatar
            }
            if let senderName = dataDic["senderName"] as? String {
              model.senderName = senderName
              model.chatmodel.fullName = senderName
            }
            model.collection = collection
            retArray.append(model)
          }
        }
      }
    }
    return retArray
  }

  /// 发送文本消息
  /// - Parameter text: 文本内容
  /// - Parameter conversationId: 会话ID
  /// - Parameter completion: 完成回调
  open func sendTextMessage(_ text: String, _ conversationId: String, _ completion: @escaping (V2NIMSendMessageResult?, Error?, UInt) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", text.count: \(text.count)")
    if text.count <= 0 {
      return
    }
    chatRepo.sendMessage(
      message: MessageUtils.textMessage(text: text),
      conversationId: conversationId,
      completion
    )
  }

  /// 转发消息
  /// - Parameters:
  ///   - conversationIds: 会话 id 列表
  ///   - comment: 留言
  ///   - completion: 完成回调
  open func forwardCollectionMessages(_ message: V2NIMMessage,
                                      _ conversationIds: [String],
                                      _ comment: String?,
                                      _ completion: @escaping (V2NIMSendMessageResult?, Error?, UInt) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: \(String(describing: message.messageClientId))")
    for conversationId in conversationIds {
      let forwardMessage = MessageUtils.forwardMessage(message: message)
      ChatMessageHelper.clearForwardAtMark(forwardMessage)
      chatRepo.sendMessage(message: forwardMessage, conversationId: conversationId, completion)
      if let text = comment, !text.isEmpty {
        sendTextMessage(text, conversationId, completion)
      }
    }
  }

  /// 下载文件
  /// - Parameter urlString: 文件URL
  /// - Parameter filePath: 文件路径
  /// - Parameter progress: 进度回调
  /// - Parameter completion: 完成回调
  open func downloadFile(_ urlString: String,
                         _ filePath: String,
                         _ progress: ((UInt) -> Void)?,
                         _ completion: ((String?, NSError?) -> Void)?) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + urlString)
    ResourceRepo.shared.downLoad(urlString, filePath, progress, completion)
  }

  /// 删除收藏
  /// - Parameter collection: 收藏对象
  /// - Parameter completion: 完成回调
  open func removeCollection(_ collection: V2NIMCollection, _ completion: @escaping (NSError?) -> Void) {
    chatRepo.removeCollections([collection]) { ret, error in
      completion(error)
    }
  }

  open func getHandSetEnable() -> Bool {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    return SettingRepo.shared.getHandsetMode()
  }
}
