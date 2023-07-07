
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreKit

let coreLoader = CoreLoader<NEBaseConversationController>()
func localizable(_ key: String) -> String {
  coreLoader.localizable(key)
}

public let ModuleName = "NEConversationUIKit"

// 创建群聊 选择人数限制
public var inviteNumberLimit: Int = 200
