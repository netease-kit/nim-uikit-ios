
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public enum TeamType: Int {
  case normalTeam = 0
  case advancedTeam
  case supereTeam
}

@objcMembers
public class Team: NSObject {
  // FIXME: 转换部分NIMTeam属性
  public var teamId: String?
  public var teamName: String?
  public var avatarUrl: String?
  public var thumbAvatarUrl: String?
  public var type: TeamType?
  /// 群拥有者ID 普通群拥有者就是群创建者,但是高级群可以进行拥有信息的转让
  public var owner: String?
  /// 群介绍
  public var intro: String?
  /// 群公告
  public var announcement: String?
  /// 群成员人数 这个值表示是上次登录后同步下来群成员数据,并不实时变化,必要时需要调用fetchTeamInfo:completion:进行刷新
  public var memberNumber: Int?
  /// 群等级 目前主要是限制群人数上限
  public var level: Int?
  /// 群创建时间
  public var createTime: TimeInterval?

  public var nimTeam: NIMTeam?

  public init(teamInfo: NIMTeam?) {
    teamId = teamInfo?.teamId
    teamName = teamInfo?.teamName
    avatarUrl = teamInfo?.avatarUrl
    thumbAvatarUrl = teamInfo?.thumbAvatarUrl
    switch teamInfo?.type {
    case .normal:
      type = .normalTeam
    case .advanced:
      type = .advancedTeam
    case .super:
      type = .supereTeam
    default:
      type = .normalTeam
    }
    owner = teamInfo?.owner
    intro = teamInfo?.intro
    announcement = teamInfo?.announcement
    memberNumber = teamInfo?.memberNumber
    level = teamInfo?.level
    createTime = teamInfo?.createTime
    nimTeam = teamInfo
  }
}
