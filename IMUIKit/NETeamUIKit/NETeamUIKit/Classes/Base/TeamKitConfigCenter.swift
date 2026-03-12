
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK

@objcMembers
public class TeamKitConfigCenter: NSObject {
  public static let shared = TeamKitConfigCenter()

  override private init() {
    super.init()
  }

  /// 被邀请人同意入群模式
  public var teamAgreeMode: V2NIMTeamAgreeMode = .TEAM_AGREE_MODE_NO_AUTH

  /// 申请入群的模式
  public var teamJoinMode: V2NIMTeamJoinMode = .TEAM_JOIN_MODE_FREE
}
