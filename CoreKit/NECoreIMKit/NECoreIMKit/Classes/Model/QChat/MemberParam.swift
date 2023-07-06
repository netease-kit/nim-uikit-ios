
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public struct RemoveServerRoleMemberParam {
  /**
   * 服务器id
   */
  public var serverId: UInt64?

  /**
   * 身份组id
   */
  public var roleId: UInt64?
  /**
   * 用户accids
   */
  public var accountArray: [String]?

  public init() {}

  func toImParam() -> NIMQChatRemoveServerRoleMemberParam {
    let param = NIMQChatRemoveServerRoleMemberParam()

    if let sid = serverId {
      param.serverId = sid
    }
    if let rid = roleId {
      param.roleId = rid
    }
    if let accounts = accountArray {
      param.accountArray = accounts
    }
    return param
  }
}

public struct UpdateMyMemberInfoParam {
  public var serverId: UInt64?
  public var nick: String?
  public var avatar: String?
  public var custom: String?

  public init() {}

  func toImParam() -> NIMQChatUpdateMyMemberInfoParam {
    let param = NIMQChatUpdateMyMemberInfoParam()
    if let sid = serverId {
      param.serverId = sid
    }
    if let n = nick {
      param.nick = n
    }
    if let icon = avatar {
      param.avatar = icon
    }
    if let c = custom {
      param.custom = c
    }
    return param
  }
}

public struct KickServerMembersParam {
  /**
   * 圈组服务器ID
   */
  public var serverId: UInt64?

  /**
   * 邀请对象的账号数组
   */
  public var accounts: [String]?

  public init() {}

  func toImParam() -> NIMQChatKickServerMembersParam {
    let param = NIMQChatKickServerMembersParam()
    if let sid = serverId {
      param.serverId = sid
    }
    if let accids = accounts {
      param.accids = [String]()
      accids.forEach { accid in
        param.accids.append(accid)
      }
    }
    return param
  }
}
