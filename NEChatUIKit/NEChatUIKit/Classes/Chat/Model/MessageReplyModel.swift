
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objcMembers
class MessageReplyModel: MessageContentModel {
  let targetHeight = 26.0
  public var text: String?
  public var targetText: String?
  public var targetMessage: NIMMessage?
  required init(message: NIMMessage?, targetMessage: NIMMessage?) {
    super.init(message: message)
    self.targetMessage = targetMessage
    type = .reply
    text = message?.text
//        targetText = "|" + targetMessage?.from + ": "
    let textSize = String.getTextRectSize(
      text ?? "",
      font: DefaultTextFont(16),
      size: CGSize(width: qChat_content_maxW, height: CGFloat.greatestFiniteMagnitude)
    )
    var h = qChat_min_h
    if textSize.height > qChat_min_h {
      h = textSize.height + 32 + targetHeight
    }
    contentSize = CGSize(width: textSize.width + qChat_cell_margin * 2, height: h)
    height = Float(contentSize.height + qChat_margin) + fullNameHeight
  }

  public required init(message: NIMMessage?) {
    fatalError("init(message:) has not been implemented")
  }

//    func replyTextWithMessage(_ message:) -> <#return type#> {
//        <#function body#>
//    }
}
