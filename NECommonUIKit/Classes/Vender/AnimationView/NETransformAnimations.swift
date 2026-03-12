// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NETransformModel

/// This protocol mirrors the interface of `NETransform`,
/// but is also implemented by `NEShapeTransform` to allow
/// both transform types to share the same animation implementation.
protocol NETransformModel {
  /// The anchor point of the transform.
  var anchorPoint: NEKeyframeGroup<NELottieVector3D> { get }

  /// The position of the transform. This is nil if the position data was split.
  var _position: NEKeyframeGroup<NELottieVector3D>? { get }

  /// The positionX of the transform. This is nil if the position property is set.
  var _positionX: NEKeyframeGroup<NELottieVector1D>? { get }

  /// The positionY of the transform. This is nil if the position property is set.
  var _positionY: NEKeyframeGroup<NELottieVector1D>? { get }

  /// The scale of the transform
  var scale: NEKeyframeGroup<NELottieVector3D> { get }

  /// The rotation of the transform on X axis.
  var rotationX: NEKeyframeGroup<NELottieVector1D> { get }

  /// The rotation of the transform on Y axis.
  var rotationY: NEKeyframeGroup<NELottieVector1D> { get }

  /// The rotation of the transform on Z axis.
  var rotationZ: NEKeyframeGroup<NELottieVector1D> { get }

  /// The skew of the transform (only present on `NEShapeTransform`s)
  var _skew: NEKeyframeGroup<NELottieVector1D>? { get }

  /// The skew axis of the transform (only present on `NEShapeTransform`s)
  var _skewAxis: NEKeyframeGroup<NELottieVector1D>? { get }
}

// MARK: - NETransform + NETransformModel

extension NETransform: NETransformModel {
  var _position: NEKeyframeGroup<NELottieVector3D>? { position }
  var _positionX: NEKeyframeGroup<NELottieVector1D>? { positionX }
  var _positionY: NEKeyframeGroup<NELottieVector1D>? { positionY }
  var _skew: NEKeyframeGroup<NELottieVector1D>? { nil }
  var _skewAxis: NEKeyframeGroup<NELottieVector1D>? { nil }
}

// MARK: - NEShapeTransform + NETransformModel

extension NEShapeTransform: NETransformModel {
  var anchorPoint: NEKeyframeGroup<NELottieVector3D> { anchor }
  var _position: NEKeyframeGroup<NELottieVector3D>? { position }
  var _positionX: NEKeyframeGroup<NELottieVector1D>? { nil }
  var _positionY: NEKeyframeGroup<NELottieVector1D>? { nil }
  var _skew: NEKeyframeGroup<NELottieVector1D>? { skew }
  var _skewAxis: NEKeyframeGroup<NELottieVector1D>? { skewAxis }
}

// MARK: - CALayer + NETransformModel

extension CALayer {
  // MARK: Internal

  /// Adds transform-related animations from the given `NETransformModel` to this layer
  ///  - This _doesn't_ apply `transform.opacity`, which has to be handled separately
  ///    since child layers don't inherit the `opacity` of their parent.
  @nonobjc
  func addTransformAnimations(for transformModel: NETransformModel,
                              context: NELayerAnimationContext)
    throws {
    if
      // CALayers don't support animating skew with its own set of keyframes.
      // If the transform includes a skew, we have to combine all of the transform
      // components into a single set of keyframes.
      transformModel.hasSkew
      // Negative `scale.x` values aren't applied correctly by Core Animation when animating
      // `transform.scale.x` and `transform.scale.y` using separate `CAKeyframeAnimation`s
      // (https://openradar.appspot.com/FB9862872). If the transform includes negative `scale.x`
      // values, we have to combine all of the transform components into a single set of keyframes.
      || transformModel.hasNegativeXScaleValues {
      try addCombinedTransformAnimation(for: transformModel, context: context)
    }

    else {
      try addPositionAnimations(from: transformModel, context: context)
      try addAnchorPointAnimation(from: transformModel, context: context)
      try addScaleAnimations(from: transformModel, context: context)
      try addRotationAnimations(from: transformModel, context: context)
    }
  }

  // MARK: Private

