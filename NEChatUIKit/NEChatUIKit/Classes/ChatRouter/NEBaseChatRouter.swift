
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NIMSDK
import ObjectiveC
import UIKit

private var conversationPresentationKey: UInt8 = 0

private final class NEConversationPresentationBlock: NSObject {
  let handler: (String, [String: Any]) -> Bool
  init(_ handler: @escaping (String, [String: Any]) -> Bool) {
    self.handler = handler
  }
}

@objcMembers
open class ChatRouter: NSObject {
  /// Reuses existing anchor/recovery handling for a retained adaptive detail.
  public static func applyPresentationParameters(_ parameters: [String: Any], to controller: UIViewController, reload: Bool) -> Bool {
    guard let chat = controller as? ChatViewController else { return false }
    chat.applyHistoryAnchor(parameters["anchor"] as? V2NIMMessage,
                            transferredNewMessages: parameters["onReceiveNewMsgs"] as? [V2NIMMessage] ?? [])
    if reload { chat.loadData() }
    return true
  }

  /// Optional presentation boundary. Unbinding restores the original Router behavior.
  /// The host must capture its shell weakly. No SDK or ViewModel ownership is transferred.
  public static func setConversationPresentationHandler(_ handler: ((String, [String: Any]) -> Bool)?, for navigationController: UINavigationController) {
    let value = handler.map { NEConversationPresentationBlock($0) }
    objc_setAssociatedObject(navigationController, &conversationPresentationKey, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  }

  public static func presentConversationIfHandled(route: String, parameters: [String: Any]) -> Bool {
    if parameters["ne_conversation_presentation_declined"] as? Bool == true { return false }
    guard Thread.isMainThread,
          let nav = parameters["nav"] as? UINavigationController,
          let block = objc_getAssociatedObject(nav, &conversationPresentationKey) as? NEConversationPresentationBlock else {
      return false
    }
    return block.handler(route, parameters)
  }

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
