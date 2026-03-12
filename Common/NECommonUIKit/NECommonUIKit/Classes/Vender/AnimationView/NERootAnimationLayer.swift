// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NERootAnimationLayer

/// A root `CALayer` responsible for playing a Lottie animation
protocol NERootAnimationLayer: CALayer {
  var lottieAnimationLayer: NELottieAnimationLayer? { get set }

  var currentFrame: NEAnimationFrameTime { get set }
  var renderScale: CGFloat { get set }
  var respectAnimationFrameRate: Bool { get set }

  var _animationLayers: [CALayer] { get }
  var imageProvider: NEAnimationImageProvider { get set }
  var textProvider: NEAnimationKeypathTextProvider { get set }
  var fontProvider: NEAnimationFontProvider { get set }

  /// The `CAAnimation` key corresponding to the primary animation.
  ///  - `NELottieAnimationView` uses this key to check if the animation is still active
  var primaryAnimationKey: NEAnimationKey { get }

  /// Whether or not this layer is currently playing an animation
  ///  - If the layer returns `nil`, `NELottieAnimationView` determines if an animation
  ///    is playing by checking if there is an active animation for `primaryAnimationKey`
  var isAnimationPlaying: Bool? { get }

  /// Instructs this layer to remove all `CAAnimation`s,
  /// other than the `CAAnimation` managed by `NELottieAnimationView` (if applicable)
  func removeAnimations()

  func reloadImages()
  func forceDisplayUpdate()
  func logHierarchyKeypaths()
  func allHierarchyKeypaths() -> [String]
  func setValueProvider(_ valueProvider: NEAnyValueProvider, keypath: NEAnimationKeypath)
  func getValue(for keypath: NEAnimationKeypath, atFrame: NEAnimationFrameTime?) -> Any?
  func getOriginalValue(for keypath: NEAnimationKeypath, atFrame: NEAnimationFrameTime?) -> Any?

  func layer(for keypath: NEAnimationKeypath) -> CALayer?
  func animatorNodes(for keypath: NEAnimationKeypath) -> [NEAnimatorNode]?
}

// MARK: - NEAnimationKey

enum NEAnimationKey {
  /// The primary animation and its key should be managed by `NELottieAnimationView`
  case managed
  /// The primary animation always uses the given key
  case specific(String)
}
