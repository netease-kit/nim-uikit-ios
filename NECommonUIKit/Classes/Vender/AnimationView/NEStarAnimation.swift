// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

extension CAShapeLayer {
  // MARK: Internal

  /// Adds animations for the given `NERectangle` to this `CALayer`
  @nonobjc
  func addAnimations(for star: NEStar,
                     context: NELayerAnimationContext,
                     pathMultiplier: PathMultiplier)
    throws {
    switch star.starType {
    case .star:
      try addStarAnimation(for: star, context: context, pathMultiplier: pathMultiplier)
    case .polygon:
      try addPolygonAnimation(for: star, context: context, pathMultiplier: pathMultiplier)
    case .none:
      break
    }
  }

  // MARK: Private

  @nonobjc
  private func addStarAnimation(for star: NEStar,
                                context: NELayerAnimationContext,
                                pathMultiplier: PathMultiplier)
    throws {
    try neAddAnimation(
      for: .path,
      keyframes: star.combinedKeyframes(),
      value: { keyframe in
        NEBezierPath.star(
          position: keyframe.position.pointValue,
          outerRadius: keyframe.outerRadius.cgFloatValue,
          innerRadius: keyframe.innerRadius.cgFloatValue,
          outerRoundedness: keyframe.outerRoundness.cgFloatValue,
          innerRoundedness: keyframe.innerRoundness.cgFloatValue,
          numberOfPoints: keyframe.points.cgFloatValue,
          rotation: keyframe.rotation.cgFloatValue,
          direction: star.direction
        )
        .cgPath()
        .duplicated(times: pathMultiplier)
      },
      context: context
    )
  }

  @nonobjc
  private func addPolygonAnimation(for star: NEStar,
                                   context: NELayerAnimationContext,
                                   pathMultiplier: PathMultiplier)
    throws {
    try neAddAnimation(
      for: .path,
      keyframes: star.combinedKeyframes(),
      value: { keyframe in
        NEBezierPath.polygon(
          position: keyframe.position.pointValue,
          numberOfPoints: keyframe.points.cgFloatValue,
          outerRadius: keyframe.outerRadius.cgFloatValue,
          outerRoundedness: keyframe.outerRoundness.cgFloatValue,
          rotation: keyframe.rotation.cgFloatValue,
          direction: star.direction
        )
        .cgPath()
        .duplicated(times: pathMultiplier)
      },
      context: context
    )
  }
}

extension NEStar {
  /// Data that represents how to render a star at a specific point in time
  struct NEKeyframe: NEInterpolatable {
    let position: NELottieVector3D
    let outerRadius: NELottieVector1D
    let innerRadius: NELottieVector1D
    let outerRoundness: NELottieVector1D
    let innerRoundness: NELottieVector1D
    let points: NELottieVector1D
    let rotation: NELottieVector1D

    func interpolate(to: NEStar.NEKeyframe, amount: CGFloat) -> NEStar.NEKeyframe {
      NEStar.NEKeyframe(
        position: position.interpolate(to: to.position, amount: amount),
        outerRadius: outerRadius.interpolate(to: to.outerRadius, amount: amount),
        innerRadius: innerRadius.interpolate(to: to.innerRadius, amount: amount),
        outerRoundness: outerRoundness.interpolate(to: to.outerRoundness, amount: amount),
        innerRoundness: innerRoundness.interpolate(to: to.innerRoundness, amount: amount),
        points: points.interpolate(to: to.points, amount: amount),
        rotation: rotation.interpolate(to: to.rotation, amount: amount)
      )
    }
  }

  /// Creates a single array of animatable keyframes from the separate arrays of keyframes in this star/polygon
  func combinedKeyframes() throws -> NEKeyframeGroup<NEKeyframe> {
    NEKeyframes.combined(
      position,
      outerRadius,
      innerRadius ?? NEKeyframeGroup(NELottieVector1D(0)),
      outerRoundness,
      innerRoundness ?? NEKeyframeGroup(NELottieVector1D(0)),
      points,
      rotation,
      makeCombinedResult: NEStar.NEKeyframe.init
    )
  }
}
