
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NEAnimationImageProvider

/// Image provider is a protocol that is used to supply images to `NELottieAnimationView`.
///
/// Some animations require a reference to an image. The image provider loads and
/// provides those images to the `NELottieAnimationView`.  Lottie includes a couple of
/// prebuilt Image Providers that supply images from a Bundle, or from a FilePath.
///
/// Additionally custom Image Providers can be made to load images from a URL,
/// or to Cache images.
public protocol NEAnimationImageProvider {
  /// Whether or not the resulting image of this image provider can be cached by Lottie. Defaults to true.
  /// If true, Lottie may internally cache the result of `imageForAsset`
  var cacheEligible: Bool { get }

  /// The image to display for the given `NEImageAsset` defined in the `NELottieAnimation` JSON file.
  func imageForAsset(asset: NEImageAsset) -> CGImage?

  /// Specifies how the layer's contents are positioned or scaled within its bounds for a given asset.
  /// Defaults to `.resize`, which stretches the image to fill the layer.
  func contentsGravity(for asset: NEImageAsset) -> CALayerContentsGravity
}

public extension NEAnimationImageProvider {
  var cacheEligible: Bool {
    true
  }

  /// The default value is `.resize`, similar to that of `CALayer`.
  func contentsGravity(for _: NEImageAsset) -> CALayerContentsGravity {
    .resize
  }
}
