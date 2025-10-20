// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIM2Kit
import NECoreKit
import NIMSDK

public extension TeamRouter {
  static func registerFun() {
    registerCommon(icUrls: iconUrlsFun)

    Router.shared.register(TeamJoinTeamRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let animated = param["animated"] as? Bool ?? true
      let joinTeam = FunJoinTeamViewController()
      nav?.pushViewController(joinTeam, animated: animated)
    }

    Router.shared.register(TeamDetailInfoPageRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        let animated = param["animated"] as? Bool ?? true
        if let team = param["team"] as? V2NIMTeam {
          let teamInfoVC = FunTeamDetailViewController(nim_team: team)
          nav.pushViewController(teamInfoVC, animated: animated)
        }
      }
    }

    Router.shared.register(TeamSettingViewRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let animated = param["animated"] as? Bool ?? true
      let teamId = param["teamid"] as? String
      let teamSetting = FunTeamSettingViewController()
      teamSetting.teamId = teamId
      nav?.pushViewController(teamSetting, animated: animated)
    }

    Router.shared.register(SearchMessageRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let animated = param["animated"] as? Bool ?? true
      if let teamId = param["teamId"] as? String {
        let searchMsgCtrl = FunTeamHistoryMessageController(teamId: teamId)
        if let info = param["teamInfo"] as? NETeamInfoModel {
          searchMsgCtrl.viewModel.teamInfoModel = info
        }
        nav?.pushViewController(searchMsgCtrl, animated: animated)
      }
    }
  }
}
