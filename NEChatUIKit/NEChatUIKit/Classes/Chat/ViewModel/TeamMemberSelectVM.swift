// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NIMSDK

@objcMembers
open class TeamMemberSelectVM: NSObject {
  public var teamRepo = TeamRepo.shared
  private let className = "TeamMemberSelectVM"

  let teamProvider = TeamProvider.shared

  open func getTeamMembers(_ teamId: String,
                           _ completion: @escaping (Error?, NETeamInfoModel?) -> Void) {
    getTeamMembers(teamId, progress: nil, completion)
  }

  @nonobjc
  open func getTeamMembers(_ teamId: String,
                           progress: ((NETeamMemberLoadProgress) -> Void)?,
                           _ completion: @escaping (Error?, NETeamInfoModel?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", teamId: " + teamId)
    if let team = NETeamUserManager.shared.getTeamInfo(),
       team.teamId == teamId,
       let teamMembers = NETeamUserManager.shared.getAllTeamMemberModels() {
      let model = NETeamInfoModel()
      model.team = team
      model.users = teamMembers
      completion(nil, model)
    } else {
      NETeamUserManager.shared.getAllTeamMembers(
        teamId,
        .TEAM_MEMBER_ROLE_QUERY_TYPE_ALL,
        progress: progress
      ) { _ in
        let team = NETeamUserManager.shared.getTeamInfo()
        if team?.teamId == teamId,
           let teamMembers = NETeamUserManager.shared.getAllTeamMemberModels() {
          let model = NETeamInfoModel()
          model.team = team
          model.users = teamMembers
          completion(nil, model)
        } else {
          completion(nil, nil)
        }
      }
    }
  }
}
