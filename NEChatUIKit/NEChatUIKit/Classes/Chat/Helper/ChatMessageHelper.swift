
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CommonCrypto
import Foundation
import NEChatKit
import NECommonKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK

@objcMembers
public class ChatMessageHelper: NSObject {
  public static let repo = ChatRepo.shared

  /// 获取图片合适尺寸
  /// - Parameters:
  ///   - maxSize: 最大宽高
  ///   - size: 图片宽高
  ///   - miniWH: 最小宽高
  /// - Returns: 消息列表中展示的尺寸
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

  /// 获取会话昵称
  /// - Parameters:
  ///   - conversationId: 会话 id
  ///   - showAlias: 是否优先显示备注
  /// - Returns: 会话昵称
  public static func getSessionName(conversationId: String, showAlias: Bool = true) -> String {
    guard let sessionId = V2NIMConversationIdUtil.conversationTargetId(conversationId) else {
      return ""
    }
    if V2NIMConversationIdUtil.conversationType(conversationId) == .CONVERSATION_TYPE_P2P {
      if NEAIUserManager.shared.isAIUser(sessionId) {
        return NEAIUserManager.shared.getShowName(sessionId) ?? sessionId
      }
      return NEFriendUserCache.shared.getShowName(sessionId)
    } else {
      return NETeamUserManager.shared.getTeamInfo()?.name ?? sessionId
    }
  }

  // MARK: message

  /// 获取消息列表单元格注册列表
  /// - Parameter isFun: 是否是娱乐皮肤
  /// - Returns: 单元格注册列表
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

  /// 获取标记列表单元格注册列表
  /// - Parameter isFun: 是否是娱乐皮肤
  /// - Returns: 单元格注册列表
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

  /// 获取收藏列表单元格注册列表
  /// - Parameter isFun: 是否是娱乐皮肤
  /// - Returns: 单元格注册列表
  public static func getCollectionCellRegisterDic(isFun: Bool) -> [String: NEBaseCollectionMessageCell.Type] {
    [
      "\(MessageType.text.rawValue)":
        isFun ? FunCollectionMessageTextCell.self : CollectionMessageTextCell.self,
      "\(MessageType.image.rawValue)":
        isFun ? FunCollectionMessageImageCell.self : CollectionMessageImageCell.self,
      "\(MessageType.audio.rawValue)":
        isFun ? FunCollectionMessageAudioCell.self : CollectionMessageAudioCell.self,
      "\(MessageType.video.rawValue)":
        isFun ? FunCollectionMessageVideoCell.self : CollectionMessageVideoCell.self,
      "\(MessageType.location.rawValue)":
        isFun ? FunCollectionMessageLocationCell.self : CollectionMessageLocationCell.self,
      "\(MessageType.file.rawValue)":
        isFun ? FunCollectionMessageFileCell.self : CollectionMessageFileCell.self,
      "\(MessageType.multiForward.rawValue)":
        isFun ? FunCollectionMessageMultiForwardCell.self : CollectionMessageMultiForwardCell.self,
      "\(MessageType.richText.rawValue)":
        isFun ? FunCollectionMessageRichTextCell.self : CollectionMessageRichTextCell.self,
      "\(NEBasePinMessageTextCell.self)":
        isFun ? FunCollectionMessageDefaultCell.self : CollectionMessageDefaultCell.self,
      "\(NEBaseCollectionDefaultCell.self)": isFun ? FunCollectionDefaultCell.self : CollectionDefaultCell.self,
    ]
  }

