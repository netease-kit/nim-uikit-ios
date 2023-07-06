
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public struct RemoveChannelRoleParam {
  public var serverId: UInt64?
  public var channelId: UInt64?
  public var roleId: UInt64?

  public init() {}
  public func toImParam() -> NIMQChatRemoveChannelRoleParam {
    let imParam = NIMQChatRemoveChannelRoleParam()
    imParam.serverId = serverId ?? 0
    imParam.roleId = roleId ?? 0
    imParam.channelId = channelId ?? 0
    return imParam
  }
}
