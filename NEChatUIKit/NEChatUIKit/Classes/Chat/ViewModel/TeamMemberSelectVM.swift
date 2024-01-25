// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIMKit
import NIMSDK

@objcMembers
open class TeamMemberSelectVM: NSObject {
  public var chatRepo = ChatRepo.shared
  private let className = "TeamMemberSelectVM"

  open func fetchTeamMembers(sessionId: String,
                             _ completion: @escaping (Error?, ChatTeamInfoModel?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", sessionId: " + sessionId)
    chatRepo.getTeamInfo(sessionId, completion)
  }
}
