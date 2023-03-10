
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objcMembers
class MessageTextModel: MessageContentModel {
  public var attributeStr: NSAttributedString?

  required init(message: NIMMessage?) {
    super.init(message: message)
    type = .text

    attributeStr = NEEmotionTool.getAttWithStr(
      str: message?.text ?? "",
      font: NEKitChatConfig.shared.ui.messageFont
    )

    let textSize = NEChatUITool.getSizeWithAtt(
      att: attributeStr ?? NSAttributedString(string: ""),
      font: DefaultTextFont(16),
      maxSize: CGSize(width: qChat_content_maxW, height: CGFloat.greatestFiniteMagnitude)
    )

    var h = qChat_min_h
//        if textSize.height > qChat_min_h {
//            h = textSize.height + 32
//        }
    h = textSize.height + 24
    contentSize = CGSize(width: textSize.width + qChat_cell_margin * 2, height: h)

    height = Float(contentSize.height + qChat_margin) + fullNameHeight

//    print(">>text:\(message?.text) height:\(height)")
  }
}
