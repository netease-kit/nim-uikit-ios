// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

extension CAShapeLayer {
  /// Adds animations for the given `NERectangle` to this `CALayer`
  @nonobjc
  func addAnimations(for rectangle: NERectangle,
                     context: NELayerAnimationContext,
                     pathMultiplier: PathMultiplier,
                     roundedCorners: NERoundedCorners?)
    throws {
    try neAddAnimation(
      for: .path,
      keyframes: rectangle.combinedKeyframes(roundedCorners: roundedCorners),
      value: { keyframe in
        NEBezierPath.rectangle(
          position: keyframe.position.pointValue,
          size: keyframe.size.sizeValue,
          cornerRadius: keyframe.cornerRadius.cgFloatValue,
          direction: rectangle.direction
        )
        .cgPath()
        .duplicated(times: pathMultiplier)
      },
      context: context
    )
  }
}

extension NERectangle {
  /// Data that represents how to render a rectangle at a specific point in time
  struct NEKeyframe: NEInterpolatable {
    let size: NELottieVector3D
    let position: NELottieVector3D
    let cornerRadius: NELottieVector1D

    func interpolate(to: NERectangle.NEKeyframe, amount: CGFloat) -> NERectangle.NEKeyframe {
      NERectangle.NEKeyframe(
        size: size.interpolate(to: to.size, amount: amount),
        position: position.interpolate(to: to.position, amount: amount),
        cornerRadius: cornerRadius.interpolate(to: to.cornerRadius, amount: amount)
      )
    }
  }

  /// Creates a single array of animatable keyframes from the separate arrays of keyframes in this NERectangle
  func combinedKeyframes(roundedCorners: NERoundedCorners?) throws -> NEKeyframeGroup<NERectangle.NEKeyframe> {
    let cornerRadius = roundedCorners?.radius ?? cornerRadius
    return NEKeyframes.combined(
      size, position, cornerRadius,
      makeCombinedResult: NERectangle.NEKeyframe.init
    )
  }
}
