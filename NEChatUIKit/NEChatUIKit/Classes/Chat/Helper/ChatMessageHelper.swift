
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CommonCrypto
import Foundation
import NEChatKit
import NECommonKit
import NECoreIMKit
import NIMSDK

@objcMembers
public class ChatMessageHelper: NSObject {
  public static let repo = ChatRepo.shared

  // 获取图片合适尺寸
  public class func getSizeWithMaxSize(_ maxSize: CGSize, size: CGSize,
                                       miniWH: CGFloat) -> CGSize {
    var realSize = CGSize.zero

    if min(size.width, size.height) > 0 {
      if size.width > size.height {
        // 宽大 按照宽给高
        let width = CGFloat(min(maxSize.width, size.width))
        realSize = CGSize(width: width, height: width * size.height / size.width)
        if realSize.height < miniWH {
          realSize.height = miniWH
        }
      } else {
        // 高大 按照高给宽
        let height = CGFloat(min(maxSize.height, size.height))
        realSize = CGSize(width: height * size.width / size.height, height: height)
        if realSize.width < miniWH {
          realSize.width = miniWH
        }
      }
    } else {
      realSize = maxSize
    }

    return realSize
  }

  public static func getSessionName(session: NIMSession, showAlias: Bool = true) -> String {
    session.sessionType == .P2P ? ChatUserCache.getShowName(userId: session.sessionId, teamId: nil, showAlias) : repo.getTeamInfo(teamId: session.sessionId)?.teamName ?? ""
  }

  // MARK: message

  public static func getChatCellRegisterDic(isFun: Bool) -> [String: UITableViewCell.Type] {
    [
      "\(MessageType.text.rawValue)":
        isFun ? FunChatMessageTextCell.self : ChatMessageTextCell.self,
      "\(MessageType.rtcCallRecord.rawValue)":
        isFun ? FunChatMessageCallCell.self : ChatMessageCallCell.self,
      "\(MessageType.audio.rawValue)":
        isFun ? FunChatMessageAudioCell.self : ChatMessageAudioCell.self,
      "\(MessageType.image.rawValue)":
        isFun ? FunChatMessageImageCell.self : ChatMessageImageCell.self,
      "\(MessageType.revoke.rawValue)":
        isFun ? FunChatMessageRevokeCell.self : ChatMessageRevokeCell.self,
      "\(MessageType.video.rawValue)":
        isFun ? FunChatMessageVideoCell.self : ChatMessageVideoCell.self,
      "\(MessageType.file.rawValue)":
        isFun ? FunChatMessageFileCell.self : ChatMessageFileCell.self,
      "\(MessageType.reply.rawValue)":
        isFun ? FunChatMessageReplyCell.self : ChatMessageReplyCell.self,
      "\(MessageType.location.rawValue)":
        isFun ? FunChatMessageLocationCell.self : ChatMessageLocationCell.self,
      "\(MessageType.time.rawValue)":
        isFun ? FunChatMessageTipCell.self : ChatMessageTipCell.self,
      "\(MessageType.multiForward.rawValue)":
        isFun ? FunChatMessageMultiForwardCell.self : ChatMessageMultiForwardCell.self,
      "\(MessageType.richText.rawValue)":
        isFun ? FunChatMessageRichTextCell.self : ChatMessageRichTextCell.self,
    ]
  }

