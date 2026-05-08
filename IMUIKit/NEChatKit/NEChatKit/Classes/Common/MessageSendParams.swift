//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

/// 消息发送参数
@objc
@objcMembers
open class MessageSendParams: NSObject {
  // 即将发送的消息
  public var message: V2NIMMessage

  // 会话 id
  public var conversationId: String?

  // 消息发送参数
  public var params: V2NIMSendMessageParams?

  public init(message: V2NIMMessage, conversationId: String? = nil, params: V2NIMSendMessageParams? = nil) {
    self.message = message
    self.conversationId = conversationId
    self.params = params
  }
}