  /// 构造消息体
  /// - Parameter message: 消息
  /// - Returns: 消息体
  public static func modelFromMessage(message: V2NIMMessage) -> MessageModel {
    var model: MessageModel
    switch message.messageType {
    case .MESSAGE_TYPE_VIDEO:
      model = MessageVideoModel(message: message)
    case .MESSAGE_TYPE_TEXT:
      model = MessageTextModel(message: message)
    case .MESSAGE_TYPE_IMAGE:
      model = MessageImageModel(message: message)
    case .MESSAGE_TYPE_AUDIO:
      model = MessageAudioModel(message: message)
    case .MESSAGE_TYPE_NOTIFICATION, .MESSAGE_TYPE_TIP:
      model = MessageTipsModel(message: message)
    case .MESSAGE_TYPE_FILE:
      model = MessageFileModel(message: message)
    case .MESSAGE_TYPE_LOCATION:
      model = MessageLocationModel(message: message)
    case .MESSAGE_TYPE_CALL:
      model = MessageCallRecordModel(message: message)
    case .MESSAGE_TYPE_CUSTOM:
      if let type = NECustomUtils.typeOfCustomMessage(message.attachment) {
        if type == customMultiForwardType {
          return MessageCustomModel(message: message, contentHeight: Int(customMultiForwardCellHeight))
        }
        if type == customRichTextType {
          return MessageRichTextModel(message: message)
        }

        // 注册过的自定义消息类型
        if NEChatUIKitClient.instance.getRegisterCustomCell()["\(type)"] != nil {
          return MessageCustomModel(message: message, contentHeight: Int(customMultiForwardCellHeight))
        }
      }
      fallthrough
    default:
      // 未识别的消息类型，默认为文本消息类型，text为未知消息体
      message.text = chatLocalizable("msg_unknown")
      model = MessageTextModel(message: message)
      model.unkonwMessage = true
    }
    return model
  }

  /// 构造消息体
  /// - Parameters:
  ///   - message: 消息
  ///   - completion: 完成回调
  public static func modelFromMessage(message: V2NIMMessage, _ completion: @escaping (MessageModel) -> Void) {
    var model: MessageModel
    switch message.messageType {
    case .MESSAGE_TYPE_VIDEO:
      model = MessageVideoModel(message: message)
      completion(model)
    case .MESSAGE_TYPE_TEXT:
      model = MessageTextModel(message: message)
      completion(model)
    case .MESSAGE_TYPE_IMAGE:
      model = MessageImageModel(message: message)
      completion(model)
    case .MESSAGE_TYPE_AUDIO:
      model = MessageAudioModel(message: message)
      completion(model)
    case .MESSAGE_TYPE_NOTIFICATION, .MESSAGE_TYPE_TIP:
      // 查询通知消息中 targetId 的用户信息
      if message.messageType == .MESSAGE_TYPE_NOTIFICATION,
         let attach = message.attachment as? V2NIMMessageNotificationAttachment,
         var accIds = attach.targetIds {
        if let senderId = message.senderId {
          accIds.append(senderId)
        }

        NETeamUserManager.shared.getTeamMembers(accountIds: accIds) {
          completion(MessageTipsModel(message: message))
        }
      } else {
        completion(MessageTipsModel(message: message))
      }
    case .MESSAGE_TYPE_FILE:
      model = MessageFileModel(message: message)
      completion(model)
    case .MESSAGE_TYPE_LOCATION:
      model = MessageLocationModel(message: message)
      completion(model)
    case .MESSAGE_TYPE_CALL:
      model = MessageCallRecordModel(message: message)
      completion(model)
    case .MESSAGE_TYPE_CUSTOM:
      if let type = NECustomUtils.typeOfCustomMessage(message.attachment) {
        if type == customMultiForwardType {
          completion(MessageCustomModel(message: message, contentHeight: Int(customMultiForwardCellHeight)))
          return
        }
        if type == customRichTextType {
          completion(MessageRichTextModel(message: message))
          return
        }

        // 注册过的自定义消息类型
        if NEChatUIKitClient.instance.getRegisterCustomCell()["\(type)"] != nil {
          completion(MessageCustomModel(message: message, contentHeight: Int(customMultiForwardCellHeight)))
          return
        }
      }
      fallthrough
    default:
      // 未识别的消息类型，默认为文本消息类型，text为未知消息体
      message.text = chatLocalizable("msg_unknown")
      model = MessageTextModel(message: message)
      model.unkonwMessage = true
      completion(model)
    }
  }

