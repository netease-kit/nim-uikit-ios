// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK

@objc
public protocol MultiForwardViewModelDelegate: NSObjectProtocol {
  @objc optional
  func getMessageModel(model: MessageModel)
}

@objcMembers
open class MultiForwardViewModel: NSObject {
  public weak var delegate: MultiForwardViewModelDelegate?
  public var repo = ChatRepo.shared
  public var messages = [MessageModel]()

  func loadData(_ messageAttachmentUrl: String?,
                _ filePath: String,
                _ md5: String?,
                _ completion: @escaping (Error?) -> Void) {
    if FileManager.default.fileExists(atPath: filePath) {
      decodeMesssage(filePath: filePath, md5: md5, completion)
    } else if let urlString = messageAttachmentUrl {
      downLoad(urlString, filePath, nil) { [weak self] _, error in
        self?.decodeMesssage(filePath: filePath, md5: md5, completion)
      }
    }
  }

  func decodeMesssage(filePath: String,
                      md5: String?,
                      _ completion: (Error?) -> Void) {
    // 校验文件 MD5
    if let filePath = URL(string: filePath),
       let fileMD5 = ChatMessageHelper.getFileChecksum(fileURL: filePath) {
      if fileMD5 != md5 {
        completion(NSError(domain: chatLocalizable("file_check_failed"), code: 0))
        return
      }
    }

    do {
      let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
      let strData = String(data: data, encoding: .utf8)
      let subStringData = strData?.components(separatedBy: "\n")
      if let msgCount = subStringData?.count, msgCount > 1 {
        for i in 1 ..< msgCount {
          if let msgString = subStringData?[i], let msg = V2NIMMessageConverter.messageDeserialization(msgString) {
            let model = modelFromMessage(message: msg)
            ChatMessageHelper.addTimeMessage(model, messages.last)
            messages.append(model)
          }
        }
        completion(nil)
      }
    } catch {
      completion(error)
    }
  }

  open func modelFromMessage(message: V2NIMMessage) -> MessageModel {
    var model: MessageModel
    switch message.messageType {
    case .MESSAGE_TYPE_AUDIO:
      message.text = chatLocalizable("msg_audio")
      model = MessageTextModel(message: message)
    case .MESSAGE_TYPE_CALL:
      message.text = chatLocalizable("msg_rtc_call")
      if let attachment = message.attachment as? V2NIMMessageCallAttachment {
        message.text = attachment.type == 1 ? chatLocalizable("msg_rtc_audio") : chatLocalizable("msg_rtc_video")
      }
      model = MessageTextModel(message: message)
    default:
      model = ChatMessageHelper.modelFromMessage(message: message)
    }

    if let remoteExt = getDictionaryFromJSONString(message.serverExtension ?? "") {
      model.fullName = remoteExt[mergedMessageNickKey] as? String
      model.shortName = NEFriendUserCache.getShortName(model.fullName ?? "")
      model.avatar = remoteExt[mergedMessageAvatarKey] as? String
    } else {
      model.fullName = ChatMessageHelper.getSenderId(message)
      model.shortName = NEFriendUserCache.getShortName(model.fullName ?? "")
    }

    delegate?.getMessageModel?(model: model)
    return model
  }

  open func downLoad(_ urlString: String,
                     _ filePath: String,
                     _ progress: ((UInt) -> Void)?,
                     _ completion: ((String?, NSError?) -> Void)?) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + urlString)
    ResourceRepo.shared.downLoad(urlString, filePath, progress, completion)
  }
}
