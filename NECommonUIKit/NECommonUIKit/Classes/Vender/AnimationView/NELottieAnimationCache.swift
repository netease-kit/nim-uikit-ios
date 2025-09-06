// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// A customization point to configure which `AnimationCacheProvider` will be used.
public enum NELottieAnimationCache {
  /// The animation cache that will be used when loading `NELottieAnimation` models.
  /// Using an Animation Cache can increase performance when loading an animation multiple times.
  /// Defaults to NEDefaultAnimationCache.sharedCache.
  public static var shared: NEAnimationCacheProvider? = NEDefaultAnimationCache.sharedCache
}
