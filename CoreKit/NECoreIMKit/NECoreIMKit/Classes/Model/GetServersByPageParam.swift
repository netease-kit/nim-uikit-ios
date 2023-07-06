
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
public struct GetServersByPageParam {
  /// 时间戳
  public var timeTag: TimeInterval?

  /// 条数限制
  public var limit: Int?

  public init(timeTag: TimeInterval, limit: Int) {
    self.timeTag = timeTag
    self.limit = limit
  }

  func toIMParam() -> NIMQChatGetServersByPageParam {
    let imParam = NIMQChatGetServersByPageParam()
    imParam.timeTag = timeTag ?? 0
    imParam.limit = limit ?? 0
    return imParam
  }
}
