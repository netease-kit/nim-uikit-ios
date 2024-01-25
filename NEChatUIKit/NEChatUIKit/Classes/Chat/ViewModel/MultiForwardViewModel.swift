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
      downLoad(urlString, filePath, nil) { [weak self] error in
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
          if let msgData = subStringData?[i].data(using: .utf8) {
            let msg = NIMSDK.shared().conversationManager.decodeMessage(from: msgData)
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

  open func modelFromMessage(message: NIMMessage) -> MessageModel {
    var model: MessageModel
    switch message.messageType {
    case .audio:
      message.text = chatLocalizable("msg_audio")
      model = MessageTextModel(message: message)
    case .rtcCallRecord:
      message.text = chatLocalizable("msg_rtc_call")
      if let object = message.messageObject as? NIMRtcCallRecordObject {
        message.text = object.callType == .audio ? chatLocalizable("msg_rtc_audio") : chatLocalizable("msg_rtc_video")
      }
      model = MessageTextModel(message: message)
    default:
      model = ChatMessageHelper.modelFromMessage(message: message)
    }

    model.fullName = message.remoteExt?[mergedMessageNickKey] as? String
    model.shortName = ChatUserCache.getShortName(name: model.fullName ?? "", length: 2)
    model.avatar = message.remoteExt?[mergedMessageAvatarKey] as? String

    delegate?.getMessageModel?(model: model)
    return model
  }

  open func downLoad(_ urlString: String, _ filePath: String, _ progress: NIMHttpProgressBlock?,
                     _ completion: NIMDownloadCompleteBlock?) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + urlString)
    repo.downloadSource(urlString, filePath, progress, completion)
  }
}
