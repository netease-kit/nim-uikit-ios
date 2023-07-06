
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
public struct QChatGetChannelsByPageResult {
  public var channels = [ChatChannel]()
  // 是否还有下一页数据
  public var hasMore: Bool = false
  // 下一页的起始时间戳
  public var nextTimetag: TimeInterval = 0

  public init(channelsResult: NIMQChatGetChannelsByPageResult?) {
    guard let channelArray = channelsResult?.channels else { return }
    for channel in channelArray {
      let itemModel = ChatChannel(channel: channel)
      channels.append(itemModel)
    }

    if let hasMore = channelsResult?.hasMore {
      self.hasMore = hasMore
    }
    if let nextTimeTag = channelsResult?.nextTimetag {
      nextTimetag = nextTimeTag
    }
  }
}
