
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit
import NIMSDK

@objcMembers
open class MessageRichTextModel: MessageTextModel {
  public var titleText: String?
  public var titleAttributeStr: NSMutableAttributedString?
  public var titleTextHeight: CGFloat = 0

  public required init(message: V2NIMMessage?) {
    guard let data = NECustomUtils.dataOfCustomMessage(message?.attachment),
          let title = data["title"] as? String else {
      super.init(message: message)
      return
    }

    titleText = title
    let body = (data["body"] as? String) ?? ""
    message?.text = body
    super.init(message: message)
    type = .custom
    customType = customRichTextType

    let font = UIFont.systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.messageTextSize, weight: .semibold)
    titleAttributeStr = NEEmotionTool.getAttWithStr(
      str: title,
      font: font
    )

    let textSize = NSAttributedString.getRealSize(titleAttributeStr, messageTextFont, messageMaxSize)
    titleTextHeight = textSize.height

    let contentSizeWidth = max(textWidth, textSize.width) + chat_content_margin * 2
    let contentSizeHeight = contentSize.height + titleTextHeight + (body.isEmpty ? 0 : chat_content_margin)
    contentSize = CGSize(width: contentSizeWidth, height: contentSizeHeight)
    height = contentSizeHeight + chat_content_margin * 2 + fullNameHeight + chat_pin_height
  }

  /// 获取划词选中的文本（替换内置表情）
  /// - Returns: 选中的文本
  override open func selectText() -> String? {
    if attributeStr == nil, titleText != nil {
      if let selectRange = selectRange {
        // 内置表情转为文本
        let text = NEEmotionTool.getTextWithAtt(titleAttributeStr, selectRange)

        return text
      }
    } else {
      return super.selectText()
    }

    return nil
  }
}
