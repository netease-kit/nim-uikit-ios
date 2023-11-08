
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIMKit
import NECoreKit
import NIMSDK

public extension ContactRouter {
  static func registerFun() {
    Router.shared.register(ContactUserSelectRouter) { param in
      print("param:\(param)")
      let nav = param["nav"] as? UINavigationController
      let contactSelectVC = FunContactsSelectedViewController()
      if let fiters = param["filters"] as? Set<String> {
        contactSelectVC.filterUsers = fiters
      }
      if let limit = param["limit"] as? Int, limit > 0 {
        contactSelectVC.limit = limit
      }
      if let uid = param["uid"] as? String {
        contactSelectVC.userId = uid
      }
      nav?.pushViewController(contactSelectVC, animated: true)
    }

    Router.shared.register(ContactAddFriendRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let findFrined = FunFindFriendViewController()
      nav?.pushViewController(findFrined, animated: true)
    }

    Router.shared.register(ContactUserInfoPageRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        if let user = param["user"] as? User {
          let userInfoVC = FunContactUserViewController(user: user)
          nav.pushViewController(userInfoVC, animated: true)
        } else if let nimUser = param["nim_user"] as? User {
          let userInfoVC = FunContactUserViewController(user: nimUser)
          nav.pushViewController(userInfoVC, animated: true)
        } else if let uid = param["uid"] as? String {
          let userInfoVC = FunContactUserViewController(uid: uid)
          nav.pushViewController(userInfoVC, animated: true)
        }
      }
    }

    Router.shared.register(ContactTeamListRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        let team = FunTeamListViewController()
        team.isClickCallBack = true
        nav.pushViewController(team, animated: true)
      }
    }
  }
}
