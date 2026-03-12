
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK

public extension ChatRouter {
  static func registerFun() {
    registerCommon()

    // pin
    Router.shared.register(PushPinMessageVCRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let animated = param["animated"] as? Bool ?? true
      guard let conversationId = param["conversationId"] as? String else {
        return
      }
      let pin = FunPinMessageViewController(conversationId: conversationId)
      nav?.pushViewController(pin, animated: animated)
    }

    // p2p
    Router.shared.register(PushP2pChatVCRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let animated = param["animated"] as? Bool ?? true
      guard let conversationId = param["conversationId"] as? String else {
        return
      }
      let anchor = param["anchor"] as? V2NIMMessage
      let onReceiveNewMsgs = param["onReceiveNewMsgs"] as? [V2NIMMessage]
      let p2pChatVC = FunP2PChatViewController(conversationId: conversationId, anchor: anchor)

      // 检查导航栈中是否已有 ChatViewController
      var hasChatVCInStack = false
      for (i, vc) in (nav?.viewControllers ?? []).enumerated() {
        if vc.isKind(of: ChatViewController.self) {
          hasChatVCInStack = true
          if vc.isKind(of: FunP2PChatViewController.self) {
            // 复用栈中已有的 FunP2PChatViewController，不需要设置 pendingNewMessages
            // 因为该 VC 的 onReceiveNewMsgs 已经是正确的
            // 注意：不要在这里设置 pendingNewMessages，否则会导致数量翻倍
            (vc as? ChatViewController)?.viewModel.anchor = anchor
            (vc as? ChatViewController)?.loadData()
            nav?.popToViewController(vc, animated: animated)
          } else {
            // 栈中有其他类型的 ChatViewController，需要替换为 FunP2PChatViewController
            // 此时需要传递 pendingNewMessages
            if let newMsgs = onReceiveNewMsgs, !newMsgs.isEmpty {
              p2pChatVC.pendingNewMessages = newMsgs
            }
            nav?.viewControllers[i] = p2pChatVC
            nav?.popToViewController(p2pChatVC, animated: animated)
          }
          return
        }
      }

      // 无论如何都先设置 pendingNewMessages（如果有的话）
      if let newMsgs = onReceiveNewMsgs, !newMsgs.isEmpty {
        p2pChatVC.pendingNewMessages = newMsgs
      }

      var count = nav?.viewControllers.count ?? 0
      nav?.pushViewController(p2pChatVC, animated: animated)

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: DispatchWorkItem(block: {
        if let remove = param["removeUserVC"] as? Bool, remove {
          while count > 1,
                nav?.viewControllers.last?.isKind(of: ChatViewController.self) == true {
            nav?.viewControllers.remove(at: count - 1)
            count -= 1
          }
        }
      }))
    }

    // group
    Router.shared.register(PushTeamChatVCRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let animated = param["animated"] as? Bool ?? true
      guard let conversationId = param["conversationId"] as? String else {
        return
      }

      let anchor = param["anchor"] as? V2NIMMessage
      let onReceiveNewMsgs = param["onReceiveNewMsgs"] as? [V2NIMMessage]
      let groupVC = FunTeamChatViewController(conversationId: conversationId, anchor: anchor)

      // 检查导航栈中是否已有 ChatViewController
      var hasChatVCInStack = false
      for (i, vc) in (nav?.viewControllers ?? []).enumerated() {
        if vc.isKind(of: ChatViewController.self) {
          hasChatVCInStack = true
          if vc.isKind(of: FunTeamChatViewController.self) {
            // 复用栈中已有的 FunTeamChatViewController，不需要设置 pendingNewMessages
            // 因为该 VC 的 onReceiveNewMsgs 已经是正确的
            // 注意：不要在这里设置 pendingNewMessages，否则会导致数量翻倍
            (vc as? ChatViewController)?.viewModel.anchor = anchor
            (vc as? ChatViewController)?.loadData()
            nav?.popToViewController(vc, animated: animated)
          } else {
            // 栈中有其他类型的 ChatViewController，需要替换为 FunTeamChatViewController
            // 此时需要传递 pendingNewMessages
            if let newMsgs = onReceiveNewMsgs, !newMsgs.isEmpty {
              groupVC.pendingNewMessages = newMsgs
            }
            nav?.viewControllers[i] = groupVC
            nav?.popToViewController(groupVC, animated: animated)
          }
          return
        }
      }

      let count = nav?.viewControllers.count ?? 0
      nav?.pushViewController(groupVC, animated: animated)

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: DispatchWorkItem(block: {
        if let remove = param["removeTeamVC"] as? Bool, remove {
          if count > 1,
             nav?.viewControllers.last?.isKind(of: ChatViewController.self) == true {
            nav?.viewControllers.remove(at: count - 1)
          }
        }
      }))
    }

    Router.shared.register(SearchMessageRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let animated = param["animated"] as? Bool ?? true
      if let conversationId = param["conversationId"] as? String {
        let searchMsgCtrl = FunHistoryMessageController(conversationId: conversationId)
        nav?.pushViewController(searchMsgCtrl, animated: animated)
      }
    }
  }
}