  public static func getPinCellRegisterDic(isFun: Bool) -> [String: NEBasePinMessageCell.Type] {
    [
      "\(MessageType.text.rawValue)":
        isFun ? FunPinMessageTextCell.self : PinMessageTextCell.self,
      "\(MessageType.image.rawValue)":
        isFun ? FunPinMessageImageCell.self : PinMessageImageCell.self,
      "\(MessageType.audio.rawValue)":
        isFun ? FunPinMessageAudioCell.self : PinMessageAudioCell.self,
      "\(MessageType.video.rawValue)":
        isFun ? FunPinMessageVideoCell.self : PinMessageVideoCell.self,
      "\(MessageType.location.rawValue)":
        isFun ? FunPinMessageLocationCell.self : PinMessageLocationCell.self,
      "\(MessageType.file.rawValue)":
        isFun ? FunPinMessageFileCell.self : PinMessageFileCell.self,
      "\(MessageType.multiForward.rawValue)":
        isFun ? FunPinMessageMultiForwardCell.self : PinMessageMultiForwardCell.self,
      "\(MessageType.richText.rawValue)":
        isFun ? FunPinMessageRichTextCell.self : PinMessageRichTextCell.self,
      "\(NEBasePinMessageTextCell.self)":
        isFun ? FunPinMessageDefaultCell.self : PinMessageDefaultCell.self,
    ]
  }

