
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import Foundation
import CoreGraphics
import UIKit
extension UIImage {
    public class func ne_imageNamed(name: String?) -> UIImage? {
        guard let imageName = name else {
            return nil
        }
        return coreLoader.loadImage(imageName)
//        guard let path = Bundle(for: ChatBaseCell.self).resourcePath?.appending("/NEKitQChatUI.bundle") else {
//            print("Image:\(imageName) path: nil")
//            return nil
//        }
//        let image = UIImage(named: imageName, in: Bundle(path: path), compatibleWith: nil)
//        print("Bundle:\(Bundle(path: path))")
//        print("imageName:\(imageName) image:\(image)")
//        return image
    }
    
    public class func ne_bundleImage(name: String) -> UIImage {
         //图片放到 framework 的 bundle 中可使用
         let bundleName = "NIMKitEmoticon.bundle/Emoji/\(name)"
        if let image = UIImage.ne_imageNamed(name: bundleName) {
             return image
         }
         return UIImage()
     }

}
