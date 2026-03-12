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

    Router.shared.register(TeamMemberSelectViewRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let animated = param["animated"] as? Bool ?? true
      let teamId = param["teamId"] as? String
      let navTitle = param["navTitle"] as? String
      let memberLimit = param["memberLimit"] as? Int ?? 1
      let block = param["selectMemberBlock"] as? NESelectTeamMemberBlock
      let showAllMembers = param["showAllMembers"] as? Bool ?? false
      let teamSelect = FunTeamMemberSelectController()
      teamSelect.teamId = teamId
      teamSelect.title = navTitle
      teamSelect.selectCountLimit = memberLimit
      teamSelect.selectMemberBlock = block
      teamSelect.showAllMembers = showAllMembers
      nav?.pushViewController(teamSelect, animated: animated)
    }
  }
}
