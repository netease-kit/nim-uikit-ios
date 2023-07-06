
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
public struct QChatInviteServerMembersParam {
  // 圈组服务器ID
  public var serverId: UInt64?
  // 邀请对象的账号数组
  public var accids: [String]?
  // 附言（最长5000）
  public var postscript: String?

  public init(serverId: UInt64, accids: [String]) {
    self.serverId = serverId
    self.accids = accids
  }

  func toImParam() -> NIMQChatInviteServerMembersParam {
    let imParam = NIMQChatInviteServerMembersParam()
    if let id = serverId {
      imParam.serverId = id
    }
    if let accids = accids {
      imParam.accids = accids
    }
    imParam.postscript = postscript
    return imParam
  }
}
