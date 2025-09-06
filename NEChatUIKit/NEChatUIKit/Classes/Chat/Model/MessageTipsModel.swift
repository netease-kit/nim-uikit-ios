
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objcMembers
open class MessageTipsModel: MessageContentModel {
  var text: String?

  public required init(message: V2NIMMessage?) {
    super.init(message: message)
    type = .tip

    resetMessage(message)
  }

  public func resetMessage(_ message: V2NIMMessage?) {
    if let msg = message {
      if msg.messageType == .MESSAGE_TYPE_NOTIFICATION {
        text = NotificationMessageUtils.textForNotification(message: msg)
        type = .notification
      } else if msg.messageType == .MESSAGE_TYPE_TIP {
        text = msg.text
        type = .tip
      }
    }

    var font: UIFont = .systemFont(ofSize: ChatUIConfig.shared.messageProperties.timeTextSize)
    if ChatMessageHelper.isAISender(message) {
      font = messageTextFont
    }

    let textSize = String.getRealSize(text, font, messageMaxSize)
    textWidth = textSize.width
    contentSize = textSize
    height = contentSize.height + chat_content_margin * 3

    // time
    if let time = timeContent, !time.isEmpty {
      height += chat_timeCellH
    }
  }
}
