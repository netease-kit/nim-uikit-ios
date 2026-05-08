
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIM2Kit
import NIMSDK

public typealias NESelectTeamMemberBlock = ([NETeamMemberInfoModel]) -> Void

@objcMembers
public class NETeamMemberInfoModel: NSObject {
  public var nimUser: NEUserWithFriend?
  public var teamMember: V2NIMTeamMember?

  // 昵称 > account
  open func showNickInTeam() -> String? {
    if let uNick = nimUser?.showName(), !uNick.isEmpty {
      return uNick
    }
    return nil
  }

  // 群昵称 > 昵称 > account (@高亮文本)
  open func showNameInTeam() -> String? {
    if let nick = teamMember?.teamNick, !nick.isEmpty {
      return nick
    }
    if let uNick = nimUser?.showName(false), !uNick.isEmpty {
      return uNick
    }
    return nil
  }

  // 好友备注 > 群昵称 > 昵称 > account
  open func atNameInTeam() -> String? {
    if let uNick = nimUser?.friend?.alias, !uNick.isEmpty {
      return uNick
    }
    return showNameInTeam()
  }

  /// 全名后几位
  open func getShortName(_ name: String, _ length: Int = 2) -> String {
    name
      .count > length ? String(name[name.index(name.endIndex, offsetBy: -length)...]) : name
  }
}
