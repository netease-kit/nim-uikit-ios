
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics
import Foundation
import UIKit
public extension UIImage {
  class func ne_imageNamed(name: String?) -> UIImage? {
    guard let imageName = name else {
      return nil
    }
    return coreLoader.loadImage(imageName)
  }

  class func ne_bundleImage(name: String) -> UIImage {
    // 图片放到 framework 的 bundle 中可使用
    let bundleName = "NIMKitEmoticon.bundle/Emoji/\(name)"
    if let image = UIImage.ne_imageNamed(name: bundleName) {
      return image
    }
    return UIImage()
  }
}
