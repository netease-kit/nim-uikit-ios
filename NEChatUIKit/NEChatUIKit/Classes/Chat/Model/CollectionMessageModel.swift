//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class CollectionMessageModel: NSObject {
  /// 消息对象
  var message: V2NIMMessage? {
    didSet {
      if let m = message {
        chatmodel = ChatMessageHelper.modelFromMessage(message: m)

        if chatmodel.type == .file {
          fileModel = CollectionFileModel()
          if let file = chatmodel as? MessageFileModel {
            fileModel?.size = file.size
          }
        }
      }
    }
  }

  /// 会话名称
  var conversationName: String?
  /// 发送者昵称
  var senderName: String?
  /// 用户头像
  var avatar: String?
  /// 数据对象
  var chatmodel: MessageModel = MessageTextModel(message: nil)

  var fileModel: CollectionFileModel?

  var collection: V2NIMCollection?

  open func cellHeight(contenttMaxW: CGFloat) -> CGFloat {
    var height = chatmodel.contentSize.height
    let titleFont: UIFont = .systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.pinMessageTextSize, weight: .semibold)
    let bodyFont: UIFont = .systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.pinMessageTextSize)
    let maxSize = CGSize(width: contenttMaxW, height: CGFloat.greatestFiniteMagnitude)

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

    height += 124

    if chatmodel.replyedModel?.isReplay == true {
      height += 12
    }

    return height
  }
}
