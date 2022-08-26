
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEKitCore

let coreLoader = CoreLoader<ConversationController>()
func localizable(_ key: String) -> String {
  coreLoader.localizable(key)
}
