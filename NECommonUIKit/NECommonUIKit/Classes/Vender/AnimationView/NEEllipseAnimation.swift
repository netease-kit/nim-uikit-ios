// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

extension CAShapeLayer {
  /// Adds animations for the given `NEEllipse` to this `CALayer`
  @nonobjc
  func addAnimations(for ellipse: NEEllipse,
                     context: NELayerAnimationContext,
                     pathMultiplier: PathMultiplier)
    throws {
    try neAddAnimation(
      for: .path,
      keyframes: ellipse.combinedKeyframes(),
      value: { keyframe in
        NEBezierPath.ellipse(
          size: keyframe.size.sizeValue,
          center: keyframe.position.pointValue,
          direction: ellipse.direction
        )
        .cgPath()
        .duplicated(times: pathMultiplier)
      },
      context: context
    )
  }
}

extension NEEllipse {
  /// Data that represents how to render an ellipse at a specific point in time
  struct NEKeyframe: NEInterpolatable {
    let size: NELottieVector3D
    let position: NELottieVector3D

    func interpolate(to: NEEllipse.NEKeyframe, amount: CGFloat) -> NEEllipse.NEKeyframe {
      NEKeyframe(
        size: size.interpolate(to: to.size, amount: amount),
        position: position.interpolate(to: to.position, amount: amount)
      )
    }
  }

  /// Creates a single array of animatable keyframes from the separate arrays of keyframes in this NEEllipse
  func combinedKeyframes() throws -> NEKeyframeGroup<NEEllipse.NEKeyframe> {
    NEKeyframes.combined(
      size, position,
      makeCombinedResult: NEEllipse.NEKeyframe.init
    )
  }
}
