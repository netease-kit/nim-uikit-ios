
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

extension CAShapeLayer {
  /// Adds animations for the given `NEBezierPath` keyframes to this `CALayer`
  @nonobjc
  func addAnimations(for customPath: NEKeyframeGroup<NEBezierPath>,
                     context: NELayerAnimationContext,
                     pathMultiplier: PathMultiplier = 1,
                     transformPath: (CGPath) -> CGPath = { $0 },
                     roundedCorners: NERoundedCorners? = nil)
    throws {
    let combinedKeyframes = try NEBezierPathKeyframe.combining(
      path: customPath,
      cornerRadius: roundedCorners?.radius
    )

    try neAddAnimation(
      for: .path,
      keyframes: combinedKeyframes,
      value: { pathKeyframe in
        var path = pathKeyframe.path
        if let cornerRadius = pathKeyframe.cornerRadius {
          path = path.roundCorners(radius: cornerRadius.cgFloatValue)
        }

        return transformPath(path.cgPath().duplicated(times: pathMultiplier))
      },
      context: context
    )
  }
}

extension CGPath {
  /// Duplicates this `CGPath` so that it is repeated the given number of times
  func duplicated(times: Int) -> CGPath {
    if times <= 1 {
      return self
    }

    let cgPath = CGMutablePath()

    for _ in 0 ..< times {
      cgPath.addPath(self)
    }

    return cgPath
  }
}

// MARK: - NEBezierPathKeyframe

/// Data that represents how to render a bezier path at a specific point in time
struct NEBezierPathKeyframe: NEInterpolatable {
  let path: NEBezierPath
  let cornerRadius: NELottieVector1D?

  /// Creates a single array of animatable keyframes from the given sets of keyframes
  /// that can have different counts / timing parameters
  static func combining(path: NEKeyframeGroup<NEBezierPath>,
                        cornerRadius: NEKeyframeGroup<NELottieVector1D>?) throws
    -> NEKeyframeGroup<NEBezierPathKeyframe> {
    guard
      let cornerRadius,
      cornerRadius.keyframes.contains(where: { $0.value.cgFloatValue > 0 })
    else {
      return path.map { path in
        NEBezierPathKeyframe(path: path, cornerRadius: nil)
      }
    }

    return NEKeyframes.combined(
      path, cornerRadius,
      makeCombinedResult: NEBezierPathKeyframe.init
    )
  }

  func interpolate(to: NEBezierPathKeyframe, amount: CGFloat) -> NEBezierPathKeyframe {
    NEBezierPathKeyframe(
      path: path.interpolate(to: to.path, amount: amount),
      cornerRadius: cornerRadius.interpolate(to: to.cornerRadius, amount: amount)
    )
  }
}
