
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
@_exported import NEChatKit
@_exported import NEBaseUIKit

let teamUIKitLoader = NEChatKitResourceLoader<NEBaseTeamSettingViewController>()
func localizable(_ key: String) -> String {
  teamUIKitLoader.localizable(key)
}

func teamErrorToast(_ error: Error?) -> String {
  guard let error else {
    return commonLocalizable("failed_operation")
  }

  switch (error as NSError).code {
  case protocolSendFailed:
    return commonLocalizable("network_error")
  case teamNotExistCode:
    return commonLocalizable("team_not_exist")
  case noPermissionCode, noPermissionInviteCode, noPermissionOperationCode:
    return localizable("no_permission_tip")
  case teamMemberLimitExceededCode:
    return localizable("team_member_limit_exceeded")
  case joinedTeamLimitExceededCode:
    return localizable("joined_team_limit_exceeded")
  case alreadyInTeamCode:
    return localizable("already_in_the_team")
  case invitationExpiredCode:
    return localizable("invitation_expired")
  case teamMemberNotExist:
    return commonLocalizable("team_member_not_exist")
  default:
    return commonLocalizable("failed_operation")
  }
}

public let ModuleName = "NETeamUIKit"

enum NotificationName {
  static let leaveTeamBySelf = Notification.Name(rawValue: "team.leaveTeamBySelf")
  static let popGroupChatVC = Notification.Name(rawValue: "team.popGroupChatVC")
}
