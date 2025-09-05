// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NEOpacityAnimationModel

protocol NEOpacityAnimationModel {
  /// The opacity animation to apply to a `CALayer`
  var opacity: NEKeyframeGroup<NELottieVector1D> { get }
}

// MARK: - NETransform + NEOpacityAnimationModel

extension NETransform: NEOpacityAnimationModel {}

// MARK: - NEShapeTransform + NEOpacityAnimationModel

extension NEShapeTransform: NEOpacityAnimationModel {}

// MARK: - NEFill + NEOpacityAnimationModel

extension NEFill: NEOpacityAnimationModel {}

// MARK: - NEGradientFill + NEOpacityAnimationModel

extension NEGradientFill: NEOpacityAnimationModel {}

// MARK: - NEStroke + NEOpacityAnimationModel

extension NEStroke: NEOpacityAnimationModel {}

// MARK: - NEGradientStroke + NEOpacityAnimationModel

extension NEGradientStroke: NEOpacityAnimationModel {}

extension CALayer {
  /// Adds the opacity animation from the given `NEOpacityAnimationModel` to this layer
  @nonobjc
  func addOpacityAnimation(for opacity: NEOpacityAnimationModel, context: NELayerAnimationContext) throws {
    try neAddAnimation(
      for: .opacity,
      keyframes: opacity.opacity,
      value: {
        // Lottie animation files express opacity as a numerical percentage value
        // (e.g. 0%, 50%, 100%) so we divide by 100 to get the decimal values
        // expected by Core Animation (e.g. 0.0, 0.5, 1.0).
        $0.cgFloatValue / 100
      },
      context: context
    )
  }
}
