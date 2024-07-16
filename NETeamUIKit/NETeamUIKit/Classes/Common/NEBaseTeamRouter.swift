// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK

@objcMembers
open class TeamRouter: NSObject {
  public static let repo = TeamRepo.shared
  public static var iconUrls = ["https://yx-web-nosdn.netease.im/common/2425b4cc058e5788867d63c322feb7ac/groupAvatar1.png",
                                "https://yx-web-nosdn.netease.im/common/62c45692c9771ab388d43fea1c9d2758/groupAvatar2.png",
                                "https://yx-web-nosdn.netease.im/common/d1ed3c21d3f87a41568d17197760e663/groupAvatar3.png",
                                "https://yx-web-nosdn.netease.im/common/e677d8551deb96723af2b40b821c766a/groupAvatar4.png",
                                "https://yx-web-nosdn.netease.im/common/fd6c75bb6abca9c810d1292e66d5d87e/groupAvatar5.png"]

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

        let param = V2NIMCreateTeamParams()
        param.name = name
        param.teamType = .TEAM_TYPE_NORMAL
        param.avatar = iconUrl
        param.joinMode = .TEAM_JOIN_MODE_FREE
        param.inviteMode = .TEAM_INVITE_MODE_ALL
        param.agreeMode = .TEAM_AGREE_MODE_NO_AUTH
        param.updateInfoMode = .TEAM_UPDATE_INFO_MODE_ALL
        param.updateExtensionMode = .TEAM_UPDATE_EXTENSION_MODE_ALL
        var disucssFlag = [String: Any]()
        disucssFlag[discussTeamKey] = true
        let jsonString = NECommonUtil.getJSONStringFromDictionary(disucssFlag)
        if jsonString.count > 0 {
          param.serverExtension = jsonString
        }

        repo.createTeam(param, accids, nil, nil) { createResult, error in
          var result = [String: Any]()
          if let err = error as? NSError {
            result["code"] = err.code
            result["msg"] = err.localizedDescription
          } else {
            result["code"] = 0
            result["msg"] = "ok"
            result["teamId"] = createResult?.team?.teamId
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

        let param = V2NIMCreateTeamParams()
        param.name = name
        param.avatar = iconUrl
        param.teamType = .TEAM_TYPE_NORMAL
        param.agreeMode = .TEAM_AGREE_MODE_NO_AUTH
        param.updateExtensionMode = .TEAM_UPDATE_EXTENSION_MODE_ALL

        repo.createTeam(param, [], nil, nil) { creatResult, error in
          var result = [String: Any]()
          if let err = error as? NSError {
            result["code"] = err.code
            result["msg"] = err.localizedDescription
          } else {
            result["code"] = 0
            result["msg"] = "ok"
            result["teamId"] = creatResult?.team?.teamId

            // 先插入【成功创建群聊】消息
            if let tid = creatResult?.team?.teamId, let cid = V2NIMConversationIdUtil.teamConversationId(tid) {
              TeamProvider.shared.getTeamInfo(tid, .TEAM_TYPE_NORMAL) { retTeam, error in
                print("getTeamInfo : ", error as Any)
                var createTime: TimeInterval = 0
                if let team = retTeam {
                  createTime = team.createTime
                } else {
                  createTime = Date().timeIntervalSince1970
                }

                let message = V2NIMMessageCreator.createTipsMessage(localizable("create_senior_team_noti"))
                ChatRepo.shared.insertMessageToLocal(message: message,
                                                     conversationId: cid,
                                                     createTime: createTime) { _, error in
                  print("send noti message  : ", error as Any)
                  // 再邀请用户
                  repo.inviteTeamMembers(tid, .TEAM_TYPE_NORMAL, accids) { error, members in
                    print("invite users : \(accids)", error as Any)
                  }
                }
              }
            }
          }

          Router.shared.use(TeamCreateSeniorResult, parameters: result, closure: nil)
          print("creat senior reuslt : ", result)
        }
      }
    }

    if IMKitConfigCenter.shared.onlineStatusEnable {
      _ = NEEventSubscribeManager.shared
    }
  }
}
