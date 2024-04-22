// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIM2Kit
import NECoreKit
import NIMSDK

public extension TeamRouter {
  static func register() {
    registerCommon(icUrls: iconUrls)

    Router.shared.register(TeamSettingViewRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let teamId = param["teamid"] as? String
      let teamSetting = TeamSettingViewController()
      teamSetting.teamId = teamId
      nav?.pushViewController(teamSetting, animated: true)
    }

    Router.shared.register(SearchMessageRouter) { param in

      let nav = param["nav"] as? UINavigationController
      if let teamId = param["teamId"] as? String {
        let searchMsgCtrl = TeamHistoryMessageController(teamId: teamId)
        if let info = param["teamInfo"] as? NETeamInfoModel {
          searchMsgCtrl.viewModel.teamInfoModel = info
        }
        nav?.pushViewController(searchMsgCtrl, animated: true)
      }
    }
  }
}
