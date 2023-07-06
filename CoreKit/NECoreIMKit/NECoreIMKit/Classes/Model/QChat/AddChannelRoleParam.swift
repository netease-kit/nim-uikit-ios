
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
public struct AddChannelRoleParam {
  public var serverId: UInt64
  public var channelId: UInt64
  public var parentRoleId: UInt64
  public init(serverId: UInt64, channelId: UInt64, parentRoleId: UInt64) {
    self.serverId = serverId
    self.channelId = channelId
    self.parentRoleId = parentRoleId
  }

  func toImParam() -> NIMQChatAddChannelRoleParam {
    let imParam = NIMQChatAddChannelRoleParam()
    imParam.serverId = serverId
    imParam.channelId = channelId
    imParam.parentRoleId = UInt64(parentRoleId)
    return imParam
  }
}
