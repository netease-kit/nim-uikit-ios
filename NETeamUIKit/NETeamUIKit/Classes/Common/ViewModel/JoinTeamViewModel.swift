// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit_coexist
import NECoreIM2Kit_coexist
import NIMSDK2

@objcMembers
open class JoinTeamViewModel: NSObject {
  let teamRepo = TeamRepo.shared
  private let className = "JoinTeamViewModel"

  open func getTeamInfo(_ text: String, _ completion: @escaping (V2NIM2Team?, Error?) -> Void) {
    NE2ALog.infoLog(ModuleName + " " + className, desc: #function + ", text: \(text.count)")

    teamRepo.getTeamInfo(text, .TEAM_TYPE_NORMAL, completion)
  }
}
