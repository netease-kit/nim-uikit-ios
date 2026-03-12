
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIM2Kit
import NIMSDK

@objcMembers
public class NEAddApplication: NSObject {
  /// 申请添加好友的相关信息
  public var v2Notification: V2NIMFriendAddApplication

  /// 用于显示的用户 Id
  public var displayUserId: String?

  /// 用于显示的用户信息（包含好友信息）
  public var displayUserWithFriend: NEUserWithFriend?

  /// 未读数
  public var unreadCount: Int

  /// 消息处理状态 修改这个属性,后台会自动更新 db 中对应的数据,SDK 调用者可以使用这个值来持久化他们对消息的处理结果,默认为 0
  public var handleStatus: V2NIMFriendAddApplicationStatus = .FRIEND_ADD_APPLICATION_STATUS_INIT

  /// 操作描述
  public var detail: String = localizable("add_request")

  public init(_ info: V2NIMFriendAddApplication) {
    v2Notification = info
    displayUserId = info.applicantAccountId
    handleStatus = info.status
    unreadCount = info.read == false ? 1 : 0
  }

  // 是否是同一申请
  open func isEqualTo(_ noti: V2NIMFriendAddApplication,
                      _ compareStatus: Bool = true) -> Bool {
    if v2Notification.applicantAccountId == noti.applicantAccountId,
       v2Notification.recipientAccountId == noti.recipientAccountId {
      if compareStatus {
        return handleStatus == noti.status
      }
      return true
    }
    return false
  }
}
