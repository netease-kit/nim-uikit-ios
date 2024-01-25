//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

@objcMembers
open class NESelectTeamMember: NSObject {
  var isSelected: Bool = false
  var member: TeamMemberInfoModel?
}
