
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public class QChatServer {
  public var serverId: UInt64?
  public var appId: NSInteger?
  public var name: String?
  public var icon: String?
  public var custom: String?
  public var owner: String?
  public var memberNumber: NSInteger?
  public var inviteMode: QChatServerInviteMode?
  public var applyMode: QChatServerApplyMode?
  public var validFlag: Bool?
  public var createTime: TimeInterval?
  public var updateTime: TimeInterval?
  public var hasUnread = false
//    public var unreadCount: UInt = 0
//    public var hasGetUnread = false

  init(server: NIMQChatServer?) {
    serverId = server?.serverId
    appId = server?.appId
    name = server?.name
    icon = server?.icon
    custom = server?.custom
    owner = server?.owner
    memberNumber = server?.memberNumber ?? 0
    switch server?.inviteMode {
    case .autoEnter:
      inviteMode = .autoEnter
    case .needApprove:
      inviteMode = .needApprove
    default:
      inviteMode = .needApprove
    }

    switch server?.applyMode {
    case .autoEnter:
      applyMode = .autoEnter
    case .needApprove:
      applyMode = .needApprove
    default:
      applyMode = .autoEnter
    }

    validFlag = server?.validFlag
    createTime = server?.createTime
    updateTime = server?.updateTime
  }
}
