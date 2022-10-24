// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEContactKit
import NECoreKit
import NECoreIMKit

@objcMembers
public class TeamListViewModel: NSObject {
  var contactRepo = ContactRepo()
  public var teamList = [Team]()
  private let className = "TeamListViewModel"

  func getTeamList() -> [Team]? {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    teamList = contactRepo.getTeamList()
    return teamList
  }
}
