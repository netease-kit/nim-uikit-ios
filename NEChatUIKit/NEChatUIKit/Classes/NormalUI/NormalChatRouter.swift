
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK

public extension ChatRouter {
  static func register() {
    // pin
    Router.shared.register(PushPinMessageVCRouter) { param in
      let nav = param["nav"] as? UINavigationController
      guard let session = param["session"] as? NIMSession else {
        return
      }
      let pin = PinMessageViewController(session: session)
      nav?.pushViewController(pin, animated: true)
    }
    // sendMessage
    Router.shared.register(ChatAddFriendRouter) { param in
      if let text = param["text"] as? String,
         let sessionId = param["sessionId"] as? String,
         let sessionType = param["sessionType"] as? NIMSessionType {
        let msg = NIMMessage()
        msg.text = text
        let session = NIMSession(sessionId, type: sessionType)
        NIMSDK.shared().chatManager.send(msg, to: session) { error in
          if let err = error {
            NELog.errorLog("ChatAddFriendRouter", desc: "send P2P message error:\(err.localizedDescription)")
          }
        }
      }
    }

    // p2p
    Router.shared.register(PushP2pChatVCRouter) { param in
      print("param:\(param)")
      let nav = param["nav"] as? UINavigationController
      guard let session = param["session"] as? NIMSession else {
        return
      }
      let anchor = param["anchor"] as? NIMMessage
      let p2pChatVC = P2PChatViewController(session: session, anchor: anchor)

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
      guard let session = param["session"] as? NIMSession else {
        return
      }

      let anchor = param["anchor"] as? NIMMessage
      let groupVC = GroupChatViewController(session: session, anchor: anchor)
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
