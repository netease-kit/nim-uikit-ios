
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import Foundation
public struct GetMessageHistoryParam {
  var serverId: UInt64
  var channelId: UInt64
//    message number per page
  public var limit: Int = 100
//    last message in last page
  public var lastMsg: NIMQChatMessage?

  public init(serverId: UInt64, channelId: UInt64) {
    self.serverId = serverId
    self.channelId = channelId
  }

  func toImParam() -> NIMQChatGetMessageHistoryParam {
    let imParam = NIMQChatGetMessageHistoryParam()
    imParam.serverId = serverId
    imParam.channelId = channelId
    imParam.limit = Foundation.NSNumber(integerLiteral: limit)
    imParam.reverse = false

    if let msg = lastMsg {
      imParam.toTime = Foundation.NSNumber(floatLiteral: msg.timestamp)
      imParam.excludeMsgId = Foundation.NSNumber(integerLiteral: Int(msg.serverID) ?? 0)
    }
    print("imParam:\(imParam.toTime) \(imParam.excludeMsgId)")
    return imParam
  }
}
