// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics
import Foundation

extension NEKeyframe where T: NEAnyInterpolatable {
  func interpolate(to: NEKeyframe<T>, progress: CGFloat) -> T {
    value._interpolate(
      to: to.value,
      amount: progress,
      spatialOutTangent: spatialOutTangent?.pointValue,
      spatialInTangent: to.spatialInTangent?.pointValue
    )
  }
}

extension NEKeyframe {
  /// Interpolates the keyTime into a value from 0-1
  func interpolatedProgress(_ to: NEKeyframe, keyTime: CGFloat) -> CGFloat {
    let startTime = time
    let endTime = to.time
    if keyTime <= startTime {
      return 0
    }
    if endTime <= keyTime {
      return 1
    }

    if isHold {
      return 0
    }

    let outTanPoint = outTangent?.pointValue ?? .zero
    let inTanPoint = to.inTangent?.pointValue ?? CGPoint(x: 1, y: 1)
    var progress: CGFloat = keyTime.remap(fromLow: startTime, fromHigh: endTime, toLow: 0, toHigh: 1)
    if !outTanPoint.isZero || !inTanPoint.equalTo(CGPoint(x: 1, y: 1)) {
      /// Cubic interpolation
      progress = progress.cubicBezierInterpolate(.zero, outTanPoint, inTanPoint, CGPoint(x: 1, y: 1))
    }
    return progress
  }
}
