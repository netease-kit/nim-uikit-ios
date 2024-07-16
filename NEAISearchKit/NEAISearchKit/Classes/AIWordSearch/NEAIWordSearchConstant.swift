
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECoreKit

let ModuleName = "NEAISearchKit"

let coreLoader = CoreLoader<NEAISearchManager>()
func localizable(_ key: String) -> String {
  coreLoader.localizable(key)
}

let textFont = UIFont.systemFont(ofSize: 14)
let textMaxSize = CGSize(width: NEConstant.screenWidth - 20 * 2, height: CGFloat.greatestFiniteMagnitude)

public extension UIImage {
  class func ne_imageNamed(name: String?) -> UIImage? {
    guard let imageName = name, !imageName.isEmpty else {
      return nil
    }
    return coreLoader.loadImage(imageName)
  }
}
