
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIM2Kit
import NIMSDK

/// 入群申请已读时间戳
public var neTeamJoinActionReadTime: TimeInterval = UserDefaults.standard.double(forKey: keyTeamJoinActionReadTime)

/// 入群申请分页查询数量
public var neTeamJoinActionPageLimit = 100

@objcMembers
public class NETeamJoinAction: NSObject {
  /// 申请添加好友的相关信息
  public var nimTeamJoinAction: V2NIMTeamJoinActionInfo

  /// 用于显示的用户 Id
  public var displayUserId: String

  /// 用于显示的用户信息（包含好友信息）
  public var displayUserWithFriend: NEUserWithFriend?

  /// 用于显示的群信息
  public var displayTeam: V2NIMTeam?

  /// 未读数
  public var unreadCount: Int

  /// 消息处理状态 修改这个属性,后台会自动更新 db 中对应的数据,SDK 调用者可以使用这个值来持久化他们对消息的处理结果,默认为 0
  public var handleStatus: V2NIMTeamJoinActionStatus = .TEAM_JOIN_ACTION_STATUS_INIT

  /// 操作描述
  public var detail: String = localizable("add_request")

  public init(_ info: V2NIMTeamJoinActionInfo) {
    nimTeamJoinAction = info
    displayUserId = info.operatorAccountId
    handleStatus = info.actionStatus
    unreadCount = info.timestamp > neTeamJoinActionReadTime ? 1 : 0
  }

  // 是否是同一申请
  open func isEqualTo(_ noti: V2NIMTeamJoinActionInfo,
                      _ compareStatus: Bool = true) -> Bool {
    if nimTeamJoinAction.operatorAccountId == noti.operatorAccountId,
       nimTeamJoinAction.teamId == noti.teamId,
       nimTeamJoinAction.actionType == noti.actionType {
      if compareStatus {
        return handleStatus == noti.actionStatus
      }
      return true
    }
    return false
  }
}
