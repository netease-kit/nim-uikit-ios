// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics
import Foundation

extension String {
  var cgColor: CGColor {
    let (red, green, blue) = hexColorComponents()
    return .neRgb(red, green, blue)
  }

  var lottieColor: NELottieColor {
    let (red, green, blue) = hexColorComponents()
    return .init(r: red, g: green, b: blue, a: 1.0)
  }

  func hexColorComponents() -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
    var cString: String = trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

    if cString.hasPrefix("#") {
      cString.remove(at: cString.startIndex)
    }

    if (cString.count) != 6 {
      return (red: 0, green: 0, blue: 0)
    }

    var rgbValue: UInt64 = 0
    Scanner(string: cString).scanHexInt64(&rgbValue)

    return (
      red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
      green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
      blue: CGFloat(rgbValue & 0x0000FF) / 255.0
    )
  }
}
