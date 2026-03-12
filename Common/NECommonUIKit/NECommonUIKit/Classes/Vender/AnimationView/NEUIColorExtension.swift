// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#if canImport(UIKit)
  import UIKit

  public extension UIColor {
    var lottieColorValue: NELottieColor {
      var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
      getRed(&r, green: &g, blue: &b, alpha: &a)
      return NELottieColor(r: Double(r), g: Double(g), b: Double(b), a: Double(a))
    }
  }
#endif
