
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
public struct QChatGetServerMembersParam {
  public var serverAccIds: [QChatGetServerMemberItem]?

  public init(serverAccIds: [QChatGetServerMemberItem]?) {
    self.serverAccIds = serverAccIds
  }

  func toIMParam() -> NIMQChatGetServerMembersParam {
    let imParam = NIMQChatGetServerMembersParam()
    var items = [NIMQChatGetServerMemberItem]()
    serverAccIds?.forEach { memberItem in
      let item = NIMQChatGetServerMemberItem()
      item.accid = memberItem.accid ?? ""
      item.serverId = memberItem.serverId ?? 0
      items.append(item)
    }
    imParam.serverAccids = items
    return imParam
  }
}

public struct QChatGetServerMemberItem {
  public var serverId: UInt64?
  public var accid: String?

  public init(serverId: UInt64, accid: String) {
    self.serverId = serverId
    self.accid = accid
  }
}
