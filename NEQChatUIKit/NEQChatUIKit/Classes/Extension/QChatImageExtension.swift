
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import CoreGraphics
import UIKit
public extension UIImage {
  class func ne_imageNamed(name: String?) -> UIImage? {
    guard let imageName = name else {
      return nil
    }
    return coreLoader.loadImage(imageName)
//        guard let path = Bundle(for:
//        QChatBaseCell.self).resourcePath?.appending("/NEQChatUIKit.bundle") else {
//            print("Image:\(imageName) path: nil")
//            return nil
//        }
//        let image = UIImage(named: imageName, in: Bundle(path: path), compatibleWith: nil)
//        print("Bundle:\(Bundle(path: path))")
//        print("imageName:\(imageName) image:\(image)")
//        return image
  }
}
