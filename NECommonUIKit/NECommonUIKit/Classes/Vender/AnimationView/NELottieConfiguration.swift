// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

/// Global configuration options for Lottie animations
public struct NELottieConfiguration: Hashable {
  // MARK: Lifecycle

  public init(renderingEngine: NERenderingEngineOption = .automatic,
              decodingStrategy: NEDecodingStrategy = .dictionaryBased,
              colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB(),
              reducedMotionOption: NEReducedMotionOption = .systemReducedMotionToggle) {
    self.renderingEngine = renderingEngine
    self.decodingStrategy = decodingStrategy
    self.colorSpace = colorSpace
    self.reducedMotionOption = reducedMotionOption
  }

  // MARK: Public

  /// The global configuration of Lottie,
  /// which applies to all `NELottieAnimationView`s by default.
  public static var shared = NELottieConfiguration()

  /// The rendering engine implementation to use when displaying an animation
  ///  - Defaults to `NERenderingEngineOption.automatic`, which uses the
  ///    Core Animation rendering engine for supported animations, and
  ///    falls back to using the Main Thread rendering engine for
  ///    animations that use features not supported by the Core Animation engine.
  public var renderingEngine: NERenderingEngineOption

  /// The decoding implementation to use when parsing an animation JSON file
  public var decodingStrategy: NEDecodingStrategy

  /// Options for controlling animation behavior in response to user / system "reduced motion" configuration.
  ///  - Defaults to `NEReducedMotionOption.systemReducedMotionToggle`, which returns `.reducedMotion`
  ///    when the system `UIAccessibility.isReduceMotionEnabled` option is `true`.
  public var reducedMotionOption: NEReducedMotionOption

  /// The color space to be used for rendering
  ///  - Defaults to `CGColorSpaceCreateDeviceRGB()`
  public var colorSpace: CGColorSpace
}
