
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public enum QChatServerMemberType {
  case common // 普通成员
  case owner // 所有者
}

public struct QChatMember {
  public var serverId: UInt64?
  public var appId: NSInteger?
  public var accid: String?
  public var nick: String?
  public var avatar: String?
  public var inviter: String?
  public var custom: String?
  public var type: QChatServerMemberType?
  public var joinTime: TimeInterval?
  public var validFlag: Bool?
  public var createTime: TimeInterval?
  public var updateTime: TimeInterval?

  init(member: NIMQChatServerMember?) {
    serverId = member?.serverId
    appId = member?.appId
    accid = member?.accid
    nick = member?.nick
    avatar = member?.avatar
    inviter = member?.inviter
    custom = member?.custom

    switch member?.type {
    case .common:
      type = .common
    case .owner:
      type = .owner
    default:
      type = .common
    }
    validFlag = member?.validFlag
    joinTime = member?.joinTime
    createTime = member?.createTime
    updateTime = member?.updateTime
  }
}
