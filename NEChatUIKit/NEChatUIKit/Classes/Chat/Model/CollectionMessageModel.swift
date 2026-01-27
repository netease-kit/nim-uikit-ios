//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit_coexist
import NIMSDK2
import UIKit

@objcMembers
open class CollectionMessageModel: NSObject {
  /// 消息对象
  public var message: V2NIM2Message? {
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
  public var conversationName: String?
  /// 发送者昵称
  public var senderName: String?
  /// 用户头像
  public var avatar: String?
  /// 数据对象
  public var chatmodel: MessageModel = MessageTextModel(message: nil)

  public var fileModel: CollectionFileModel?

  public var collection: V2NIM2Collection?

  open func cellHeight(contenttMaxW: CGFloat) -> CGFloat {
    var height = chatmodel.contentSize.height
    let titleFont: UIFont = .systemFont(ofSize: ChatUIConfig.shared.messageProperties.pinMessageTextSize, weight: .semibold)
    let bodyFont: UIFont = .systemFont(ofSize: ChatUIConfig.shared.messageProperties.pinMessageTextSize)
    let maxSize = CGSize(width: contenttMaxW, height: CGFloat.greatestFiniteMagnitude)

    if let textModel = chatmodel as? MessageTextModel {
      // 文本消息最多显示 3 行
      let textSize = NSAttributedString.getRealLabelSize(textModel.attributeStr, bodyFont, maxSize, 3)
      height = textSize.height
    }

    if let textModel = chatmodel as? MessageRichTextModel {
      // 换行消息中的标题最多显示 1 行
      let titleSize = NSAttributedString.getRealLabelSize(textModel.titleAttributeStr, titleFont, maxSize, 1)
      height = titleSize.height

      // 换行消息中的内容最多显示 2 行
      let textSize = NSAttributedString.getRealLabelSize(textModel.attributeStr, bodyFont, maxSize, 2)
      height += textSize.height
    }

    height += 124

    if chatmodel.isReply == true {
      height += 12
    }

    return height
  }
}
