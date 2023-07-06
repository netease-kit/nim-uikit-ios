
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

/// eee
public enum NotificationType: Int {
//    申请入群
  case teamApply = 0
//    拒绝入群
  case teamApplyReject
//    邀请入群
  case teamInvite
//    拒绝入群邀请
  case teamInviteReject
//    添加好友 直接通过
  case addFriendDirectly
//    添加好友 需要对方同意
  case addFriendRequest
//    同意添加好友
  case addFriendVerify
//    拒绝添加好友
  case addFriendReject
//    申请入超大群
  case superTeamApply
//    拒绝入超大群
  case superTeamApplyReject
//    邀请入超大群
  case superTeamInvite
//    拒绝入超大群邀请
  case superTeamInviteReject
}

public enum IMHandleStatus: NSInteger {
  case HandleTypePending = 0
  case HandleTypeOk
  case HandleTypeNo
  case HandleTypeOutOfDate
}

@objcMembers
public class XNotification: NSObject {
  /// 操作者名字 只有NotificationType为addFriend相关操作有值
  public var sourceName: String?
  /// 目标名字,群名或者是用户名 只有群和高级群相关操作有值
  public var targetName: String?
  /// 通知 ID
  public var notificationId: Int64?
  /// 通知类型
  public var type: NotificationType?
  /// 时间戳
  public var timestamp: TimeInterval?
  /// 操作者
  public var sourceID: String?
  /// 目标ID,群ID或者是用户ID
  public var targetID: String?
  /// 附言
  public var postscript: String?
  /// 是否已读 修改这个属性并不会修改 db 中的数据
  public var read: Bool?
  /// 未读数
  public var unReadCount: Int
  /// 消息处理状态 修改这个属性,后台会自动更新 db 中对应的数据,SDK 调用者可以使用这个值来持久化他们对消息的处理结果,默认为 0
  public var handleStatus: IMHandleStatus
  /// 系统通知下发的自定义扩展信息
  public var notifyExt: String?
  /// 附件 额外信息,只有 好友添加 这个通知有附件 好友添加的 attachment 为 NIMUserAddAttachment
  public var attachment: NIMUserAddAttachment?
  /// 服务器扩展 只有type为添加好友相关类型是有值
  public var serverExt: String?
  /// 缓存IMSDK的通知
  public var imNotification: NIMSystemNotification?
  // 扩展字段(根据sourceId获取的用户信息)
  public var userInfo: User?
  // 扩展字段(根据targetId获取群信息)
  public var teamInfo: Team?
//  // 扩展字段(最新的通知)
//  public var lastMsg: XNotification?
  // 扩展字段(历史同类通知)
  public var msgList: [XNotification]?

//  public var avatar:String?

  init(notification: NIMSystemNotification?) {
    imNotification = notification
    notificationId = notification?.notificationId
    switch notification?.type {
    case .teamApply:
      type = .teamApply
    case .teamApplyReject:
      type = .teamApplyReject
    case .teamInvite:
      type = .teamInvite
    case .teamIviteReject:
      type = .teamInviteReject
    case .friendAdd:
      let attach = notification?.attachment as! NIMUserAddAttachment
      serverExt = attach.serverExt
      attachment = attach
      switch attach.operationType {
      case .add:
        type = .addFriendDirectly
      case .request:
        type = .addFriendRequest
      case .verify:
        type = .addFriendVerify
      case .reject:
        type = .addFriendReject
      default:
        type = .addFriendDirectly
      }
    case .superTeamApply:
      type = .superTeamApply
    case .superTeamApplyReject:
      type = .superTeamApplyReject
    case .superTeamInvite:
      type = .superTeamInvite
    case .superTeamIviteReject:
      type = .superTeamInviteReject
    default:
      type = .addFriendDirectly
    }

    switch notification?.handleStatus {
    case 0:
      handleStatus = .HandleTypePending
    case 1:
      handleStatus = .HandleTypeOk
    case 2:
      handleStatus = .HandleTypeNo
    case 3:
      handleStatus = .HandleTypeOutOfDate
    default:
      handleStatus = .HandleTypePending
    }

    timestamp = notification?.timestamp
    sourceID = notification?.sourceID
    targetID = notification?.targetID

    postscript = notification?.postscript
    read = notification?.read
    unReadCount = 0
    notifyExt = notification?.notifyExt
    sourceName = sourceID
  }

  public func isEqualTo(noti: XNotification) -> Bool {
    if type == noti.type,
       sourceID == noti.sourceID,
       targetID == noti.targetID,
       handleStatus == noti.handleStatus {
      return true
    }
    return false
  }
}
