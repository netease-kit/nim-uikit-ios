
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public enum ChannelMemberRoleType {
  case white
  case black
}

public struct GetChannelBlackWhiteMembers {
  public var serverId: UInt64?
  public var channelId: UInt64?
  // timetag
  public var timeTag: TimeInterval?
  // 每页个数
  public var limit: Int?

  public var type: ChannelMemberRoleType?

  public init(serverId: UInt64?, channelId: UInt64?, timeTag: TimeInterval?, limit: Int?,
              type: ChannelMemberRoleType?) {
    self.serverId = serverId
    self.channelId = channelId
    self.timeTag = timeTag
    self.limit = limit
    self.type = type
  }

  public func toIMParam() -> NIMQChatGetChannelBlackWhiteMembersByPageParam {
    let imParam = NIMQChatGetChannelBlackWhiteMembersByPageParam()
    imParam.serverId = serverId ?? 0
    imParam.channelId = channelId ?? 0
    imParam.timeTag = timeTag ?? 0
    imParam.limit = limit ?? 50
    switch type {
    case .white:
      imParam.type = .white
    case .black:
      imParam.type = .black
    case .none:
      imParam.type = .white
    }
    return imParam
  }
}