  @nonobjc
  private func addPositionAnimations(from transformModel: NETransformModel,
                                     context: NELayerAnimationContext)
    throws {
    if let positionKeyframes = transformModel._position {
      try neAddAnimation(
        for: .position,
        keyframes: positionKeyframes,
        value: \.pointValue,
        context: context
      )
    } else if
      let xKeyframes = transformModel._positionX,
      let yKeyframes = transformModel._positionY {
      try neAddAnimation(
        for: .positionX,
        keyframes: xKeyframes,
        value: \.cgFloatValue,
        context: context
      )

      try neAddAnimation(
        for: .positionY,
        keyframes: yKeyframes,
        value: \.cgFloatValue,
        context: context
      )
    } else {
      try context.logCompatibilityIssue("""
      `NETransform` values must provide either `position` or `positionX` / `positionY` keyframes
      """)
    }
  }

  @nonobjc
  private func addAnchorPointAnimation(from transformModel: NETransformModel,
                                       context: NELayerAnimationContext)
    throws {
    try neAddAnimation(
      for: .anchorPoint,
      keyframes: transformModel.anchorPoint,
      value: { absoluteAnchorPoint in
        guard bounds.width > 0, bounds.height > 0 else {
          context.logger.assertionFailure("Size must be non-zero before an animation can be played")
          return .zero
        }

        // Lottie animation files express anchorPoint as an absolute point value,
        // so we have to divide by the width/height of this layer to get the
        // relative decimal values expected by Core Animation.
        return CGPoint(
          x: CGFloat(absoluteAnchorPoint.x) / bounds.width,
          y: CGFloat(absoluteAnchorPoint.y) / bounds.height
        )
      },
      context: context
    )
  }

  @nonobjc
  private func addScaleAnimations(from transformModel: NETransformModel,
                                  context: NELayerAnimationContext)
    throws {
    try neAddAnimation(
      for: .scaleX,
      keyframes: transformModel.scale,
      value: { scale in
        // Lottie animation files express scale as a numerical percentage value
        // (e.g. 50%, 100%, 200%) so we divide by 100 to get the decimal values
        // expected by Core Animation (e.g. 0.5, 1.0, 2.0).
        CGFloat(scale.x) / 100
      },
      context: context
    )

    try neAddAnimation(
      for: .scaleY,
      keyframes: transformModel.scale,
      value: { scale in
        // Lottie animation files express scale as a numerical percentage value
        // (e.g. 50%, 100%, 200%) so we divide by 100 to get the decimal values
        // expected by Core Animation (e.g. 0.5, 1.0, 2.0).
        CGFloat(scale.y) / 100
      },
      context: context
    )
  }

  private func addRotationAnimations(from transformModel: NETransformModel,
                                     context: NELayerAnimationContext)
    throws {
    let containsXRotationValues = transformModel.rotationX.keyframes.contains(where: { $0.value.cgFloatValue != 0 })
    let containsYRotationValues = transformModel.rotationY.keyframes.contains(where: { $0.value.cgFloatValue != 0 })

    // When `rotation.x` or `rotation.y` is used, it doesn't render property in test snapshots
    // but do renders correctly on the simulator / device
    if NETestHelpers.snapshotTestsAreRunning {
      if containsXRotationValues {
        context.logger.warn("""
        `rotation.x` values are not displayed correctly in snapshot tests
        """)
      }

      if containsYRotationValues {
        context.logger.warn("""
        `rotation.y` values are not displayed correctly in snapshot tests
        """)
      }
    }

    // Lottie animation files express rotation in degrees
    // (e.g. 90º, 180º, 360º) so we convert to radians to get the
    // values expected by Core Animation (e.g. π/2, π, 2π)

    try neAddAnimation(
      for: .rotationX,
      keyframes: transformModel.rotationX,
      value: { rotationDegrees in
        rotationDegrees.cgFloatValue * .pi / 180
      },
      context: context
    )

    try neAddAnimation(
      for: .rotationY,
      keyframes: transformModel.rotationY,
      value: { rotationDegrees in
        rotationDegrees.cgFloatValue * .pi / 180
      },
      context: context
    )

    try neAddAnimation(
      for: .rotationZ,
      keyframes: transformModel.rotationZ,
      value: { rotationDegrees in
        // Lottie animation files express rotation in degrees
        // (e.g. 90º, 180º, 360º) so we convert to radians to get the
        // values expected by Core Animation (e.g. π/2, π, 2π)
        rotationDegrees.cgFloatValue * .pi / 180
      },
      context: context
    )
  }

