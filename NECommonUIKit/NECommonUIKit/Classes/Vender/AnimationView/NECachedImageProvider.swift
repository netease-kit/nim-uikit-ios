
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NECachedImageProvider

private final class NECachedImageProvider: NEAnimationImageProvider {
  // MARK: Lifecycle

  /// Initializes an image provider with an image provider
  ///
  /// - Parameter imageProvider: The provider to load image from asset
  ///
  init(imageProvider: NEAnimationImageProvider) {
    self.imageProvider = imageProvider
  }

  // MARK: Public

  func imageForAsset(asset: NEImageAsset) -> CGImage? {
    if let image = imageCache.value(forKey: asset.id) {
      return image
    }
    if let image = imageProvider.imageForAsset(asset: asset) {
      imageCache.setValue(image, forKey: asset.id)
      return image
    }
    return nil
  }

  // MARK: Internal

  func contentsGravity(for asset: NEImageAsset) -> CALayerContentsGravity {
    imageProvider.contentsGravity(for: asset)
  }

  // MARK: Private

  /// The underlying storage of this cache.
  ///  - We use the `NELRUCache` library instead of `NSCache`, because `NSCache`
  ///    clears all cached values when the app is backgrounded instead of
  ///    only when the app receives a memory warning notification.
  private var imageCache = NELRUCache<String, CGImage>()
  private let imageProvider: NEAnimationImageProvider
}

extension NEAnimationImageProvider {
  /// Create a cache enabled image provider which will reuse the asset image with the same asset id
  /// It wraps the current provider as image loader, and uses `NSCache` to cache the images for resue.
  /// The cache will be reset when the `animation` is reset.
  var cachedImageProvider: NEAnimationImageProvider {
    guard cacheEligible else { return self }
    return NECachedImageProvider(imageProvider: self)
  }
}
