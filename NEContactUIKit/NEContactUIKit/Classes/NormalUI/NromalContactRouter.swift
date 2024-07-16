
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIM2Kit
import NECoreKit
import NIMSDK

public extension ContactRouter {
  static func register() {
    Router.shared.register(ContactUserSelectRouter) { param in
      print("param:\(param)")
      let nav = param["nav"] as? UINavigationController
      let filters = param["filters"] as? Set<String>
      let contactSelectVC = ContactSelectedViewController(filterUsers: filters)
      if let limit = param["limit"] as? Int, limit > 0 {
        contactSelectVC.limit = limit
      }
      if let uid = param["uid"] as? String {
        contactSelectVC.userId = uid
      }
      nav?.pushViewController(contactSelectVC, animated: true)
    }

    // 携带机器人的成员选择页面
    Router.shared.register(ContactFusionSelectRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let userFilters = param["filters"] as? Set<String>
      let contactSelectedPageController = ContactSelectedPageController(filterUsers: userFilters)
      if let limit = param["limit"] as? Int, limit > 0 {
        contactSelectedPageController.limit = limit
      }
      if let uid = param["uid"] as? String {
        contactSelectedPageController.userId = uid
      }
      nav?.pushViewController(contactSelectedPageController, animated: true)
    }

    // 转发选择页面
    Router.shared.register(ForwardMultiSelectRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let filters = param["filters"] as? Set<String>
      let contactSelectVC = MultiSelectViewController(filterUsers: filters)
      if let limit = param["limit"] as? Int, limit > 0 {
        contactSelectVC.limit = limit
      }
      if let uid = param["uid"] as? String {
        contactSelectVC.userId = uid
      }
      nav?.present(contactSelectVC, animated: true)
    }

    Router.shared.register(ContactAddFriendRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let findFrined = FindFriendViewController()
      nav?.pushViewController(findFrined, animated: true)
    }

    Router.shared.register(ContactUserInfoPageRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        if let user = param["user"] as? NEUserWithFriend {
          let userInfoVC = ContactUserViewController(user: user)
          nav.pushViewController(userInfoVC, animated: true)
        } else if let nimUser = param["nim_user"] as? V2NIMUser {
          let userInfoVC = ContactUserViewController(nim_user: nimUser)
          nav.pushViewController(userInfoVC, animated: true)
        } else if let uid = param["uid"] as? String {
          let userInfoVC = ContactUserViewController(uid: uid)
          nav.pushViewController(userInfoVC, animated: true)
        }
      }
    }

    Router.shared.register(ContactPageRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        let contactVC = ContactViewController()
        nav.pushViewController(contactVC, animated: true)
      }
    }

    Router.shared.register(ValidationMessageRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        let validationController = ValidationMessageViewController()
        nav.pushViewController(validationController, animated: true)
      }
    }

    Router.shared.register(ContactBlackListRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        let blackVC = BlackListViewController()
        nav.pushViewController(blackVC, animated: true)
      }
    }

    Router.shared.register(ContactAIUserListRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        let blackVC = AIUserController()
        nav.pushViewController(blackVC, animated: true)
      }
    }

    Router.shared.register(ContactTeamListRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        let team = TeamListViewController()

        if let isClickCallBack = param["isClickCallBack"] as? Bool {
          team.isClickCallBack = isClickCallBack
        }

        nav.pushViewController(team, animated: true)
      }
    }
  }
}
