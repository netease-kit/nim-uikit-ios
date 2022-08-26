
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEKitTeam
import NEKitCore
import NEKitCoreIM
import NIMSDK
public enum TeamRouter {
  public static var iconUrls = ["https://s.netease.im/safe/ABg8YjWQWvcqO6sAAAAAAAAAAAA?_im_url=1",
                                "https://s.netease.im/safe/ABg8YjmQWvcqO6sAAAAAAAABAAA?_im_url=1",
                                "https://s.netease.im/safe/ABg8YjyQWvcqO6sAAAAAAAABAAA?_im_url=1",
                                "https://s.netease.im/safe/ABg8YkCQWvcqO6sAAAAAAAABAAA?_im_url=1",
                                "https://s.netease.im/safe/ABg8YkSQWvcqO6sAAAAAAAABAAA?_im_url=1"]

  public static let repo = TeamRepo()

  public static func register() {
    Router.shared.register(TeamSettingViewRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let teamId = param["teamid"] as? String
      let teamSetting = TeamSettingViewController()
      teamSetting.teamId = teamId
      nav?.pushViewController(teamSetting, animated: true)
    }

    Router.shared.register(TeamCreateDisuss) { param in
      if let accids = param["accids"] as? [String] {
        var name = (param["names"] as? String) ?? localizable("normal_team")
        if name.count > 30 {
          name = String(name.prefix(30))
        }
        let iconUrl = (param["url"] as? String) ??
          iconUrls[Int(arc4random()) % iconUrls.count]
        repo.createNormalTeam(accids, iconUrl, name) { error, teamid, failedIds in
          var result = [String: Any]()
          if let err = error {
            result["code"] = err.code
            result["msg"] = err.localizedDescription
          } else {
            result["code"] = 0
            result["msg"] = "ok"
            result["teamId"] = teamid
          }
          Router.shared.use(TeamCreateDiscussResult, parameters: result, closure: nil)
        }
      }
    }

    Router.shared.register(TeamCreateSenior) { param in

      if let accids = param["accids"] as? [String] {
        var name = (param["names"] as? String) ?? localizable("senior_team")
        if name.count > 30 {
          name = String(name.prefix(30))
        }
        let iconUrl = (param["url"] as? String) ??
          iconUrls[Int(arc4random()) % iconUrls.count]
        repo.createAdvanceTeam(accids, iconUrl, name) { error, teamid, failedIds in
          var result = [String: Any]()
          if let err = error {
            result["code"] = err.code
            result["msg"] = err.localizedDescription
          } else {
            result["code"] = 0
            result["msg"] = "ok"
            result["teamId"] = teamid

            repo.sendCreateAdavanceNoti(
              teamid ?? "",
              localizable("create_senior_team_noti")
            ) { error in
              print("send noti message  : ", error as Any)
            }
          }
          Router.shared.use(TeamCreateSeniorResult, parameters: result, closure: nil)
          print("creat senior reuslt : ", result)
        }
      }
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
