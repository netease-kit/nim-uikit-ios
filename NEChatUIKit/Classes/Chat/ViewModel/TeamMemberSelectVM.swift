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

  let teamProvider = TeamProvider.shared

  open func getTeamMembers(_ teamId: String,
                           _ completion: @escaping (Error?, NETeamInfoModel?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", teamId: " + teamId)
    if let team = NETeamUserManager.shared.getTeamInfo(),
       let teamMembers = NETeamUserManager.shared.getAllTeamMemberModels() {
      let model = NETeamInfoModel()
      model.team = team
      model.users = teamMembers
      completion(nil, model)
    } else {
      NETeamUserManager.shared.getAllTeamMembers(teamId, .TEAM_MEMBER_ROLE_QUERY_TYPE_ALL) { _ in
        let team = NETeamUserManager.shared.getTeamInfo()
        if let teamMembers = NETeamUserManager.shared.getAllTeamMemberModels() {
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
