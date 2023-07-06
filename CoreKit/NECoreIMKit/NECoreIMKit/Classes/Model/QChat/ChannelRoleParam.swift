
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public struct ChannelRoleParam {
  public var serverId: UInt64
  public var channelId: UInt64
  // timetag
  public var timeTag: TimeInterval?
  // 每页个数
  public var limit: Int = 5

  public init(serverId: UInt64, channelId: UInt64) {
    self.serverId = serverId
    self.channelId = channelId
  }

  public func toIMParam() -> NIMQChatGetChannelRolesParam {
    let imParam = NIMQChatGetChannelRolesParam()
    imParam.serverId = serverId
    imParam.channelId = channelId
    imParam.timeTag = timeTag ?? 0
    imParam.limit = limit
    return imParam
  }
}
