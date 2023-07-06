
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
public struct CreateServerResult {
  public var server: QChatServer?

  init(serverResult: NIMQChatCreateServerResult?) {
    server = QChatServer(server: serverResult?.server)
  }
}
