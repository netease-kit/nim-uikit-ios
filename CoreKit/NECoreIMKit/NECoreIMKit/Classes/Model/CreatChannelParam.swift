
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public enum ChannelType: Int {
  case messageType = 0, customType = 100
}

public enum ChannelVisibleType {
  case isPublic
  case isPrivate
}

public struct CreatChannelParam {
  public var serverId: UInt64
  public var name: String
  public var topic: String?
  public var custom: String?
  public var visibleType: ChannelVisibleType = .isPublic
  public var type: ChannelType = .messageType

  public init(serverId: UInt64, name: String, topic: String?, visibleType: ChannelVisibleType) {
    self.serverId = serverId
    self.name = name
    self.topic = topic
    self.visibleType = visibleType
  }

  func toIMParam() -> NIMQChatCreateChannelParam {
    let imParam = NIMQChatCreateChannelParam()
    imParam.serverId = serverId
    imParam.name = name
    imParam.topic = topic ?? ""
    imParam.custom = custom ?? ""
    switch type {
    case .messageType:
      imParam.type = .msg
    default:
      imParam.type = .custom
    }
    switch visibleType {
    case .isPublic:
      imParam.viewMode = .public
    case .isPrivate:
      imParam.viewMode = .private
    }
    return imParam
  }
}
