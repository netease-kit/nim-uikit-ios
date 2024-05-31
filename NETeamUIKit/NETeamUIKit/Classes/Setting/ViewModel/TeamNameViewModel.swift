//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objc
@objcMembers
open class TeamNameViewModel: NSObject {
  let teamRepo = TeamRepo.shared
  var currentTeamMember: V2NIMTeamMember?

  /// 获取当前用户群信息
  /// - Parameter teamId 群id
  func getCurrentUserTeamMember(_ teamId: String?, _ completion: @escaping (NSError?) -> Void) {
    if let tid = teamId {
      let currentUserAccid = IMKitClient.instance.account()
      teamRepo.getTeamMember(tid, .TEAM_TYPE_NORMAL, currentUserAccid) { member, error in
        self.currentTeamMember = member
        completion(error)
      }
    }
  }
}
