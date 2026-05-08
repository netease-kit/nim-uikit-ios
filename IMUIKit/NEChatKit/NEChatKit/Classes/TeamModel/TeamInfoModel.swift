
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIM2Kit
import NIMSDK

@objcMembers
public class NETeamInfoModel: NSObject {
  public var team: V2NIMTeam?
  public var users = [NETeamMemberInfoModel]()
}
