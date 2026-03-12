
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

@objcMembers
open class ConversationRouter: NSObject {
  /// 注册通用路由
  static func registerCommon() {
    Router.shared.register("ClearAtMessageRemind") { param in
      if let sessionId = param["sessionId"] as? String {
        NEAtMessageManager.instance?.clearAtRecord(sessionId)
      }
    }
  }
}
