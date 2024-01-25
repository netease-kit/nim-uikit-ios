// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit
import NECoreIMKit
import NECoreKit
import NIMSDK

@objcMembers
open class TeamRouter: NSObject {
  public static let repo = TeamRepo.shared
  public static var iconUrls = ["https://s.netease.im/safe/ABg8YjWQWvcqO6sAAAAAAAAAAAA?_im_url=1",
                                "https://s.netease.im/safe/ABg8YjmQWvcqO6sAAAAAAAABAAA?_im_url=1",
                                "https://s.netease.im/safe/ABg8YjyQWvcqO6sAAAAAAAABAAA?_im_url=1",
                                "https://s.netease.im/safe/ABg8YkCQWvcqO6sAAAAAAAABAAA?_im_url=1",
                                "https://s.netease.im/safe/ABg8YkSQWvcqO6sAAAAAAAABAAA?_im_url=1"]

  public static var iconUrlsFun = ["https://nim-nosdn.netease.im/MjYxNDkzNzE=/bmltYV8xNDIxMTk0NzAzMzhfMTY4NDgyNzc0MTczNV8yY2FlMjczZS01MDk0LTQ5NWMtODMzMS1mYTBmMTE1NmEyNDQ=",
                                   "https://nim-nosdn.netease.im/MjYxNDkzNzE=/bmltYV8xNDIxMTk0NzAzMzhfMTY4NDgyNzc0MTczNV9jYWJmNjViNy1kMGM3LTRiNDEtYmVmMi1jYjhiNzRjY2EwY2M=",
                                   "https://nim-nosdn.netease.im/MjYxNDkzNzE=/bmltYV8xNDIxMTk0NzAzMzhfMTY4NDgyNzc0MTczNV8yMzY1YmY5YS0xNGE1LTQxYTctYTg2My1hMzMyZWE5YzhhOTQ=",
                                   "https://nim-nosdn.netease.im/MjYxNDkzNzE=/bmltYV8xNDIxMTk0NzAzMzhfMTY4NDgyNzc0MTczNV80NTQxMDhhNy1mNWMzLTQxMzMtOWU3NS1hNThiN2FiNjI5MWY=",
                                   "https://nim-nosdn.netease.im/MjYxNDkzNzE=/bmltYV8xNDIxMTk0NzAzMzhfMTY4NDgyNzc0MTczNV8wMGVlNWUyOS0wYzg3LTQxMzUtYmVjOS00YjI1MjcxMDhhNTM="]

  public static func registerCommon(icUrls: [String]) {
    Router.shared.register(TeamCreateDisuss) { param in
      if let accids = param["accids"] as? [String] {
        var name = (param["names"] as? String) ?? localizable("normal_team")
        if name.count > 30 {
          name = String(name.prefix(30))
        }

        let iconUrl = (param["url"] as? String) ??
          iconUrls[Int(arc4random()) % iconUrls.count]

        let option = NIMCreateTeamOption()
        option.type = .advanced
        option.avatarUrl = iconUrl
        option.name = name
        option.joinMode = .noAuth
        option.inviteMode = .all
        option.beInviteMode = .noAuth
        option.updateInfoMode = .all
        option.updateClientCustomMode = .all
        var disucssFlag = [String: Any]()
        disucssFlag[discussTeamKey] = true
        let jsonString = NECommonUtil.getJSONStringFromDictionary(disucssFlag)
        if jsonString.count > 0 {
          option.clientCustomInfo = jsonString
        }

        repo.createAdvanceTeam(accids, option) { error, teamid, failedIds in
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

        let option = NIMCreateTeamOption()
        option.type = .advanced
        option.avatarUrl = iconUrl
        option.name = name
        option.beInviteMode = .noAuth

        repo.createAdvanceTeam(accids, option) { error, teamid, failedIds in
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
  }
}
