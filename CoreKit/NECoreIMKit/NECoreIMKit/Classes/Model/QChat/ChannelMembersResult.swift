
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public struct ChannelMembersResult {
  public var memberArray: [ServerMemeber]?

  /// 是否还有下一页数据
  public var hasMore: Bool?

  /// 下一页的起始时间戳
  public var nextTimetag: TimeInterval?

  init() {}
  init(memberResult: NIMQChatGetChannelMembersByPageResult?) {
    hasMore = memberResult?.hasMore
    nextTimetag = memberResult?.nextTimetag
    if let members = memberResult?.memberArray {
      var array = [ServerMemeber]()
      for member in members {
        array.append(ServerMemeber(member))
      }
      memberArray = array
    }
  }

  init(whiteMemberResult: NIMQChatGetChannelBlackWhiteMembersByPageResult?) {
    hasMore = whiteMemberResult?.hasMore
    nextTimetag = whiteMemberResult?.nextTimetag
    if let members = whiteMemberResult?.memberArray {
      var array = [ServerMemeber]()
      for member in members {
        array.append(ServerMemeber(member))
      }
      memberArray = array
    }
  }
}
