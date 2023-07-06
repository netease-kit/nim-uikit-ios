
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

//
public enum type: Int {
  case ManageServer = 1, ManageChannel, ManageRole, SendMsg, ModifySelfInfo, InviteToServer,
       KickOthersInServer, ModifyOthersInfoInServer, RevokeMsg, DeleteOtherMsg, RemindOther,
       RemindAll, BlackWhiteList
}

public enum status: Int {
  case Deny = -1, Extend, Allow
}

public struct RoleStatusInfo {
  public var type: type = .ManageServer
  public var status: status = .Deny

  public init(type: type, status: status) {
    self.type = type
    self.status = status
  }

  init(info: NIMQChatPermissionStatusInfo) {
    switch info.type {
    case .manageServer:
      type = .ManageServer
    case .manageChannel:
      type = .ManageChannel
    case .manageRole:
      type = .ManageRole
    case .sendMsg:
      type = .SendMsg
    case .modifySelfInfo:
      type = .ModifySelfInfo
    case .inviteToServer:
      type = .InviteToServer
    case .kickOthersInServer:
      type = .KickOthersInServer
    case .modifyOthersInfoInServer:
      type = .ModifyOthersInfoInServer
    case .revokeMsg:
      type = .RevokeMsg
    case .deleteOtherMsg:
      type = .DeleteOtherMsg
    case .remindOther:
      type = .RemindOther
    case .remindAll:
      type = .RemindAll
    case .manageBlackWhiteList:
      type = .BlackWhiteList
    default:
      type = .ManageServer
    }
    switch info.status {
    case .deny:
      status = .Deny
    case .extend:
      status = .Extend
    case .allow:
      status = .Allow
    default:
      status = .Deny
    }
  }
}
