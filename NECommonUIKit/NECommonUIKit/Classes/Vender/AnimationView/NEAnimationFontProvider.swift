
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreText

// MARK: - NEAnimationFontProvider

/// NEFont provider is a protocol that is used to supply fonts to `NELottieAnimationView`.
///
public protocol NEAnimationFontProvider {
  func fontFor(family: String, size: CGFloat) -> CTFont?
}

// MARK: - NEDefaultFontProvider

/// Default NEFont provider.
public final class NEDefaultFontProvider: NEAnimationFontProvider {
  // MARK: Lifecycle

  public init() {}

  // MARK: Public

  public func fontFor(family: String, size: CGFloat) -> CTFont? {
    CTFontCreateWithName(family as CFString, size, nil)
  }
}

// MARK: Equatable

extension NEDefaultFontProvider: Equatable {
  public static func == (_: NEDefaultFontProvider, _: NEDefaultFontProvider) -> Bool {
    true
  }
}
