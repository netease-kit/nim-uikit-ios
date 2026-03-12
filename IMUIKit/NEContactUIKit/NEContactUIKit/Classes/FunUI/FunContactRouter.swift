
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIM2Kit
import NECoreKit
import NIMSDK

public extension ContactRouter {
  static func registerFun() {
    Router.shared.register(ContactUserSelectRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let animated = param["animated"] as? Bool ?? true
      let filters = param["filters"] as? Set<String>
      let contactSelectVC = FunContactSelectedViewController(filterUsers: filters)
      if let limit = param["limit"] as? Int, limit > 0 {
        contactSelectVC.limit = limit
      }
      if let uid = param["uid"] as? String {
        contactSelectVC.userId = uid
      }
      nav?.pushViewController(contactSelectVC, animated: animated)
    }

    // 携带数字人的成员选择页面
    Router.shared.register(ContactFusionSelectRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let animated = param["animated"] as? Bool ?? true
      let userFilters = param["filters"] as? Set<String>
      let contactSelectedPageController = FunContactSelectedPageController(filterUsers: userFilters)
      if let limit = param["limit"] as? Int, limit > 0 {
        contactSelectedPageController.limit = limit
      }
      if let uid = param["uid"] as? String {
        contactSelectedPageController.userId = uid
      }
      nav?.pushViewController(contactSelectedPageController, animated: animated)
    }

    // 转发选择页面
    Router.shared.register(ForwardMultiSelectRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let animated = param["animated"] as? Bool ?? true
      let filters = param["filters"] as? Set<String>
      let contactSelectVC = FunMultiSelectViewController(filterUsers: filters)
      contactSelectVC.modalPresentationStyle = .formSheet
      if let limit = param["limit"] as? Int, limit > 0 {
        contactSelectVC.limit = limit
      }
      if let uid = param["uid"] as? String {
        contactSelectVC.userId = uid
      }
      nav?.present(contactSelectVC, animated: animated)
    }

    Router.shared.register(ContactAddFriendRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let animated = param["animated"] as? Bool ?? true
      let findFrined = FunFindFriendViewController()
      nav?.pushViewController(findFrined, animated: animated)
    }

    Router.shared.register(ContactUserInfoPageRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        let animated = param["animated"] as? Bool ?? true
        if let user = param["user"] as? NEUserWithFriend {
          let userInfoVC = FunContactUserViewController(user: user)
          nav.pushViewController(userInfoVC, animated: animated)
        } else if let nimUser = param["nim_user"] as? V2NIMUser {
          let userInfoVC = FunContactUserViewController(nim_user: nimUser)
          nav.pushViewController(userInfoVC, animated: animated)
        } else if let uid = param["uid"] as? String {
          let userInfoVC = FunContactUserViewController(accountId: uid)
          nav.pushViewController(userInfoVC, animated: animated)
        }
      }
    }

    Router.shared.register(ContactPageRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        let animated = param["animated"] as? Bool ?? true
        let contactVC = FunContactViewController()
        nav.pushViewController(contactVC, animated: animated)
      }
    }

    Router.shared.register(ValidationMessageRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        let animated = param["animated"] as? Bool ?? true
        let validationController = FunValidationPageController()
        nav.pushViewController(validationController, animated: animated)
      }
    }

    Router.shared.register(ContactBlackListRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        let animated = param["animated"] as? Bool ?? true
        let blackVC = FunBlackListViewController()
        nav.pushViewController(blackVC, animated: animated)
      }
    }
    Router.shared.register(ContactAIUserListRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        let animated = param["animated"] as? Bool ?? true
        let blackVC = FunAIUserController()
        nav.pushViewController(blackVC, animated: animated)
      }
    }

    Router.shared.register(ContactTeamListRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        let animated = param["animated"] as? Bool ?? true
        let team = FunTeamListViewController()

        if let isClickCallBack = param["isClickCallBack"] as? Bool {
          team.isClickCallBack = isClickCallBack
        }

        nav.pushViewController(team, animated: animated)
      }
    }
  }
}
