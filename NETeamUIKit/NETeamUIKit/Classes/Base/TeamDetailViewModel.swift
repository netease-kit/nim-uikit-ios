// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreMedia
import Foundation
import NEChatKit
import NECoreIM2Kit
import NIMSDK

@objcMembers
open class TeamDetailViewModel: NSObject {
  let teamRepo = TeamRepo.shared
  private let className = "ContactUserViewModel"

  open func applyJoinTeam(_ teamId: String, _ completion: @escaping (V2NIMTeam?, Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", teamId: " + teamId)

    teamRepo.applyJoinTeam(teamId: teamId, teamType: .TEAM_TYPE_NORMAL, postscript: nil, completion)
  }

  open func getTeamInfo(_ teamId: String, _ completion: @escaping (V2NIMTeam?, Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", teamId: " + teamId)
    teamRepo.getTeamInfo(teamId, .TEAM_TYPE_NORMAL, completion)
  }
}
