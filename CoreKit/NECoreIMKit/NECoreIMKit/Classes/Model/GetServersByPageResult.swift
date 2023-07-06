
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public struct GetServersByPageResult {
  public var servers = [QChatServer]()

  init(serversResult: NIMQChatGetServersByPageResult?) {
    guard let serverArray = serversResult?.servers else { return }

    for server in serverArray {
      let itemModel = QChatServer(server: server)
      servers.append(itemModel)
    }
  }
}
