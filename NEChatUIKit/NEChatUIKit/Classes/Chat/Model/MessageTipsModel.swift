
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objcMembers
class MessageTipsModel: NSObject, MessageModel {
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
  var contentSize: CGSize
  var height: Float
  var shortName: String?
  var fullName: String?
  var avatar: String?
  var text: String?
  var isRevoked: Bool = false
  var replyedModel: MessageModel?
  var isRevokedText: Bool = false
  weak var tipMessage: NIMMessage?
  required init(message: NIMMessage?) {
    if let msg = message {
      if msg.messageType == .notification {
        text = NotificationMessageUtils.textForNotification(message: msg)
        type = .notification
      } else if msg.messageType == .tip {
        text = msg.text
        type = .tip
      }
    }
    tipMessage = message
    tipTimeStamp = message?.timestamp
    contentSize = CGSize(width: kScreenWidth, height: 35)
    height = 35
  }
}
