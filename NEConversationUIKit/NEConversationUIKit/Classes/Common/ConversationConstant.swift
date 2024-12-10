
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit

let coreLoader = CommonLoader<NEBaseConversationController>()
func localizable(_ key: String) -> String {
  coreLoader.localizable(key)
}

public let ModuleName = "NEConversationUIKit"

extension UIColor {
  static let securityWarningBg = UIColor(hexString: "#FFF5E1")
  static let securityWarningTextColor = UIColor(hexString: "#EB9718")
}
