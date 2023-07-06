
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.
import Foundation
import NIMSDK

public struct AddMemberRoleParam {
  public var serverId: UInt64?
  public var channelId: UInt64?
  public var accid: String?

  public init(serverId: UInt64?, channelId: UInt64?, accid: String?) {
    self.serverId = serverId
    self.channelId = channelId
    self.accid = accid
  }

  public func toIMParam() -> NIMQChatAddMemberRoleParam {
    let imParam = NIMQChatAddMemberRoleParam()
    imParam.serverId = serverId ?? 0
    imParam.channelId = channelId ?? 0
    imParam.accid = accid ?? ""
    return imParam
  }
}
