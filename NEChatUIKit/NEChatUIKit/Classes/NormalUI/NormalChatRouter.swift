
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK

public extension ChatRouter {
  static func register() {
    // pin
    Router.shared.register(PushPinMessageVCRouter) { param in
      let nav = param["nav"] as? UINavigationController
      guard let conversationId = param["conversationId"] as? String else {
        return
      }
      let pin = PinMessageViewController(conversationId: conversationId)
      nav?.pushViewController(pin, animated: true)
    }
    // sendMessage
    Router.shared.register(ChatAddFriendRouter) { param in
      if let text = param["text"] as? String,
         let sessionId = param["conversationId"] as? String {
        let msg = V2NIMMessage()
        msg.text = text

        let config = V2NIMMessageConfig()
        config.lastMessageUpdateEnabled = true
        config.onlineSyncEnabled = true
        config.unreadEnabled = true
        let param = V2NIMSendMessageParams()
        param.messageConfig = MessageUtils.messageConfig()
        NIMSDK.shared().v2MessageService.send(msg, conversationId: sessionId, params: param) { result in

        } failure: { error in
          NEALog.errorLog("ChatAddFriendRouter", desc: "send P2P message error:\(error.nserror.localizedDescription)")
        } progress: { _ in
        }
      }
    }

    // p2p
    Router.shared.register(PushP2pChatVCRouter) { param in
      print("param:\(param)")
      let nav = param["nav"] as? UINavigationController
      guard let conversationId = param["conversationId"] as? String else {
        return
      }
      let anchor = param["anchor"] as? V2NIMMessage
      let p2pChatVC = P2PChatViewController(conversationId: conversationId, anchor: anchor)

      for (i, vc) in (nav?.viewControllers ?? []).enumerated() {
        if vc.isKind(of: ChatViewController.self) {
          nav?.viewControllers[i] = p2pChatVC
          nav?.popToViewController(p2pChatVC, animated: true)
          return
        }
      }

      if let remove = param["removeUserVC"] as? Bool, remove {
        nav?.viewControllers.removeLast()
      }

      nav?.pushViewController(p2pChatVC, animated: true)
    }

    // group
    Router.shared.register(PushTeamChatVCRouter) { param in
      print("param:\(param)")
      let nav = param["nav"] as? UINavigationController
      guard let conversationId = param["conversationId"] as? String else {
        return
      }

      let anchor = param["anchor"] as? V2NIMMessage
      let groupVC = TeamChatViewController(conversationId: conversationId, anchor: anchor)
      for (i, vc) in (nav?.viewControllers ?? []).enumerated() {
        if vc.isKind(of: ChatViewController.self) {
          nav?.viewControllers[i] = groupVC
          nav?.popToViewController(groupVC, animated: true)
          return
        }
      }
      nav?.pushViewController(groupVC, animated: true)
    }
  }
}