  public static func modelFromMessage(message: NIMMessage) -> MessageModel {
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
    case .notification, .tip:
      model = MessageTipsModel(message: message)
    case .file:
      model = MessageFileModel(message: message)
    case .location:
      model = MessageLocationModel(message: message)
    case .rtcCallRecord:
      model = MessageCallRecordModel(message: message)
    case .custom:
      if let attach = NECustomAttachment.attachmentOfCustomMessage(message: message) {
        if attach.customType == customRichTextType {
          return MessageRichTextModel(message: message)
        }
        return MessageCustomModel(message: message)
      }
      fallthrough
    default:
      // 未识别的消息类型，默认为文本消息类型，text为未知消息体
      message.text = chatLocalizable("msg_unknown")
      model = MessageTextModel(message: message)
    }
    return model
  }

  /// 获取消息列表的中所以图片消息的 url
  public static func getUrls(messages: [MessageModel]) -> [String] {
    NELog.infoLog(ModuleName + " " + className(), desc: #function)
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
    return urls
  }

  // history message insert message at first of messages, send message add last of messages
  static func addTimeMessage(_ model: MessageModel, _ lastModel: MessageModel?) {
    guard let message = model.message else {
      NELog.errorLog(ModuleName + " " + className(), desc: #function + ", model.message is nil")
      return
    }

    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + message.messageId)
    if NotificationMessageUtils.isDiscussSeniorTeamNoti(message: message) {
      return
    }

    let lastTs = lastModel?.message?.timestamp ?? 0.0
    let curTs = message.timestamp
    let dur = curTs - lastTs
    if (dur / 60) > 5 {
      let timeText = String.stringFromDate(date: Date(timeIntervalSince1970: curTs))
      model.timeContent = timeText
    }
  }

  public static func contentOfMessage(_ message: NIMMessage?) -> String {
    switch message?.messageType {
    case .text:
      if let t = message?.text {
        return t
      } else {
        return chatLocalizable("message_not_found")
      }
    case .image:
      return chatLocalizable("msg_image")
    case .audio:
      return chatLocalizable("msg_audio")
    case .video:
      return chatLocalizable("msg_video")
    case .file:
      return chatLocalizable("msg_file")
    case .location:
      return chatLocalizable("msg_location")
    case .rtcCallRecord:
      if let record = message?.messageObject as? NIMRtcCallRecordObject {
        return record.callType == .audio ? chatLocalizable("msg_rtc_audio") :
          chatLocalizable("msg_rtc_video")
      }
      return chatLocalizable("msg_rtc_call")
    case .custom:
      if let content = NECustomAttachment.contentOfRichText(message: message) {
        return content
      }

      if let attach = NECustomAttachment.attachmentOfCustomMessage(message: message),
         attach.customType == customMultiForwardType {
        return "[\(chatLocalizable("chat_history"))]"
      }

      return chatLocalizable("msg_custom")
    default:
      return chatLocalizable("msg_unknown")
    }
  }

  /// 移除消息扩展字段中的 回复、@
  public static func clearForwardAtMark(_ forwardMessage: NIMMessage) {
    forwardMessage.remoteExt?.removeValue(forKey: yxAtMsg)
    forwardMessage.remoteExt?.removeValue(forKey: keyReplyMsgKey)
    if forwardMessage.remoteExt?.count ?? 0 <= 0 {
      forwardMessage.remoteExt = nil
    }
  }

  public static func buildHeader(messageCount: Int) -> String {
    var dic = [String: Any]()
    dic["version"] = 0 // 功能版本
    dic["terminal"] = 2 // iOS
    //    dic["sdk_version"] = IMKitClient.instance.sdkVersion()
    //    dic["app_version"] = imkitVersion
    dic["message_count"] = messageCount // 转发消息数量

    return getJSONStringFromDictionary(dic)
  }

  public static func buildBody(messages: [NIMMessage],
                               _ completion: @escaping (String, [[String: Any]]) -> Void) {
    let enter = "\n" // 分隔符
    var body = "" // 序列化结果
    var abstracts = [[String: Any]]() // 摘要信息
    let group = DispatchGroup()

    for (i, msg) in messages.enumerated() {
      // 移除扩展字段中的 回复、@ 信息
      let remoteExt = msg.remoteExt
      clearForwardAtMark(msg)

      // 保存消息昵称和头像
      if let from = msg.from {
        group.enter()
        ChatUserCache.getUserInfo(from) { user, error in
          if let user = user {
            let senderNick = user.showName(false)
            if msg.remoteExt != nil {
              msg.remoteExt![mergedMessageNickKey] = senderNick
              msg.remoteExt![mergedMessageAvatarKey] = user.userInfo?.avatarUrl ?? user.shortName(count: 2)
            } else {
              msg.remoteExt = [mergedMessageNickKey: senderNick as Any,
                               mergedMessageAvatarKey: user.userInfo?.avatarUrl as Any]
            }

            // 摘要信息
            if i < 3 {
              let content = ChatMessageHelper.contentOfMessage(msg)
              abstracts.append(["senderNick": senderNick as Any,
                                "content": content,
                                "userAccId": from])
            }
          }
          body.append(enter)
          let data = NIMSDK.shared().conversationManager.encodeMessage(toData: msg)
          if let stringData = String(data: data, encoding: .utf8) {
            body.append(stringData)
          }
          group.leave()
        }
      }

      // 恢复扩展字段中的 回复、@ 信息
      msg.remoteExt = remoteExt
    }

    group.notify(queue: .main, work: DispatchWorkItem(block: {
      completion(body, abstracts)
    }))
  }

  public static func getFileChecksum(fileURL: URL) -> String? {
    // 打开文件，创建文件句柄
    let file = FileHandle(forReadingAtPath: fileURL.path)
    guard file != nil else { return nil }

    // 创建 CC_MD5_CTX 上下文对象
    var context = CC_MD5_CTX()
    CC_MD5_Init(&context)

    // 读取文件数据并更新上下文对象
    while autoreleasepool(invoking: {
      let data = file?.readData(ofLength: 1024)
      if data?.count == 0 {
        return false
      }
      data?.withUnsafeBytes { buffer in
        CC_MD5_Update(&context, buffer.baseAddress, CC_LONG(buffer.count))
      }
      return true
    }) {}

    // 计算 MD5 值并关闭文件
    var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
    CC_MD5_Final(&digest, &context)
    file?.closeFile()

    // 将 MD5 值转换为字符串格式
    let md5String = digest.map { String(format: "%02hhx", $0) }.joined()
    return md5String
  }

  // 检测语音消息是否下载，非漫游的云端消息不会自动下载语音文件，需要手动下载
  public static func downloadAudioFile(message: NIMMessage) {
    if message.messageType == .audio {
      if let audio = message.messageObject as? NIMAudioObject {
        if let path = audio.path, FileManager.default.fileExists(atPath: path) == false {
          repo.downloadMessageAttachment(message) { error in
          }
        }
      }
    }
  }
}
