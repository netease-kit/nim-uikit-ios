
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK

public extension ChatRouter {
  static func registerFun() {
    registerCommon()

    // pin
    Router.shared.register(PushPinMessageVCRouter) { param in
      let nav = param["nav"] as? UINavigationController
      guard let conversationId = param["conversationId"] as? String else {
        return
      }
      let pin = FunPinMessageViewController(conversationId: conversationId)
      nav?.pushViewController(pin, animated: true)
    }

    // p2p
    Router.shared.register(PushP2pChatVCRouter) { param in
      print("param:\(param)")
      let nav = param["nav"] as? UINavigationController
      guard let conversationId = param["conversationId"] as? String else {
        return
      }
      let anchor = param["anchor"] as? V2NIMMessage
      let p2pChatVC = FunP2PChatViewController(conversationId: conversationId, anchor: anchor)

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
      let groupVC = FunTeamChatViewController(conversationId: conversationId, anchor: anchor)
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
