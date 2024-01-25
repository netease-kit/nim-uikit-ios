// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIMKit
import NIMSDK
import UIKit

@objcMembers
open class PinMessageModel: NSObject {
  var chatmodel: MessageModel = MessageTextModel(message: nil)
  var message: NIMMessage
  var item: NIMMessagePinItem
  var session: NIMSession
  var repo = ChatRepo.shared
  var pinFileModel: PinMessageFileModel?

  init(message: NIMMessage, item: NIMMessagePinItem) {
    self.message = message
    session = item.session
    self.item = item
    super.init()
    chatmodel = modelFromMessage(message: message)
    if chatmodel.type == .file {
      pinFileModel = PinMessageFileModel()
      if let filemodel = chatmodel as? MessageFileModel {
        pinFileModel?.size = filemodel.size
      }
    }
  }

  private func modelFromMessage(message: NIMMessage) -> MessageModel {
    let model = ChatMessageHelper.modelFromMessage(message: message)

    if let uid = message.from {
      let user = ChatUserCache.getUserInfo(uid)
      let fullName = ChatUserCache.getShowName(userId: uid, teamId: session.sessionId)
      model.avatar = user?.userInfo?.avatarUrl
      model.fullName = fullName
      model.shortName = ChatUserCache.getShortName(name: user?.showName(false) ?? "", length: 2)
    }

//    model.replyedModel = getReplyMessageWithoutThread(message: message)
//    if let pin = repo.searchMessagePinHistory(message) {
//      model.isPined = true
//      model.pinAccount = pin.accountID
//      let pinID = pin.accountID ?? NIMSDK.shared().loginManager.currentAccount()
//      model.pinShowName = getShowName(userId: pinID, teamId: session.sessionId)
//    } else {
//      model.isPined = false
//    }
    return model
  }

  open func cellHeight(pinContentMaxW: CGFloat) -> CGFloat {
    var height = chatmodel.contentSize.height
    if let textModel = chatmodel as? MessageTextModel {
      // 文本消息最多显示 3 行
      let textSize = textModel.attributeStr?.finalSize(.systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.pinMessageTextSize), CGSize(width: pinContentMaxW, height: CGFloat.greatestFiniteMagnitude), 3) ?? .zero
      height = textSize.height
    }

    if let textModel = chatmodel as? MessageRichTextModel {
      // 换行消息中的标题最多显示 1 行
      let titleSize = textModel.titleAttributeStr?.finalSize(.systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.pinMessageTextSize, weight: .semibold), CGSize(width: pinContentMaxW, height: CGFloat.greatestFiniteMagnitude), 1) ?? .zero
      height = titleSize.height

      // 换行消息中的内容最多显示 2 行
      let textSize = textModel.attributeStr?.finalSize(.systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.pinMessageTextSize), CGSize(width: pinContentMaxW, height: CGFloat.greatestFiniteMagnitude), 2) ?? .zero
      height += textSize.height
    }

    height += 100

    if chatmodel.replyedModel?.isReplay == true {
      height += 12
    }

    return height
  }

  open func getReplyMessageWithoutThread(message: NIMMessage) -> MessageModel? {
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
}
