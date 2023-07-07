
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objcMembers
class MessageTipsModel: NSObject, MessageModel {
  var offset: CGFloat = 0

  func cellHeight() -> CGFloat {
    CGFloat(height) + offset
  }

  var tipTimeStamp: TimeInterval?

  var isReplay: Bool = false

  var pinToAccount: String?
  var pinFromAccount: String?
  var isPined: Bool = false
  var pinAccount: String?
  var pinShowName: String?
  var replyText: String?
  var type: MessageType = .tip
  var message: NIMMessage?
  var contentSize: CGSize = .zero
  var height: Float = 28
  var shortName: String?
  var fullName: String?
  var avatar: String?
  var text: String?
  var isRevoked: Bool = false
  var replyedModel: MessageModel?
  var isRevokedText: Bool = false
  weak var tipMessage: NIMMessage?

  func commonInit(message: NIMMessage?) {
    if let msg = message {
      if msg.messageType == .notification {
        text = NotificationMessageUtils.textForNotification(message: msg)
        type = .notification
      } else if msg.messageType == .tip {
        text = msg.text
        type = .tip
      }

      tipMessage = msg
      tipTimeStamp = msg.timestamp
    }

    var font: UIFont = .systemFont(ofSize: NEKitChatConfig.shared.ui.timeTextSize)

    contentSize = String.getTextRectSize(text ?? "",
                                         font: font,
                                         size: CGSize(width: chat_text_maxW, height: CGFloat.greatestFiniteMagnitude))
    height = Float(max(contentSize.height + chat_content_margin, 28))
  }

  required init(message: NIMMessage?) {
    super.init()
    commonInit(message: message)
  }

  init(message: NIMMessage?, initType: MessageType = .tip, initText: String? = nil) {
    super.init()
    type = initType
    text = initText
    commonInit(message: message)
  }

  public func resetNotiText() {
    if let msg = tipMessage {
      if msg.messageType == .notification {
        text = NotificationMessageUtils.textForNotification(message: msg)
        type = .notification
      }
    }
  }
}
