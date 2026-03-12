// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

// MARK: - NEReducedMotionOption

/// Options for controlling animation behavior in response to user / system "reduced motion" configuration
public enum NEReducedMotionOption {
  /// Always use the specific given `NEReducedMotionMode` value.
  case specific(NEReducedMotionMode)

  /// Dynamically check the given `NEReducedMotionOptionProvider` each time an animation begins.
  ///  - Includes a Hashable `dataID` to support `NEReducedMotionOption`'s `Hashable` requirement,
  ///    which is required due to `NELottieConfiguration`'s existing `Hashable` requirement.
  case dynamic(NEReducedMotionOptionProvider, dataID: AnyHashable)
}

public extension NEReducedMotionOption {
  /// The standard behavior where Lottie animations play normally with no overrides.
  /// By default this mode is used when the system "reduced motion" option is disabled.
  static var standardMotion: NEReducedMotionOption { .specific(.standardMotion) }

  /// Lottie animations with a "reduced motion" marker will play that marker instead of any other animations.
  /// By default this mode is used when the system "reduced motion" option is enabled.
  ///  - Valid marker names include "reduced motion", "reducedMotion", "reduced_motion" (case insensitive).
  static var reducedMotion: NEReducedMotionOption { .specific(.reducedMotion) }

  /// A `NEReducedMotionOptionProvider` that returns `.reducedMotion` when
  /// the system `UIAccessibility.isReduceMotionEnabled` option is `true`.
  /// This is the default option of `NELottieConfiguration`.
  static var systemReducedMotionToggle: NEReducedMotionOption {
    .dynamic(NESystemReducedMotionOptionProvider(), dataID: ObjectIdentifier(NESystemReducedMotionOptionProvider.self))
  }
}

public extension NEReducedMotionOption {
  /// The current `NEReducedMotionMode` based on the currently selected option.
  var currentReducedMotionMode: NEReducedMotionMode {
    switch self {
    case let .specific(specificMode):
      return specificMode
    case let .dynamic(optionProvider, _):
      return optionProvider.currentReducedMotionMode
    }
  }
}

// MARK: Hashable

extension NEReducedMotionOption: Hashable {
  public static func == (_ lhs: NEReducedMotionOption, _ rhs: NEReducedMotionOption) -> Bool {
    switch (lhs, rhs) {
    case let (.specific(lhsMode), .specific(rhsMode)):
      return lhsMode == rhsMode
    case let (.dynamic(_, lhsDataID), .dynamic(_, dataID: rhsDataID)):
      return lhsDataID == rhsDataID
    case (.dynamic, .specific), (.specific, .dynamic):
      return false
    }
  }

  public func hash(into hasher: inout Hasher) {
    switch self {
    case let .specific(mode):
      hasher.combine(mode)
    case let .dynamic(_, dataID):
      hasher.combine(dataID)
    }
  }
}

// MARK: - NEReducedMotionMode

public enum NEReducedMotionMode: Hashable {
  /// The default behavior where Lottie animations play normally with no overrides
  /// By default this mode is used when the system "reduced motion" option is disabled.
  case standardMotion

  /// Lottie animations with a "reduced motion" marker will play that marker instead of any other animations.
  /// By default this mode is used when the system "reduced motion" option is enabled.
  case reducedMotion
}

// MARK: - NEReducedMotionOptionProvider

/// A type that returns a dynamic `NEReducedMotionMode` which is checked when playing a Lottie animation.
public protocol NEReducedMotionOptionProvider {
  var currentReducedMotionMode: NEReducedMotionMode { get }
}

// MARK: - NESystemReducedMotionOptionProvider

/// A `NEReducedMotionOptionProvider` that returns `.reducedMotion` when
/// the system `UIAccessibility.isReduceMotionEnabled` option is `true`.
public struct NESystemReducedMotionOptionProvider: NEReducedMotionOptionProvider {
  public init() {}

  public var currentReducedMotionMode: NEReducedMotionMode {
    #if canImport(UIKit)
      if UIAccessibility.isReduceMotionEnabled {
        return .reducedMotion
      } else {
        return .standardMotion
      }
    #else
      return .standardMotion
    #endif
  }
}
