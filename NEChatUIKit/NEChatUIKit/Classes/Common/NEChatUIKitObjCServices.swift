// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NIMSDK
import UIKit

public extension NotificationMessageUtils {
  @objc(teamLeaveOrDismissResult:)
  static func objcTeamLeaveOrDismissResult(_ message: V2NIMMessage) -> NENotificationTeamStateResult {
    let result = isTeamLeaveOrDismiss(message: message)
    return NENotificationTeamStateResult(isLeave: result.isLeave,
                                         isDismiss: result.isDismiss)
  }
}

public extension NETeamUserManager {
  @objc(getAllTeamMemberWithMaxLimit:nextToken:memberList:queryType:completion:)
  func objcGetAllTeamMemberWithMaxLimit(
    _ teamId: String,
    nextToken: String?,
    memberList: [V2NIMTeamMember],
    queryType: V2NIMTeamMemberRoleQueryType,
    completion: @escaping ([V2NIMTeamMember]?, NSError?) -> Void
  ) {
    var accumulatedMembers = memberList
    getAllTeamMemberWithMaxLimit(teamId,
                                 nextToken,
                                 &accumulatedMembers,
                                 queryType,
                                 completion)
  }
}
