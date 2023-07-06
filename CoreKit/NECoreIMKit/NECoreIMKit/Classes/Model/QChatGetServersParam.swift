
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public struct QChatGetServersParam {
  public var serverIds: [NSNumber]?

  public init(serverIds: [NSNumber]) {
    self.serverIds = serverIds
  }

  func toIMParam() -> NIMQChatGetServersParam {
    let imParam = NIMQChatGetServersParam()
    imParam.serverIds = serverIds ?? [NSNumber]()
    return imParam
  }
}
