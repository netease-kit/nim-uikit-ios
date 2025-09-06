
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// `NEDotLottieCacheProvider` is a protocol that describes a DotLottie Cache.
/// DotLottie Cache is used when loading `DotLottie` model. Using a DotLottie Cache
/// can increase performance when loading an animation multiple times.
///
/// Lottie comes with a prebuilt LRU DotLottie Cache.
public protocol NEDotLottieCacheProvider: Sendable {
  func file(forKey: String) -> NEDotLottieFile?

  func setFile(_ lottie: NEDotLottieFile, forKey: String)

  func clearCache()
}
