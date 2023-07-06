
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public struct GetExistingAccidsOfMemberRolesParam {
  public var serverId: UInt64
  public var channelId: UInt64
  public var accids: [String]

  public init(serverId: UInt64, channelId: UInt64, accids: [String]) {
    self.serverId = serverId
    self.channelId = channelId
    self.accids = accids
  }

  func toIMParam() -> NIMQChatGetExistingAccidsOfMemberRolesParam {
    let imParam = NIMQChatGetExistingAccidsOfMemberRolesParam()
    imParam.serverId = serverId
    imParam.channelId = channelId
    imParam.accids = accids
    return imParam
  }
}
