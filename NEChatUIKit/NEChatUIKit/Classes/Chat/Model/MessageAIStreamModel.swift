
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECommonKit
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

    let NEMarkdownParser = NEMarkdownParser(font: .systemFont(ofSize: 16))
    NEMarkdownParser.code.textHighlightColor = .black
//    NEMarkdownParser.code.font = UIFont(name: "Times New Roman", size: 16)
    let mulAttr = NEMarkdownParser.parse(message?.text ?? "")
    attributeStr = NSMutableAttributedString(attributedString: mulAttr)
    resetHeight()
    offset = 0
  }

  override public func getTextSize(_ attributeStr: NSAttributedString?) -> CGSize {
    NSAttributedString.getRealTextViewSize(attributeStr ?? self.attributeStr, messageTextFont, messageMaxSize)
  }
}
