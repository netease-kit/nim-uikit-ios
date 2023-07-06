
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
import AVFoundation

public enum ServerRoleType {
  case everyone
  case custom

  func convertImType() -> NIMQChatRoleType {
    switch self {
    case .everyone:
      return NIMQChatRoleType.everyOne
    case .custom:
      return NIMQChatRoleType.custom
    }
  }
}

public struct DeleteServerRoleParam {
  public var serverId: UInt64?
  public var roleId: UInt64?
  public init() {}
  func toIMParam() -> NIMQChatDeleteServerRoleParam {
    let param = NIMQChatDeleteServerRoleParam()
    if let sid = serverId {
      param.serverId = sid
    }
    if let rid = roleId {
      param.roleId = rid
    }
    return param
  }
}

public struct GetMemberRolesParam {
  public var serverId: UInt64?
  public var channelId: UInt64?
  public var limit: Int?
  public var timeTag: Double?
  public init() {}
  func toImParam() -> NIMQChatGetMemberRolesParam {
    let param = NIMQChatGetMemberRolesParam()
    if let sid = serverId {
      param.serverId = sid
    }
    if let cid = channelId {
      param.channelId = cid
    }
    if let l = limit {
      param.limit = l
    }
    param.timeTag = timeTag ?? 0
//        if let t = timeTag {
//            param.timeTag = t
//        }
    return param
  }
}

public struct GetServerRoleParam {
  public var serverId: UInt64?
//    public var timeTag: Double?
  public var limit: Int?
  public var priority: Int?

  public init() {}

  func toImParam() -> NIMQChatGetServerRolesParam {
    let param = NIMQChatGetServerRolesParam()
    if let sid = serverId {
      param.serverId = sid
    }
    if let l = limit {
      param.limit = l
    }
    if let p = priority {
      param.priority = NSNumber(value: p)
    }
    return param
  }
}

public struct UpdateServerRolePriorityItem {
  /**
   *  服务器id
   */
  public var serverId: UInt64?
  /**
   * 身份组id
   */
  public var roleId: UInt64?
  /**
   * 优先级
   */
  public var priority: Int

  public init(_ role: ServerRole, _ pri: Int) {
    serverId = role.serverId
    roleId = role.roleId
    priority = pri
  }

  func toImRolePriorityItem() -> NIMQChatUpdateServerRolePriorityItem {
    let item = NIMQChatUpdateServerRolePriorityItem()
    if let sid = serverId {
      item.serverId = sid
    }
    if let rid = roleId {
      item.roleId = rid
    }
    item.priority = NSNumber(value: priority)
    return item
  }
}

public struct UpdateServerRolePrioritiesParam {
  public var serverId: UInt64?
  public var updateItems: [UpdateServerRolePriorityItem]?
  public init() {}
  func toImParam() -> NIMQChatupdateServerRolePrioritiesParam {
    let param = NIMQChatupdateServerRolePrioritiesParam()
    if let sid = serverId {
      param.serverId = sid
    }
    var items = [NIMQChatUpdateServerRolePriorityItem]()
    updateItems?.forEach { item in
      items.append(item.toImRolePriorityItem())
    }
    if items.count > 0 {
      param.updateItems = items
    }
    return param
  }
}

public struct ServerRoleParam {
  public var serverId: UInt64?
  public var name: String?
  public var type: ServerRoleType?
  public var icon: String?
  public var ext: String?

  public init() {}

  func toIMParam() -> NIMQChatCreateServerRoleParam {
    let param = NIMQChatCreateServerRoleParam()
    if let id = serverId {
      param.serverId = id
    }
    if let n = name {
      param.name = n
    }
    if let i = icon {
      param.icon = i
    }
    if let e = ext {
      param.ext = e
    }
    if let t = type?.convertImType() {
      param.type = t
    }
    return param
  }
}

public enum ChatPermissionType: String {
  // 管理服务器。修改服务器
  case manageServer
  // 管理频道，server和channel都有
  case manageChannel
  // 管理角色的权限，server和channel都有
  case manageRole
  // 发送消息，server和channel都有
  case sendMsg
  // 修改自己在该server的成员信息，仅server有
  case modifySelfInfo
  // 邀请他人进入server的，仅server有
  case inviteToServer
  // 踢除他人的权限，仅server有
  case kickOthersInServer
  // 修改他人在该server的服务器成员信息，仅server有
  case modifyOthersInfoInServer
  // 撤回他人消息的权限，server和channel都有
  case revokeMsg
  // 删除他人消息的权限，server和channel都有
  case deleteOtherMsg
  //  @ 他人的权限，server和channel都有
  case remindOther
  // @ everyone的权限，server和channel都有
  case remindAll
  // 管理黑白名单的权限，server和channel都有
  case manageBlackWhiteList
  // default
  case none

