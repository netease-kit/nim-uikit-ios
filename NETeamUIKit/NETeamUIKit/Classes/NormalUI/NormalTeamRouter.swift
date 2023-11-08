// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIMKit
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
      if let tid = param["teamId"] as? String {
        let session = NIMSession(tid, type: .team)
        let searchMsgCtrl = TeamHistoryMessageController(session: session)
        nav?.pushViewController(searchMsgCtrl, animated: true)
      }
    }
  }
}
