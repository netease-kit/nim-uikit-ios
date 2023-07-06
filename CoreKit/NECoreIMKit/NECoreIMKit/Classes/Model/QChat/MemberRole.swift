
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public struct MemberRole {
  /**
   *  服务器id
   */
  public var serverId: UInt64?
  /**
   * 定制权限id
   */
  public var roleId: UInt64?
  /**
   * 用户id
   */
  public var accid: String?
  /**
   * 频道id
   */
  public var channelId: UInt64?
  /**
   * 该身份组各资源的权限状态
   */
  public var auths: [RoleStatusInfo]?

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
  public var joinTime: Double?
  /**
   * 邀请者accid
   */
  public var inviter: String?

  init(aid: String) {
    accid = aid
  }

  init(member: NIMQChatMemberRole?) {
    serverId = member?.serverId
    roleId = member?.roleId
    accid = member?.accid
    channelId = member?.channelId
    if let authsTmp = member?.auths {
      var auths = [RoleStatusInfo]()
      for a in authsTmp {
        auths.append(RoleStatusInfo(info: a))
      }
      self.auths = auths
    }
    createTime = member?.createTime
    updateTime = member?.updateTime
    nick = member?.nick
    avatar = member?.avatar
    custom = member?.custom
    type = member?.type.convertMeberType()
    joinTime = member?.joinTime
    inviter = member?.inviter
  }
}
