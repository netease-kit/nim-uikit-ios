
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
import CoreVideo

public enum RoleType {
  case white
  case black
}

public enum QChatOperationType {
  case add
  case remove
}

public struct UpdateChannelBlackWhiteMembersParam {
  public var serverId: UInt64?
  public var channelId: UInt64?
  public var type: RoleType?
  public var opeType: QChatOperationType?
  public var accids: [String]?
  public init(serverId: UInt64?, channelId: UInt64?, type: RoleType?,
              opeType: QChatOperationType?, accids: [String]?) {
    self.serverId = serverId
    self.channelId = channelId
    self.type = type
    self.opeType = opeType
    self.accids = accids
  }

  public func toIMParam() -> NIMQChatUpdateChannelBlackWhiteMembersParam {
    let imParam = NIMQChatUpdateChannelBlackWhiteMembersParam()
    imParam.serverId = serverId ?? 0
    imParam.channelId = channelId ?? 0
    switch type {
    case .white:
      imParam.type = .white
    case .black:
      imParam.type = .black
    default:
      imParam.type = .white
    }

    switch opeType {
    case .add:
      imParam.opeType = .add
    case .remove:
      imParam.opeType = .remove
    default:
      imParam.opeType = .add
    }
    imParam.accids = accids ?? [String]()
    return imParam
  }
}
