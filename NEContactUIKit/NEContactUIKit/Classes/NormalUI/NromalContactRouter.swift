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
      let animated = param["animated"] as? Bool ?? true
      let filters = param["filters"] as? Set<String>
      let contactSelectVC = ContactSelectedViewController(filterUsers: filters)
      if let limit = param["limit"] as? Int, limit > 0 {
        contactSelectVC.limit = limit
      }
      if let uid = param["uid"] as? String {
        contactSelectVC.userId = uid
      }
      nav?.pushViewController(contactSelectVC, animated: animated)
    }

    // 携带机器人的成员选择页面
    Router.shared.register(ContactFusionSelectRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let animated = param["animated"] as? Bool ?? true
      let userFilters = param["filters"] as? Set<String>
      let contactSelectedPageController = ContactSelectedPageController(filterUsers: userFilters)
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
      let contactSelectVC = MultiSelectViewController(filterUsers: filters)
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
      let findFrined = FindFriendViewController()
      nav?.pushViewController(findFrined, animated: animated)
    }

    Router.shared.register(ContactUserInfoPageRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        let animated = param["animated"] as? Bool ?? true
        let isRobot = param["isRobot"] as? Bool ?? false
        if let user = param["user"] as? NEUserWithFriend {
          let userInfoVC = ContactUserViewController(user: user)
          userInfoVC.isRobot = isRobot
          nav.pushViewController(userInfoVC, animated: animated)
        } else if let nimUser = param["nim_user"] as? V2NIMUser {
          let userInfoVC = ContactUserViewController(nim_user: nimUser)
          userInfoVC.isRobot = isRobot
          nav.pushViewController(userInfoVC, animated: animated)
        } else if let uid = param["uid"] as? String {
          let userInfoVC = ContactUserViewController(accountId: uid)
          userInfoVC.isRobot = isRobot
          nav.pushViewController(userInfoVC, animated: animated)
        }
      }
    }

    Router.shared.register(ContactPageRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        let animated = param["animated"] as? Bool ?? true
        let contactVC = ContactViewController()
        nav.pushViewController(contactVC, animated: animated)
      }
    }

    Router.shared.register(ValidationMessageRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        let animated = param["animated"] as? Bool ?? true
        let validationController = ValidationPageController()
        nav.pushViewController(validationController, animated: animated)
      }
    }

    Router.shared.register(ContactBlackListRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        let animated = param["animated"] as? Bool ?? true
        let blackVC = BlackListViewController()
        nav.pushViewController(blackVC, animated: animated)
      }
    }

    Router.shared.register(ContactAIUserListRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        let animated = param["animated"] as? Bool ?? true
        let blackVC = AIUserController()
        nav.pushViewController(blackVC, animated: animated)
      }
    }

    Router.shared.register(ContactAIRobotListRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        let animated = param["animated"] as? Bool ?? true
        let robotVC = AIRobotController()
        nav.pushViewController(robotVC, animated: animated)
      }
    }

    Router.shared.register(ContactCreateAIRobotRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        let animated = param["animated"] as? Bool ?? true
        let createVC = CreateAIRobotController()
        if let bot = param["bot"] as? V2NIMUserAIBot {
          // 编辑模式：预填 bot、注入保存回调（用于刷新 Detail 页）
          createVC.editingBot = bot
          if let onEditSaved = param["onEditSaved"] as? (V2NIMUserAIBot) -> Void {
            createVC.onEditSavedCallback = onEditSaved
          }
        } else {
          // 新建模式：注入默认昵称（Bot_N，N 跟随现有机器人数量自增）
          if let defaultName = param["defaultName"] as? String {
            createVC.defaultName = defaultName
          }
          // 来自绑定页的新建：注入 qrCode 以便创建后自动绑定
          if let qrCode = param["autoBindQrCode"] as? String {
            createVC.autoBindQrCode = qrCode
          }
          if let sourceVC = param["autoBindSourceVC"] as? UIViewController {
            createVC.autoBindSourceVC = sourceVC
          }
        }
        nav.pushViewController(createVC, animated: animated)
      }
    }

    Router.shared.register(ContactRobotChatCardRouter) { param in
      if let nav = param["nav"] as? UINavigationController,
         let bot = param["bot"] as? V2NIMUserAIBot {
        let animated = param["animated"] as? Bool ?? true
        let cardVC = RobotChatCardController(bot: bot)
        nav.pushViewController(cardVC, animated: animated)
      }
    }

    Router.shared.register(ContactRobotNicknameEditRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        let animated = param["animated"] as? Bool ?? true
        let editVC: NEBaseRobotNicknameEditController = RobotNicknameEditController()
        editVC.currentName = param["currentName"] as? String ?? ""
        if let onSaved = param["onSaved"] as? (String) -> Void {
          editVC.onSaved = onSaved
        }
        nav.pushViewController(editVC, animated: animated)
      }
    }

    Router.shared.register(ContactAIRobotDetailRouter) { param in
      if let nav = param["nav"] as? UINavigationController,
         let bot = param["bot"] as? V2NIMUserAIBot {
        let animated = param["animated"] as? Bool ?? true
        let detailVC = AIRobotDetailController(bot: bot)
        nav.pushViewController(detailVC, animated: animated)
      }
    }

    Router.shared.register(ContactAIRobotConfigRouter) { param in
      if let nav = param["nav"] as? UINavigationController,
         let bot = param["bot"] as? V2NIMUserAIBot {
        let animated = param["animated"] as? Bool ?? true
        let configVC = AIRobotConfigController(bot: bot)
        nav.pushViewController(configVC, animated: animated)
      }
    }

    Router.shared.register(ContactAIRobotBindRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        let animated = param["animated"] as? Bool ?? true
        // 解析扫码 JSON，校验过期时间
        if let scanJSON = param["qrCode"] as? String {
          let result = NEBaseAIRobotBindController.parseQrCodeJSON(scanJSON)
          if let errorMessage = result.errorMessage {
            // 已过期：Toast 提示，不跳转
            nav.topViewController?.showToast(errorMessage)
            return
          }
          guard let qrCode = result.qrCode else {
            // 不符合机器人二维码格式：提示扫码失败
            nav.topViewController?.showToast(localizable("scan_qr_fail"))
            return
          }
          let bindVC = AIRobotBindController()
          bindVC.qrCode = qrCode
          if let prevAccid = param["previousBoundAccid"] as? String {
            bindVC.viewModel.previousBoundAccid = prevAccid
          }
          nav.pushViewController(bindVC, animated: animated)
        }
      }
    }

    Router.shared.register(ContactTeamListRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        let animated = param["animated"] as? Bool ?? true
        let team = TeamListViewController()
        if let isClickCallBack = param["isClickCallBack"] as? Bool {
          team.isClickCallBack = isClickCallBack
        }
        nav.pushViewController(team, animated: animated)
      }
    }
  }
}
