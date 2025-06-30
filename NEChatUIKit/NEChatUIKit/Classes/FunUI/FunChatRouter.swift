
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

      let count = nav?.viewControllers.count ?? 0
      nav?.pushViewController(p2pChatVC, animated: true)

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: DispatchWorkItem(block: {
        if let remove = param["removeUserVC"] as? Bool, remove {
          if count > 1,
             nav?.viewControllers.last?.isKind(of: ChatViewController.self) == true {
            nav?.viewControllers.remove(at: count - 1)
          }
        }
      }))
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
          if vc.isKind(of: FunTeamChatViewController.self) {
            (vc as? ChatViewController)?.viewModel.anchor = anchor
            (vc as? ChatViewController)?.loadData()
            nav?.popToViewController(vc, animated: true)
          } else {
            nav?.viewControllers[i] = groupVC
            nav?.popToViewController(groupVC, animated: true)
          }
          return
        }
      }

      let count = nav?.viewControllers.count ?? 0
      nav?.pushViewController(groupVC, animated: true)

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: DispatchWorkItem(block: {
        if let remove = param["removeTeamVC"] as? Bool, remove {
          if count > 1,
             nav?.viewControllers.last?.isKind(of: ChatViewController.self) == true {
            nav?.viewControllers.remove(at: count - 1)
          }
        }
      }))
    }
  }
}
