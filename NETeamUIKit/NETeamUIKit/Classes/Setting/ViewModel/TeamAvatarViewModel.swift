//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class TeamAvatarViewModel: NSObject {
  let repo = ChatRepo.shared
  var currentTeamMember: NIMTeamMember?

  func getCurrentUserTeamMember(_ teamId: String?) {
    if let tid = teamId {
      let currentUserAccid = IMKitClient.instance.imAccid()
      currentTeamMember = repo.getTeamMemberList(userId: currentUserAccid, teamId: tid)
    }
  }
}
