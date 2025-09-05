
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// `NEAnimationCacheProvider` is a protocol that describes an Animation Cache.
/// DotLottie Cache is used when loading `DotLottie` models. Using a DotLottie Cache
/// can increase performance when loading an animation multiple times.
///
/// Lottie comes with a prebuilt LRU Animation Cache.
public protocol NEAnimationCacheProvider: AnyObject, Sendable {
  func animation(forKey: String) -> NELottieAnimation?

  func setAnimation(_ animation: NELottieAnimation, forKey: String)

  func clearCache()
}