  func convertQCathPermissionType() -> NIMQChatPermissionType? {
    switch self {
    case .manageServer:
      return NIMQChatPermissionType.manageServer
    case .manageChannel:
      return NIMQChatPermissionType.manageChannel
    case .manageRole:
      return NIMQChatPermissionType.manageRole
    case .sendMsg:
      return NIMQChatPermissionType.sendMsg
    case .modifySelfInfo:
      return NIMQChatPermissionType.modifySelfInfo
    case .inviteToServer:
      return NIMQChatPermissionType.inviteToServer
    case .kickOthersInServer:
      return NIMQChatPermissionType.kickOthersInServer
    case .modifyOthersInfoInServer:
      return NIMQChatPermissionType.modifyOthersInfoInServer
    case .revokeMsg:
      return NIMQChatPermissionType.revokeMsg
    case .deleteOtherMsg:
      return NIMQChatPermissionType.deleteOtherMsg
    case .remindOther:
      return NIMQChatPermissionType.remindOther
    case .remindAll:
      return NIMQChatPermissionType.remindAll
    case .manageBlackWhiteList:
      return NIMQChatPermissionType.manageBlackWhiteList
    case .none:
      return nil
    }
  }
}

extension NIMQChatPermissionType {
  func convertType() -> ChatPermissionType {
    switch self {
    case .manageServer:
      return ChatPermissionType.manageServer
    case .manageChannel:
      return ChatPermissionType.manageChannel
    case .manageRole:
      return ChatPermissionType.manageRole
    case .sendMsg:
      return ChatPermissionType.sendMsg
    case .modifySelfInfo:
      return ChatPermissionType.modifySelfInfo
    case .inviteToServer:
      return ChatPermissionType.inviteToServer
    case .kickOthersInServer:
      return ChatPermissionType.kickOthersInServer
    case .modifyOthersInfoInServer:
      return ChatPermissionType.modifyOthersInfoInServer
    case .revokeMsg:
      return ChatPermissionType.revokeMsg
    case .deleteOtherMsg:
      return ChatPermissionType.deleteOtherMsg
    case .remindOther:
      return ChatPermissionType.remindOther
    case .remindAll:
      return ChatPermissionType.remindAll
    case .manageBlackWhiteList:
      return ChatPermissionType.manageBlackWhiteList
    @unknown default:
      return .none
    }
  }
}

public struct StatusInfo {
  public var permissionType: ChatPermissionType?
  public var status: status = .Allow
  public init() {}
  init(info: NIMQChatPermissionStatusInfo) {
    permissionType = info.type.convertType()
    if info.status == .extend {
      status = .Extend
    } else if info.status == .deny {
      status = .Deny
    } else if info.status == .allow {
      status = .Allow
    }
  }
}

public extension status {
  func convertQChtaType() -> NIMQChatPermissionStatus {
    switch self {
    case .Allow:
      return NIMQChatPermissionStatus.allow
    case .Deny:
      return NIMQChatPermissionStatus.deny
    case .Extend:
      return NIMQChatPermissionStatus.extend
    }
  }
}

public struct UpdateServerRoleParam {
  public var serverId: UInt64?
  public var roleId: UInt64?
  public var name: String?
  public var icon: String?
  public var ext: String?
  public var commands: [StatusInfo]?
  public var priority: Int?
  public init() {}

  func toImParam() -> NIMQChatUpdateServerRoleParam {
    let param = NIMQChatUpdateServerRoleParam()
    if let sid = serverId {
      param.serverId = sid
    }
    if let rid = roleId {
      param.roleId = rid
    }
    if let n = name {
      param.name = n
    }
    if let i = icon {
      param.icon = i
    }
    if let e = ext {
      param.ext = e
    }
    var authors = [NIMQChatPermissionStatusInfo]()
    commands?.forEach { status in
      let qchatInfo = NIMQChatPermissionStatusInfo()
      if let type = status.permissionType?.convertQCathPermissionType() {
        qchatInfo.type = type
      }
      qchatInfo.status = status.status.convertQChtaType()
      authors.append(qchatInfo)
    }
    param.commands = authors
    return param
  }
}

public struct GetServerRoleMembersParam {
  public var serverId: UInt64?
  public var roleId: UInt64?
  public var timeTag: Double?
  public var accid: String?
  public var limit: Int?

  public init() {}

  func toImParam() -> NIMQChatGetServerRoleMembersParam {
    let param = NIMQChatGetServerRoleMembersParam()
    if let sid = serverId {
      param.serverId = sid
    }
    if let rid = roleId {
      param.roleId = rid
    }
    if let t = timeTag {
      param.timeTag = t
    }
    if let uid = accid {
      param.accid = uid
    }
    if let l = limit {
      param.limit = l
    }
    return param
  }
}

public struct GetExistingServerRoleMembersByAccidsParam {
  public var serverId: UInt64?
  public var roleId: UInt64?
  public var accids: [String]?

  public init() {}

  public func toImParam() -> NIMQChatGetExistingServerRoleMembersByAccidsParam {
    let param = NIMQChatGetExistingServerRoleMembersByAccidsParam()
    if let sid = serverId {
      param.serverId = sid
    }
    if let rid = roleId {
      param.roleId = rid
    }
    if let aids = accids {
      param.accids = aids
    }
    return param
  }
}