  /// 获取消息列表的中所以图片消息的 url
  /// - Parameter messages: 消息列表
  /// - Returns: 图片路径列表
  public static func getUrls(messages: [MessageModel]) -> [String] {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    var urls = [String]()
    for model in messages {
      if model.type == .image, let message = model.message?.attachment as? V2NIMMessageImageAttachment {
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

  /// 为消息体添加时间
  /// - Parameters:
  ///   - model: 消息体
  ///   - lastModel: 最后一条消息
  static func addTimeMessage(_ model: MessageModel, _ lastModel: MessageModel?) {
    guard let message = model.message else {
      NEALog.errorLog(ModuleName + " " + className(), desc: #function + ", model.message is nil")
      return
    }

    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: \(String(describing: message.messageClientId))")
    if NotificationMessageUtils.isDiscussSeniorTeamNoti(message: message) {
      return
    }

    let lastTs = lastModel?.message?.createTime ?? 0.0
    let curTs = message.createTime
    let dur = curTs - lastTs
    if (dur / 60) > 5 {
      let timeText = String.stringFromDate(date: Date(timeIntervalSince1970: curTs))
      model.timeContent = timeText
    }
  }

  /// 获取消息外显文案
  /// - Parameter message: 消息
  /// - Returns: 外显文案
  public static func contentOfMessage(_ message: V2NIMMessage?) -> String {
    switch message?.messageType {
    case .MESSAGE_TYPE_TEXT:
      if let t = message?.text {
        return t
      } else {
        return chatLocalizable("message_not_found")
      }
    case .MESSAGE_TYPE_IMAGE:
      return chatLocalizable("msg_image")
    case .MESSAGE_TYPE_AUDIO:
      return chatLocalizable("msg_audio")
    case .MESSAGE_TYPE_VIDEO:
      return chatLocalizable("msg_video")
    case .MESSAGE_TYPE_FILE:
      return chatLocalizable("msg_file")
    case .MESSAGE_TYPE_LOCATION:
      return chatLocalizable("msg_location") + " \(message?.text ?? "")"
    case .MESSAGE_TYPE_CALL:
      if let attachment = message?.attachment as? V2NIMMessageCallAttachment {
        return attachment.type == 1 ? chatLocalizable("msg_rtc_audio") : chatLocalizable("msg_rtc_video")
      }
      return chatLocalizable("msg_rtc_call")
    case .MESSAGE_TYPE_CUSTOM:
      // 换行消息
      if let content = NECustomUtils.contentOfRichText(message?.attachment) {
        return content
      }

      // 合并转发
      if let customType = NECustomUtils.typeOfCustomMessage(message?.attachment),
         customType == customMultiForwardType {
        return "[\(chatLocalizable("chat_history"))]"
      }

      return chatLocalizable("msg_custom")
    default:
      return chatLocalizable("msg_unknown")
    }
  }

  public static func getAIErrorMsage(_ errorCode: NSInteger) -> String? {
    var content: String?
    switch errorCode {
    case failedOperation:
      content = commonLocalizable("parameter_setting_error")
    case rateLimitExceeded:
      content = commonLocalizable("rate_limit_exceeded")
    case userNotExistCode:
      content = commonLocalizable("user_not_exist")
    case userBannedCode:
      content = commonLocalizable("user_banned")
    case userChatBannedCode:
      content = commonLocalizable("user_chat_banned")
    case noFriendCode:
      content = commonLocalizable("friend_not_exist")
    case messageHitAntispam1, messageHitAntispam2:
      content = commonLocalizable("message_hit_antispam")
    case teamMemberNotExist:
      content = commonLocalizable("team_member_not_exist")
    case teamNormalMemberChatBanned:
      content = commonLocalizable("team_normal_member_chat_banned")
    case teamMemberChatBanned:
      content = commonLocalizable("team_member_chat_banned")
    case notAIAccount:
      content = commonLocalizable("not_ai_account")
    case cannotBlockAIAccount:
      content = commonLocalizable("cannot_blocklist_ai_account")
    case aiMessagesDisabled:
      content = commonLocalizable("ai_messages_function_disabled")
    case aiMessageRequestFailed:
      content = commonLocalizable("failed_request_to_the_LLM")
    case aiMessageNotSupport:
      content = chatLocalizable("format_not_supported")
    default:
      break
    }
    return content
  }

  /// 移除消息扩展字段中的 回复、@
  /// - Parameter forwardMessage: 消息
  public static func clearForwardAtMark(_ forwardMessage: V2NIMMessage) {
    guard var remoteExt = getDictionaryFromJSONString(forwardMessage.serverExtension ?? "") as? [String: Any] else { return }
    remoteExt.removeValue(forKey: yxAtMsg)
    remoteExt.removeValue(forKey: keyReplyMsgKey)
    if remoteExt.count <= 0 {
      remoteExt = [:]
    }
    forwardMessage.serverExtension = getJSONStringFromDictionary(remoteExt)
  }

  /// 构建合并转发消息附件的 header
  /// - Parameters:
  ///   - messageCount: 消息数量
  ///   - completion: 完成回调
  public static func buildHeader(messageCount: Int) -> String {
    var dic = [String: Any]()
    dic["version"] = 0 // 功能版本
    dic["terminal"] = 2 // iOS
    //    dic["sdk_version"] = IMKitClient.instance.sdkVersion()
    //    dic["app_version"] = imkitVersion
    dic["message_count"] = messageCount // 转发消息数量

    return getJSONStringFromDictionary(dic)
  }

  /// 构建合并转发消息附件的 body
  /// - Parameters:
  ///   - messages: 消息
  ///   - completion: 完成回调
  public static func buildBody(messages: [V2NIMMessage],
                               _ completion: @escaping (String, [[String: Any]]) -> Void) {
    let enter = "\n" // 分隔符
    var body = "" // 序列化结果
    var abstracts = [[String: Any]]() // 摘要信息

    for (i, msg) in messages.enumerated() {
      // 移除扩展字段中的 回复、@ 信息
      let remoteExt = msg.serverExtension
      clearForwardAtMark(msg)

      // 保存消息昵称和头像
      if let from = ChatMessageHelper.getSenderId(msg) {
        let user = getUserFromCache(from)
        if let user = user {
          let senderNick = user.showName(false)
          if var remoteExt = getDictionaryFromJSONString(msg.serverExtension ?? "") as? [String: Any] {
            remoteExt[mergedMessageNickKey] = senderNick
            remoteExt[mergedMessageAvatarKey] = user.user?.avatar ?? NEFriendUserCache.getShortName(senderNick ?? "")
            msg.serverExtension = getJSONStringFromDictionary(remoteExt)
          } else {
            let remoteExt = [mergedMessageNickKey: senderNick as Any,
                             mergedMessageAvatarKey: user.user?.avatar as Any]
            msg.serverExtension = getJSONStringFromDictionary(remoteExt)
          }

          // 摘要信息
          if i < 3 {
            let content = ChatMessageHelper.contentOfMessage(msg)
            abstracts.append(["senderNick": senderNick as Any,
                              "content": content,
                              "userAccId": from])
          }
        }
        if let stringData = V2NIMMessageConverter.messageSerialization(msg) {
          body.append(enter + stringData)
        }
      }

      // 恢复扩展字段中的 回复、@ 信息
      msg.serverExtension = remoteExt
    }

    completion(body, abstracts)
  }

  /// 获取消息的客户端本地扩展信息（转换为[String: Any]）
  /// - Parameter message: 消息
  /// - Returns: 客户端本地扩展信息
  public static func getMessageLocalExtension(message: V2NIMMessage) -> [String: Any]? {
    guard let localExtension = message.localExtension else { return nil }

    if let localExt = getDictionaryFromJSONString(localExtension) as? [String: Any] {
      return localExt
    }
    return nil
  }

  /// 判断消息是否已撤回
  /// - Parameter message: 消息
  /// - Returns: 是否已撤回
  public static func isRevokeMessage(message: V2NIMMessage?) -> Bool {
    guard let message = message else { return false }

    if let localExt = getMessageLocalExtension(message: message),
       let isRevoke = localExt[revokeLocalMessage] as? Bool, isRevoke == true {
      return true
    }
    return false
  }

  /// 获取消息撤回前的内容（用于重新编辑）
  /// - Parameter message: 消息
  /// - Returns: 撤回前的内容
  public static func getRevokeMessageContent(message: V2NIMMessage?) -> String? {
    guard let message = message else { return nil }

    if let localExt = getMessageLocalExtension(message: message) {
      if let content = localExt[revokeLocalMessageContent] as? String {
        return content
      }
    }
    return nil
  }

  /// 查找回复信息键值对
  /// - Parameter message: 消息
  /// - Returns: 回复消息的 id
  public static func getReplyDictionary(message: V2NIMMessage) -> [String: Any]? {
    if let remoteExt = getDictionaryFromJSONString(message.serverExtension ?? ""),
       let yxReplyMsg = remoteExt[keyReplyMsgKey] as? [String: Any] {
      return yxReplyMsg
    }

    return nil
  }

  /// 判断是否是数字人发送的消息
  /// - Parameter message: 消息
  /// - Returns: 是否是数字人发送的消息
  public static func isAISender(_ message: V2NIMMessage?) -> Bool {
    if message?.aiConfig != nil, message?.aiConfig?.aiStatus == .MESSAGE_AI_STATUS_RESPONSE {
      return true
    }
    return false
  }

  /// 获取消息发送者实际 id
  /// - Parameter message: 消息
  /// - Returns: 实际发送者的 id
  public static func getSenderId(_ message: V2NIMMessage?) -> String? {
    var senderId = message?.senderId
    // 数字人回复的消息
    if IMKitConfigCenter.shared.enableAIUser,
       message?.aiConfig != nil,
       message?.aiConfig?.aiStatus == .MESSAGE_AI_STATUS_RESPONSE {
      senderId = message?.aiConfig?.accountId
    }

    return senderId
  }

  /// 从缓存中获取用户信息
  /// - Parameter accountId: 用户 id
  /// - Returns: 用户信息
  public static func getUserFromCache(_ accountId: String) -> NEUserWithFriend? {
    NEAIUserManager.shared.getAIUserById(accountId) ?? NEFriendUserCache.shared.getFriendInfo(accountId) ?? NEP2PChatUserCache.shared.getUserInfo(accountId) ?? NETeamUserManager.shared.getUserInfo(accountId)
  }

  /// 查找回复信息键值对
  /// - Parameter message: 消息
  /// - Returns: 回复消息的 id
  public static func createMessageRefer(_ params: [String: Any]?) -> V2NIMMessageRefer {
    let refer = V2NIMMessageRefer()
    refer.messageClientId = params?["idClient"] as? String
    refer.messageServerId = params?["idServer"] as? String
    refer.senderId = params?["from"] as? String
    refer.createTime = TimeInterval(Double(params?["time"] as? Int ?? 0) / 1000.0)
    if let conversationId = params?["to"] as? String {
      refer.conversationId = conversationId
      refer.receiverId = V2NIMConversationIdUtil.conversationTargetId(conversationId)
      refer.conversationType = V2NIMConversationIdUtil.conversationType(conversationId)
    }

    return refer
  }

  /// 计算减少的
  /// - Parameter attribute： at 文本前的文本
  static func getReduceIndexCount(_ attribute: NSAttributedString) -> Int {
    var count = 0
    attribute.enumerateAttributes(
      in: NSMakeRange(0, attribute.length),
      options: NSAttributedString.EnumerationOptions(rawValue: 0)
    ) { dics, range, stop in
      if let neAttachment = dics[NSAttributedString.Key.attachment] as? NEEmotionAttachment {
        if let tagCount = neAttachment.emotion?.tag?.count {
          count = count + tagCount - 1
        }
      }
    }
    return count
  }

  /// 解析消息中的 @
  /// - Parameters:
  ///   - message: 消息
  ///   - attributeStr: 消息富文本
  /// - Returns: 高亮 @ 后的消息富文本
  public static func loadAtInMessage(_ message: V2NIMMessage?, _ attributeStr: NSMutableAttributedString?) -> NSMutableAttributedString? {
    // 数字人回复的消息不展示高亮（serverExtension 会被带回）
    if message?.aiConfig != nil, message?.aiConfig?.aiStatus == .MESSAGE_AI_STATUS_RESPONSE {
      return nil
    }

    let text = message?.text ?? ""
    let messageTextFont = UIFont.systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.messageTextSize)

    // 兼容老的表情消息，如果前面有表情而位置计算异常则回退回老的解析
    var notFound = false

    // 计算表情(根据转码后的index)
    if let remoteExt = getDictionaryFromJSONString(message?.serverExtension ?? ""), let dic = remoteExt[yxAtMsg] as? [String: AnyObject] {
      for (_, value) in dic {
        if let contentDic = value as? [String: AnyObject] {
          if let array = contentDic[atSegmentsKey] as? [AnyObject] {
            if let models = NSArray.yx_modelArray(with: MessageAtInfoModel.self, json: array) as? [MessageAtInfoModel] {
              for model in models {
                // 前面因为表情增加的索引数量
                var count = 0
                if text.count > model.start {
                  let frontAttributeStr = NEEmotionTool.getAttWithStr(
                    str: String(text.prefix(model.start)),
                    font: messageTextFont
                  )
                  count = getReduceIndexCount(frontAttributeStr)
                }
                let start = model.start - count
                if start < 0 {
                  notFound = true
                  break
                }
                var end = model.end - count

                if model.end + atRangeOffset > text.count {
                  notFound = true
                  break
                }
                // 获取起始索引
                let startIndex = text.index(text.startIndex, offsetBy: model.start)
                // 获取结束索引
                let endIndex = text.index(text.startIndex, offsetBy: model.end + atRangeOffset)
                let frontAttributeStr = NEEmotionTool.getAttWithStr(
                  str: String(text[startIndex ..< endIndex]),
                  font: messageTextFont
                )
                let innerCount = getReduceIndexCount(frontAttributeStr)
                end = end - innerCount
                if end <= start {
                  notFound = true
                  break
                }

                if attributeStr?.length ?? 0 > end {
                  attributeStr?.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.ne_normalTheme, range: NSMakeRange(start, end - start + atRangeOffset))
                }
              }
            }
          }
        }
      }
    }

    if notFound == true, let remoteExt = getDictionaryFromJSONString(message?.serverExtension ?? ""), let dic = remoteExt[yxAtMsg] as? [String: AnyObject] {
      for (_, value) in dic {
        if let contentDic = value as? [String: AnyObject] {
          if let array = contentDic[atSegmentsKey] as? [AnyObject] {
            if let models = NSArray.yx_modelArray(with: MessageAtInfoModel.self, json: array) as? [MessageAtInfoModel] {
              for model in models {
                if attributeStr?.length ?? 0 > model.end {
                  attributeStr?.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.ne_normalTheme, range: NSMakeRange(model.start, model.end - model.start + atRangeOffset))
                }
              }
            }
          }
        }
      }
    }

    return attributeStr
  }

  /// 获取文件 MD5 值
  /// - Parameter fileURL: 文件 URL
  /// - Returns: md5 值
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

  /// 构造消息附件的本地文件路径
  /// - Parameter message: 消息
  /// - Returns: 本地文件路径
  public static func createFilePath(_ message: V2NIMMessage?) -> String {
    var path = NEPathUtils.getDirectoryForDocuments(dir: imkitDir) ?? ""
    guard let attach = message?.attachment as? V2NIMMessageFileAttachment else {
      return path
    }

    switch message?.messageType {
    case .MESSAGE_TYPE_AUDIO:
      path = NEPathUtils.getDirectoryForDocuments(dir: "\(imkitDir)audio/") ?? ""
    case .MESSAGE_TYPE_IMAGE:
      path = NEPathUtils.getDirectoryForDocuments(dir: "\(imkitDir)image/") ?? ""
    case .MESSAGE_TYPE_VIDEO:
      path = NEPathUtils.getDirectoryForDocuments(dir: "\(imkitDir)video/") ?? ""
    default:
      path = NEPathUtils.getDirectoryForDocuments(dir: "\(imkitDir)file/") ?? ""
    }

    if let messageClientId = message?.messageClientId {
      path += messageClientId
    }

    // 后缀（例如：.png）
    if let ext = attach.ext, ext.count < 5 {
      path += ext
    }

    return path
  }
}
