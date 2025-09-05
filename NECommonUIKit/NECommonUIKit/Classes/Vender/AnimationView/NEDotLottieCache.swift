
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

// MARK: - NEDotLottieCache

/// A DotLottie Cache that will store lottie files up to `cacheSize`.
///
/// Once `cacheSize` is reached, the least recently used lottie will be ejected.
/// The default size of the cache is 100.
public class NEDotLottieCache: NEDotLottieCacheProvider {
  // MARK: Lifecycle

  public init() {
    cache.countLimit = Self.defaultCacheCountLimit
  }

  // MARK: Public

  /// The global shared Cache.
  public static let sharedCache = NEDotLottieCache()

  /// The size of the cache.
  public var cacheSize = defaultCacheCountLimit {
    didSet {
      cache.countLimit = cacheSize
    }
  }

  /// Clears the Cache.
  public func clearCache() {
    cache.removeAllValues()
  }

  public func file(forKey key: String) -> NEDotLottieFile? {
    cache.value(forKey: key)
  }

  public func setFile(_ lottie: NEDotLottieFile, forKey key: String) {
    cache.setValue(lottie, forKey: key)
  }

  // MARK: Private

  private static let defaultCacheCountLimit = 100

  /// The underlying storage of this cache.
  ///  - We use the `NELRUCache` library instead of `NSCache`, because `NSCache`
  ///    clears all cached values when the app is backgrounded instead of
  ///    only when the app receives a memory warning notification.
  private var cache = NELRUCache<String, NEDotLottieFile>()
}

// MARK: Sendable

// NEDotLottieCacheProvider has a Sendable requirement, but we can't
// redesign NEDotLottieCache to be properly Sendable without making breaking changes.
// swiftlint:disable:next no_unchecked_sendable
extension NEDotLottieCache: @unchecked Sendable {}
