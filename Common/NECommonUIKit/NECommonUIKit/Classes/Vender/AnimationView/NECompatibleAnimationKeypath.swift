
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

#if os(iOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)

  /// An Objective-C compatible wrapper around Lottie's NEAnimationKeypath
  @objc
  public final class NECompatibleAnimationKeypath: NSObject {
    // MARK: Lifecycle

    /// Creates a keypath from a dot separated string. The string is separated by "."
    @objc
    public init(keypath: String) {
      animationKeypath = NEAnimationKeypath(keypath: keypath)
    }

    /// Creates a keypath from a list of strings.
    @objc
    public init(keys: [String]) {
      animationKeypath = NEAnimationKeypath(keys: keys)
    }

    // MARK: Public

    public let animationKeypath: NEAnimationKeypath
  }
#endif
