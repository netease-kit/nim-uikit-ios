
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

import NIMSDK
public struct QChatGetExistingAccidsInServerRoleParam {
  public var serverId: UInt64
  public var accids: [String]?

  public init(serverId: UInt64, accids: [String]) {
    self.serverId = serverId
    self.accids = accids
  }

  func toImParam() -> NIMQChatGetExistingAccidsInServerRoleParam {
    let imParam = NIMQChatGetExistingAccidsInServerRoleParam()
    imParam.serverId = serverId
    if let accidArray = accids {
      imParam.accids = accidArray
    }
    return imParam
  }
}
