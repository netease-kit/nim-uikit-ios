// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import NIMSDK
import UIKit

@objcMembers
open class NEPinMessageModel: NSObject {
  var chatmodel: MessageModel = MessageTextModel(message: nil)
  var message: V2NIMMessage
  var item: V2NIMMessagePin
  var conversationId: String?
  var repo = ChatRepo.shared
  var pinFileModel: PinMessageFileModel?

  init(message: V2NIMMessage, item: V2NIMMessagePin) {
    self.message = message
    conversationId = item.messageRefer?.conversationId
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

  private func modelFromMessage(message: V2NIMMessage) -> MessageModel {
    let model = ChatMessageHelper.modelFromMessage(message: message)
    let uid = ChatMessageHelper.getSenderId(message)

    model.fullName = uid ?? ""
    model.shortName = NEFriendUserCache.getShortName(uid ?? "''")
    return model
  }

  open func cellHeight(pinContentMaxW: CGFloat) -> CGFloat {
    var height = chatmodel.contentSize.height
    let titleFont: UIFont = .systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.pinMessageTextSize, weight: .semibold)
    let bodyFont: UIFont = .systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.pinMessageTextSize)
    let maxSize = CGSize(width: pinContentMaxW, height: CGFloat.greatestFiniteMagnitude)

    if let textModel = chatmodel as? MessageTextModel {
      // 文本消息最多显示 3 行
      let textSize = NSAttributedString.getRealSize(textModel.attributeStr, bodyFont, maxSize, 3)
      height = textSize.height
    }

    if let textModel = chatmodel as? MessageRichTextModel {
      // 换行消息中的标题最多显示 1 行
      let titleSize = NSAttributedString.getRealSize(textModel.titleAttributeStr, titleFont, maxSize, 1)
      height = titleSize.height

      // 换行消息中的内容最多显示 2 行
      let textSize = NSAttributedString.getRealSize(textModel.attributeStr, bodyFont, maxSize, 2)
      height += textSize.height
    }

    height += 100

    if chatmodel.replyedModel?.isReplay == true {
      height += 12
    }

    return height
  }
}
