
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import Foundation
@_exported import NEKitCore
@_exported import NEKitCommonUI
//@_exported 
@_exported import NEKitCommon
@_exported import NEKitTeam
@_exported import SDWebImage
@_exported import NEKitCoreIM
let coreLoader = CoreLoader<TeamSettingViewController>()
func localizable(_ key: String) -> String{
    return coreLoader.localizable(key)
}
