
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
public extension UIImage {
  class func ne_imageNamed(name: String?) -> UIImage? {
    guard let imageName = name, !imageName.isEmpty else {
      return nil
    }
    return coreLoader.loadImage(imageName)
  }
}
