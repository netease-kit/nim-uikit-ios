
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

public extension UIImage {
  /// 修复图片旋转
  func fixOrientation() -> UIImage {
    // 默认方向无需旋转
    if imageOrientation == .up {
      return self
    }

    var transform = CGAffineTransform.identity

    switch imageOrientation {
    // 默认方向旋转180度、镜像旋转180度
    case .down, .downMirrored:
      transform = transform.translatedBy(x: size.width, y: size.height)
      transform = transform.rotated(by: .pi)

    // 默认方向逆时针旋转90度、镜像逆时针旋转90度
    case .left, .leftMirrored:
      transform = transform.translatedBy(x: size.width, y: 0)
      transform = transform.rotated(by: .pi / 2)

    // 默认方向顺时针旋转90度、镜像顺时针旋转90度
    case .right, .rightMirrored:
      transform = transform.translatedBy(x: 0, y: size.height)
      transform = transform.rotated(by: -.pi / 2)

    default:
      break
    }

    switch imageOrientation {
    // 默认方向的竖线镜像、镜像旋转180度
    case .upMirrored, .downMirrored:
      transform = transform.translatedBy(x: size.width, y: 0)
      transform = transform.scaledBy(x: -1, y: 1)

    // 镜像逆时针旋转90度、镜像顺时针旋转90度
    case .leftMirrored, .rightMirrored:
      transform = transform.translatedBy(x: size.height, y: 0)
      transform = transform.scaledBy(x: -1, y: 1)

    default:
      break
    }

    let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: cgImage!.bitsPerComponent, bytesPerRow: 0, space: cgImage!.colorSpace!, bitmapInfo: cgImage!.bitmapInfo.rawValue)
    ctx?.concatenate(transform)

    // 重新绘制
    switch imageOrientation {
    case .left, .leftMirrored, .right, .rightMirrored:
      ctx?.draw(cgImage!, in: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(size.height), height: CGFloat(size.width)))

    default:
      ctx?.draw(cgImage!, in: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(size.width), height: CGFloat(size.height)))
    }

    let cgimg: CGImage = (ctx?.makeImage())!
    let img = UIImage(cgImage: cgimg)

    return img
  }
}
