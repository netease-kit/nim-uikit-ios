
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public struct UpdateServerMemberInfoParam {
  public var serverId: UInt64?

  public var accid: String?

  public var nick: String?

  public var avatar: String?

  public init() {}

  func toImPara() -> NIMQChatUpdateServerMemberInfoParam {
    let param = NIMQChatUpdateServerMemberInfoParam()
    if let sid = serverId {
      param.serverId = sid
    }
    if let aid = accid {
      param.accid = aid
    }
    if let n = nick {
      param.nick = n
    }
    if let a = avatar {
      param.avatar = a
    }
    return param
  }
}
