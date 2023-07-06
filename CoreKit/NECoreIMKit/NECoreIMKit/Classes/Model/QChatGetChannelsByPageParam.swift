
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public struct QChatGetChannelsByPageParam {
  // 服务器id
  public var serverId: UInt64?

  /// 时间戳
  public var timeTag: TimeInterval = 0

  /// 条数限制
  public var limit: Int = 20

  public init(timeTag: TimeInterval, serverId: UInt64) {
    self.serverId = serverId
    self.timeTag = timeTag
  }

  public func toIMParam() -> NIMQChatGetChannelsByPageParam {
    let imParam = NIMQChatGetChannelsByPageParam()

    if let serverId = serverId {
      imParam.serverId = serverId
    }
    imParam.timeTag = timeTag
    imParam.limit = limit
    return imParam
  }
}
