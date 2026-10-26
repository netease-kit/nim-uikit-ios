
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NIMSDK

@objcMembers
open class MessageAIStreamModel: MessageTextModel {
  public required init(message: V2NIMMessage?) {
    super.init(message: message)
    type = .aiStreamText

    resetMessage(message)
  }

  override public func resetMessage(_ message: V2NIMMessage?) {
    self.message = message

    // 【服务器异常停止】模型返回可能为空
    // 替换文案：服务器繁忙，请稍后再试
    if message?.aiConfig?.aiStreamStatus == .MESSAGE_AI_STREAM_STATUS_ABORTED,
       message?.text?.isEmpty == true {
      message?.text = chatLocalizable("server_busy")
    }

    measureMarkdownForViewport()
    resetHeight()
    if ChatMessageHelper.isAIStreamLoading(message) {
      resetWH(24, 24)
    }
    offset = 0
  }

  /// Width changes only reparse presentation markup, without changing the
  /// stream status or writing fallback text into the SDK message.
  func measureMarkdownForViewport() {
    let NEMarkdownParser = NEMarkdownParser(font: .systemFont(ofSize: 16))
    NEMarkdownParser.code.textHighlightColor = .black
    // 表格宽度 = 消息最大宽度 - 气泡内边距（左右各 chat_cell_margin + 内边距 chat_content_margin）
    let contentMaxW = viewport?.maximumTextWidth ?? chat_content_maxW - chat_content_margin * 2
    NEMarkdownParser.table.maxWidth = contentMaxW
    // 图片宽度不超过气泡内容区域
    NEMarkdownParser.markdownImage.maxWidth = contentMaxW
    NEMarkdownParser.markdownImage.maxHeight = contentMaxW
//    NEMarkdownParser.code.font = UIFont(name: "Times New Roman", size: 16)
    let mulAttr = NEMarkdownParser.parse(message?.text ?? "")
    attributeStr = NSMutableAttributedString(attributedString: mulAttr)
  }

  override public func getTextSize(_ attributeStr: NSAttributedString?) -> CGSize {
    NSAttributedString.getRealTextViewSize(attributeStr ?? self.attributeStr, messageTextFont, messageMaxSize)
  }
}
