//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objc
@objcMembers
open class TeamIntroduceViewModel: NSObject {
  /// 群API单例
  public let teamRepo = TeamRepo.shared
  /// 群信息
  public var currentTeamMember: V2NIMTeamMember?

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

  ///  更新群介绍
  /// - Parameter  teamId: 群组ID
  /// - Parameter  introduce: 群介绍
  /// - Parameter  completion: 完成后的回调
  public func updateTeamIntroduce(_ teamId: String, _ introduce: String,
                                  _ completion: @escaping (NSError?) -> Void) {
    teamRepo.updateTeamIntroduce(teamId, .TEAM_TYPE_NORMAL, introduce) { error in
      completion(error)
    }
  }
}
