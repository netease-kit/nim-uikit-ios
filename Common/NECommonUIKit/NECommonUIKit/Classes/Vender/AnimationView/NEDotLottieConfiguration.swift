
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEDotLottieConfiguration

/// The `NEDotLottieConfiguration` model holds the presets extracted from NEDotLottieAnimation
///  - The presets are used as input to setup `NELottieAnimationView` before playing the animation.
public struct NEDotLottieConfiguration {
  // MARK: Public

  /// id of the animation
  public var id: String

  /// Loop behavior of animation
  public var loopMode: NELottieLoopMode

  /// Playback speed of animation
  public var speed: Double

  /// Animation Image NEProvider
  public var imageProvider: NEAnimationImageProvider? {
    dotLottieImageProvider
  }

  // MARK: Internal

  /// The underlying `NEDotLottieImageProvider` used by this dotLottie animation
  var dotLottieImageProvider: NEDotLottieImageProvider?
}

// MARK: - NEDotLottieConfigurationComponents

/// Components of the `NEDotLottieConfiguration` to apply to the `NELottieAnimationView`.
///  - When using `NELottieView`, if the component is selected to be applied it will
///    override any value provided via other `NELottieView` APIs.
public struct NEDotLottieConfigurationComponents: OptionSet {
  // MARK: Lifecycle

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  // MARK: Public

  /// `NEDotLottieConfiguration.imageProvider` will be applied to the `NELottieAnimationView`
  ///  - When using `NELottieView`, the image provider from the dotLottie animation will override
  ///    the image provider applied manually using `NELottieView.imageProvider(...)`.
  public static let imageProvider = NEDotLottieConfigurationComponents(rawValue: 1 << 0)

  /// `NEDotLottieConfigurationMode.loopMode` will be applied to the `LottieAnimationView`.
  ///  - When using `LottieView`, the loop mode from the dotLottie animation will override
  ///    the loopMode applied by any playback method.
  public static let loopMode = NEDotLottieConfigurationComponents(rawValue: 1 << 1)

  /// `NEDotLottieConfigurationMode.speed` will be applied to the `NELottieAnimationView`.
  ///  - When using `LottieView`, the speed from the dotLottie animation will override
  ///    the speed applied manually using `NELottieView.animationSpeed(...)`.
  public static let animationSpeed = NEDotLottieConfigurationComponents(rawValue: 1 << 2)

  public static let all: NEDotLottieConfigurationComponents = [.imageProvider, .loopMode, .animationSpeed]

  public static let none: NEDotLottieConfigurationComponents = []

  public let rawValue: Int
}
