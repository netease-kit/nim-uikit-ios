// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit
import UIKit

let IMUIKit_Style_Key = "imuikit_style_key"
let CHANGE_UI = "change_ui"

let coreLoader = CommonLoader<AppDelegate>()
func localizable(_ key: String) -> String {
  coreLoader.localizable(key)
}
