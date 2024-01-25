
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objcMembers
open class MessageTipsModel: MessageContentModel {
  var text: String?

  public required init(message: NIMMessage?) {
    super.init(message: message)
    commonInit()
  }

  func setText() {
    if let msg = message {
      if msg.messageType == .notification {
        text = NotificationMessageUtils.textForNotification(message: msg)
        type = .notification
      } else if msg.messageType == .tip {
        text = msg.text
        type = .tip
      }
    }
  }

  func commonInit() {
    setText()
    let font: UIFont = .systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.timeTextSize)

    contentSize = text?.finalSize(font, CGSize(width: chat_content_maxW, height: CGFloat.greatestFiniteMagnitude)) ?? .zero
    height = ceil(contentSize.height)

    // time
    if let time = timeContent, !time.isEmpty {
      height += chat_timeCellH
    }
  }
}
