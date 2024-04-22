// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIM2Kit
import NIMSDK

@objcMembers
open class TeamMemberSelectVM: NSObject {
  public var teamRepo = TeamRepo.shared
  private let className = "TeamMemberSelectVM"

  open func fetchTeamMembers(sessionId: String,
                             _ completion: @escaping (Error?, NETeamInfoModel?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", sessionId: " + sessionId)
    teamRepo.getTeamWithMembers(sessionId, .TEAM_MEMBER_ROLE_QUERY_TYPE_ALL, completion)
  }
}
