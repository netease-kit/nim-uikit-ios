
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
@_exported import NECoreKit
@_exported import NECommonUIKit
@_exported import NECommonKit
@_exported import NETeamKit
@_exported import NECoreIMKit
let coreLoader = CoreLoader<TeamSettingViewController>()
func localizable(_ key: String) -> String {
  coreLoader.localizable(key)
}

public let ModuleName = "NETeamUIKit"
