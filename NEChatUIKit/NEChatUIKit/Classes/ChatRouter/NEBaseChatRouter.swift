
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECommonKit

@objcMembers
open class ChatRouter: NSObject {
  public static func registerCommon() {
    // sendMessage
    Router.shared.register(ChatAddFriendRouter) { param in
      if let text = param["text"] as? String,
         let cid = param["conversationId"] as? String {
        let helloMessage = MessageUtils.textMessage(text: text)
        ChatRepo.shared.sendMessage(message: helloMessage, conversationId: cid) { result, error, pro in
          NEALog.errorLog("ChatAddFriendRouter", desc: "send hello message error:\(error?.localizedDescription ?? "nil")")
        }
      }
    }
  }
}
