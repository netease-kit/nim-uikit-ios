
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECommonKit
import NIMSDK

@objcMembers
open class MessageTextModel: MessageContentModel {
  public var attributeStr: NSMutableAttributedString?
  public var textHeight: CGFloat = 0

  public required init(message: V2NIMMessage?) {
    super.init(message: message)
    type = .text

    resetMessage(message)
  }

  public func resetMessage(_ message: V2NIMMessage?) {
    self.message = message

    if let text = message?.text, !text.isEmpty {
      attributeStr = NEEmotionTool.getAttWithStr(
        str: text,
        font: messageTextFont,
        color: messageTextColor
      )
    }

    // 解析 @，效果高亮
    if IMKitConfigCenter.shared.enableAtMessage {
      if let att = ChatMessageHelper.loadAtInMessage(message, attributeStr) {
        attributeStr = att
      }
    }

    resetHeight()
  }

  public func getTextSize(_ attributeStr: NSAttributedString?) -> CGSize {
    NSAttributedString.getRealTextViewSize(attributeStr ?? self.attributeStr, messageTextFont, messageMaxSize)
  }

  public func resetHeight(_ attributeStr: NSAttributedString? = nil) {
    let textSize = getTextSize(attributeStr)
    textHeight = ceil(textSize.height)
    textWidth = ceil(textSize.width)
    let contentSizeWidth = textWidth + chat_content_margin * 2
    let contentSizeHeight = textHeight + chat_content_margin * 2
    contentSize = CGSize(width: contentSizeWidth, height: contentSizeHeight)
    height = contentSizeHeight + chat_content_margin * 2 + fullNameHeight + chat_pin_height
  }

  public func resetWH(_ height: CGFloat, _ width: CGFloat = chat_content_maxW) {
    textHeight = ceil(height)
    textWidth = ceil(width)
    let contentSizeWidth = textWidth + chat_content_margin * 2
    let contentSizeHeight = textHeight + chat_content_margin * 2
    contentSize = CGSize(width: contentSizeWidth, height: contentSizeHeight)
    self.height = contentSizeHeight + chat_content_margin * 2 + fullNameHeight + chat_pin_height
  }

  /// 获取划词选中的文本（替换内置表情）
  /// - Returns: 选中的文本
  override open func selectText() -> String? {
    if let selectRange = selectRange {
      // 内置表情转为文本
      let text = NEEmotionTool.getTextWithAtt(attributeStr, selectRange)

      return text
    }

    return nil
  }
}
