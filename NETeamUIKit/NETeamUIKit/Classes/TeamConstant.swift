
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
@_exported import NEChatKit
@_exported import NECommonKit
@_exported import NECommonUIKit
@_exported import NECoreIMKit
@_exported import NECoreKit
let coreLoader = CoreLoader<NEBaseTeamSettingViewController>()
func localizable(_ key: String) -> String {
  coreLoader.localizable(key)
}

public let ModuleName = "NETeamUIKit"

// 邀请入群 选择人数限制
public var inviteNumberLimit: Int = 200

enum NotificationName {
  static let leaveTeamBySelf = Notification.Name(rawValue: "team.leaveTeamBySelf")
  static let popGroupChatVC = Notification.Name(rawValue: "team.popGroupChatVC")
}
