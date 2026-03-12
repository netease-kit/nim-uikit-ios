
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit

public let coreLoader = CommonLoader<TabNavigationView>()
public func commonLocalizable(_ key: String) -> String {
  coreLoader.localizable(key)
}

// let CommonScreenWidth: CGFloat = UIScreen.main.bounds.size.width
// let CommonScreenHeight: CGFloat = UIScreen.main.bounds.size.height

public let useSystemNav = "useSystemNav"
