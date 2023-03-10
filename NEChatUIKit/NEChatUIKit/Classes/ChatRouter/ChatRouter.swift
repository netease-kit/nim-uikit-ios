
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
import NECommonKit

@objcMembers
public class ChatRouter: NSObject {
  public static func register() {
    // p2p
    Router.shared.register(PushP2pChatVCRouter) { param in
      print("param:\(param)")
      let nav = param["nav"] as? UINavigationController
      guard let session = param["session"] as? NIMSession else {
        return
      }
      let p2pChatVC = P2PChatViewController(session: session)
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
        if vc.isMember(of: GroupChatViewController.self) {
          nav?.viewControllers[i] = groupVC
          nav?.popToViewController(groupVC, animated: true)
          return
        }
      }
      nav?.pushViewController(groupVC, animated: true)
    }
  }

  public static func setupInit() {
    NIMKitFileLocationHelper.setStaticAppkey(NIMSDK.shared().appKey())
    NIMKitFileLocationHelper.setStaticUserId(NIMSDK.shared().loginManager.currentAccount())
  }
}
