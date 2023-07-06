
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public struct ServerRole {
  public var serverId: UInt64?
  public var roleId: UInt64?
  public var name: String?
  public var type: channelRoleType?
  public var icon: String?

  public var ext: String?
  public var auths: [StatusInfo]?
  public var channelAuths: [RoleStatusInfo]?
  public var createTime: TimeInterval?
  public var updateTime: TimeInterval?
//    public var priority: Int32?
  public var memberCount: Int?

//    public var isMember = false

  public var priority: Int?

  public init(_ role: NIMQChatServerRole?) {
    serverId = role?.serverId
    roleId = role?.roleId
    name = role?.name
    memberCount = role?.memberCount
    type = role?.type == .custom ? .custom : .everyone
    icon = role?.icon
    ext = role?.ext
    priority = role?.priority.intValue
    createTime = role?.createTime
    updateTime = role?.updateTime

    var authList = [StatusInfo]()
    channelAuths = [RoleStatusInfo]()

    role?.auths.forEach { info in
      authList.append(StatusInfo(info: info))
      channelAuths?.append(RoleStatusInfo(info: info))
    }

    if authList.count > 0 {
      auths = authList
    }

//        if let member = role?.isMember {
//            isMember = member
//        }
  }
}
