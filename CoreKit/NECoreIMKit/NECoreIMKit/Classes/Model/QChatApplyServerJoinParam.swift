
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public struct QChatApplyServerJoinParam {
  // 申请加入的服务器Id
  public var serverId: UInt64
  // 附言（最长5000）
  public var postscript: String?

  public init(serverId: UInt64) {
    self.serverId = serverId
  }

  func toIMParam() -> NIMQChatApplyServerJoinParam {
    let imParam = NIMQChatApplyServerJoinParam()
    imParam.serverId = serverId
    imParam.postscript = postscript ?? ""
    return imParam
  }
}
