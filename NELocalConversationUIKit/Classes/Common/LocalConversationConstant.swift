
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit

let localConversationCoreLoader = CommonLoader<NEBaseLocalConversationController>()
func localizable(_ key: String) -> String {
  localConversationCoreLoader.localizable(key)
}

public let ModuleName = "NELocalConversationUIKit"
