
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

extension CGColor {
  /// Initializes a `CGColor` using the given `RGB` values
  static func neRgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> CGColor {
    neRgba(red, green, blue, 1.0)
  }

  /// Initializes a `CGColor` using the given grayscale value
  static func neGray(_ gray: CGFloat) -> CGColor {
    CGColor(
      colorSpace: CGColorSpaceCreateDeviceGray(),
      components: [gray, 1.0]
    )!
  }

  /// Initializes a `CGColor` using the given `RGBA` values
  static func neRgba(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat) -> CGColor {
    CGColor(
      colorSpace: NELottieConfiguration.shared.colorSpace,
      components: [red, green, blue, alpha]
    )!
  }
}
