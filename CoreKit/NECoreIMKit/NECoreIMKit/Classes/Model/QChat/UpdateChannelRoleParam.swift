
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public struct UpdateChannelRoleParam {
  public var serverId: UInt64?
  public var channelId: UInt64?
  public var roleId: UInt64?
  public var commands: [RoleStatusInfo]?

  public init(serverId: UInt64?, channelId: UInt64?, roleId: UInt64?,
              commands: [RoleStatusInfo]?) {
    self.serverId = serverId
    self.channelId = channelId
    self.roleId = roleId
    self.commands = commands
  }

  public func toIMParam() -> NIMQChatUpdateChannelRoleParam {
    let imParam = NIMQChatUpdateChannelRoleParam()
    imParam.serverId = serverId ?? 0
    imParam.channelId = channelId ?? 0
    imParam.roleId = roleId ?? 0
    if let cmds = commands {
      var tmp = [NIMQChatPermissionStatusInfo]()
      for c in cmds {
        let im = NIMQChatPermissionStatusInfo()
        im.status = NIMQChatPermissionStatus(rawValue: c.status.rawValue) ?? .extend
        im.type = NIMQChatPermissionType(rawValue: c.type.rawValue) ?? .manageServer
        tmp.append(im)
      }
      imParam.commands = tmp
    }
    return imParam
  }
}
