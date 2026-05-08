
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIM2Kit
import NIMSDK

@objcMembers
public class ConversationListModel: NSObject {
  public var recentSession: NIMRecentSession?

  public var userInfo: NEUserWithFriend?
  public var teamInfo: NIMTeam?
  public var customType = 0
  public var localExtension: [String: Any]?
  override public init() {
    super.init()
  }
}
