
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIM2Kit
import NIMSDK

@objcMembers
public class ConversationSearchListModel: NSObject, Comparable {
  public static func < (lhs: ConversationSearchListModel, rhs: ConversationSearchListModel) -> Bool {
    if let user1 = lhs.userInfo, let user2 = rhs.userInfo {
      if let time1 = user1.user?.createTime, let time2 = user2.user?.createTime {
        return time1 > time2
      }
      return false
    }
    if let team1 = lhs.team, let team2 = rhs.team {
      let time1 = team1.createTime
      let time2 = team2.createTime
      return time1 > time2
    }
    return false
  }

  public var userInfo: NEUserWithFriend?

//  public var teamInfo: NIMTeam?

  public var team: V2NIMTeam?
  override public init() {
    super.init()
  }
}
