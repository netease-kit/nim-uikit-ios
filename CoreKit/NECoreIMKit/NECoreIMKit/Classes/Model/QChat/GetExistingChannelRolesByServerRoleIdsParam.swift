
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.
import Foundation
import NIMSDK

public struct GetExistingChannelRolesByServerRoleIdsParam {
  public var serverId: UInt64
  public var channelId: UInt64
  public var roleIds: [UInt64]
  public init(serverId: UInt64, channelId: UInt64, roleIds: [UInt64]) {
    self.serverId = serverId
    self.channelId = channelId
    self.roleIds = roleIds
  }

  public func toIMParam() -> NIMQChatGetExistingChannelRolesByServerRoleIdsParam {
    let imParam = NIMQChatGetExistingChannelRolesByServerRoleIdsParam()
    imParam.serverId = serverId
    imParam.channelId = channelId
    var ids = [NSNumber]()
    for roleId in roleIds {
      ids.append(NSNumber(value: roleId))
    }
    imParam.roleIds = ids
    return imParam
  }
}