  /// Adds an animation for the entire `transform` key by combining all of the
  /// position / size / rotation / skew animations into a single set of keyframes.
  /// This is more expensive that animating each component separately, since
  /// it may require manually interpolating the keyframes at each frame.
  private func addCombinedTransformAnimation(for transformModel: NETransformModel,
                                             context: NELayerAnimationContext)
    throws {
    let requiresManualInterpolation =
      // Core Animation doesn't animate skew changes properly. If the skew value
      // changes over the course of the animation then we have to manually
      // compute the `CATransform3D` for each frame individually.
      transformModel.hasSkewAnimation
      // `addAnimation` requires that we use an `NEInterpolatable` value, but we can't interpolate a `CATransform3D`.
      // Since this is only necessary when using `complexTimeRemapping`, we can avoid this by manually interpolating
      // when `context.mustUseComplexTimeRemapping` is true and just returning a `Hold` container.
      // Since our keyframes are already manually interpolated, they won't need to be interpolated again.
      || context.mustUseComplexTimeRemapping

    let combinedTransformKeyframes = NEKeyframes.combined(
      transformModel.anchorPoint,
      transformModel._position ?? NEKeyframeGroup(NELottieVector3D(x: 0.0, y: 0.0, z: 0.0)),
      transformModel._positionX ?? NEKeyframeGroup(NELottieVector1D(0)),
      transformModel._positionY ?? NEKeyframeGroup(NELottieVector1D(0)),
      transformModel.scale,
      transformModel.rotationX,
      transformModel.rotationY,
      transformModel.rotationZ,
      transformModel._skew ?? NEKeyframeGroup(NELottieVector1D(0)),
      transformModel._skewAxis ?? NEKeyframeGroup(NELottieVector1D(0)),
      requiresManualInterpolation: requiresManualInterpolation,
      makeCombinedResult: {
        anchor, position, positionX, positionY, scale, rotationX, rotationY, rotationZ, skew, skewAxis
          -> Hold<CATransform3D> in
        let transformPosition: CGPoint
        if transformModel._positionX != nil, transformModel._positionY != nil {
          transformPosition = CGPoint(x: positionX.cgFloatValue, y: positionY.cgFloatValue)
        } else {
          transformPosition = position.pointValue
        }

        let transform = CATransform3D.makeTransform(
          anchor: anchor.pointValue,
          position: transformPosition,
          scale: scale.sizeValue,
          rotationX: rotationX.cgFloatValue,
          rotationY: rotationY.cgFloatValue,
          rotationZ: rotationZ.cgFloatValue,
          skew: skew.cgFloatValue,
          skewAxis: skewAxis.cgFloatValue
        )

        return Hold(value: transform)
      }
    )

    try neAddAnimation(
      for: .transform,
      keyframes: combinedTransformKeyframes,
      value: { $0.value },
      context: context
    )
  }
}

extension NETransformModel {
  /// Whether or not this transform has a non-zero skew value
  var hasSkew: Bool {
    guard
      let _skew,
      let _skewAxis,
      !_skew.keyframes.isEmpty,
      !_skewAxis.keyframes.isEmpty
    else {
      return false
    }

    return _skew.keyframes.contains(where: { $0.value.cgFloatValue != 0 })
  }

  /// Whether or not this transform has a non-zero skew value which animates
  var hasSkewAnimation: Bool {
    guard
      hasSkew,
      let _skew,
      let _skewAxis
    else { return false }

    return _skew.keyframes.count > 1
      || _skewAxis.keyframes.count > 1
  }

  /// Whether or not this `NETransformModel` has any negative X scale values
  var hasNegativeXScaleValues: Bool {
    scale.keyframes.contains(where: { $0.value.x < 0 })
  }
}
