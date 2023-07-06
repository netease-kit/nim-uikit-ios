
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public struct RoleMember {
  /**
   *  服务器id
   */
  public var serverId: UInt64?
  /**
   * 身份组id
   */
  public var roleId: UInt64?
  /**
   * 用户id
   */
  public var accid: String?
  /**
   * 创建时间
   */
  public var createTime: Double?
  /**
   * 更新时间
   */
  public var updateTime: Double?
  /**
   * 昵称
   * */
  public var nick: String?
  /**
   * 头像
   */
  public var avatar: String?
  /**
   * 自定义字段
   */
  public var custom: String?
  /**
   * 成员类型
   */
  public var type: ServerMemberType?
  /**
   * 加入时间
   */
  public var jointime: Double?
  /**
   * 邀请者accid
   */
  public var inviter: String?

  init(_ member: NIMQChatServerRoleMember) {
    serverId = member.serverId
    accid = member.accid
    roleId = member.roleId
    nick = member.nick
    avatar = member.avatar
    inviter = member.inviter
    custom = member.custom
    type = member.type.convertMeberType()
    jointime = member.jointime
    createTime = member.createTime
    updateTime = member.updateTime
  }
}
