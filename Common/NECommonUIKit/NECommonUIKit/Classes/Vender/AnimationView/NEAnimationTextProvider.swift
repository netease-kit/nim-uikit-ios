
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEAnimationKeypathTextProvider

/// Protocol for providing dynamic text to for a Lottie animation.
public protocol NEAnimationKeypathTextProvider: AnyObject {
  /// The text to display for the given `NEAnimationKeypath`.
  /// If `nil` is returned, continues using the existing default text value.
  func text(for keypath: NEAnimationKeypath, sourceText: String) -> String?
}

// MARK: - NEAnimationKeypathTextProvider

/// Legacy protocol for providing dynamic text for a Lottie animation.
/// Instead prefer conforming to `NEAnimationKeypathTextProvider`.
@available(*, deprecated, message: """
`NEAnimationKeypathTextProvider` has been deprecated and renamed to `NELegacyAnimationTextProvider`. \
Instead, conform to `NEAnimationKeypathTextProvider` instead or conform to `NELegacyAnimationTextProvider` explicitly.
""")
public typealias NEAnimationTextProvider = NELegacyAnimationTextProvider

// MARK: - NELegacyAnimationTextProvider

/// Legacy protocol for providing dynamic text for a Lottie animation.
/// Instead prefer conforming to `NEAnimationKeypathTextProvider`.
public protocol NELegacyAnimationTextProvider: NEAnimationKeypathTextProvider {
  /// Legacy method to look up the text to display for the given keypath.
  /// Instead, prefer implementing `NEAnimationKeypathTextProvider.`
  /// The behavior of this method depends on the current rendering engine:
  ///  - The Core Animation rendering engine always calls this method
  ///    with the full keypath (e.g. `MY_LAYER.text_value`).
  ///  - The Main Thread rendering engine always calls this method
  ///    with the final component of the key path (e.g. just `text_value`).
  func textFor(keypathName: String, sourceText: String) -> String
}

public extension NELegacyAnimationTextProvider {
  func text(for _: NEAnimationKeypath, sourceText _: String) -> String? {
    nil
  }
}

// MARK: - NEDictionaryTextProvider

/// Text provider that simply map values from dictionary.
///  - The dictionary keys can either be the full layer keypath string (e.g. `MY_LAYER.text_value`)
///    or simply the final path component of the keypath (e.g. `text_value`).
public final class NEDictionaryTextProvider: NEAnimationKeypathTextProvider, NELegacyAnimationTextProvider {
  // MARK: Lifecycle

  public init(_ values: [String: String]) {
    self.values = values
  }

  // MARK: Public

  public func text(for keypath: NEAnimationKeypath, sourceText: String) -> String? {
    if let valueForFullKeypath = values[keypath.fullPath] {
      return valueForFullKeypath
    }

    else if
      let lastKeypathComponent = keypath.keys.last,
      let valueForLastComponent = values[lastKeypathComponent] {
      return valueForLastComponent
    }

    else {
      return sourceText
    }
  }

  // Never called directly by Lottie, but we continue to implement this conformance for backwards compatibility.
  public func textFor(keypathName: String, sourceText: String) -> String {
    values[keypathName] ?? sourceText
  }

  // MARK: Internal

  let values: [String: String]
}

// MARK: Equatable

extension NEDictionaryTextProvider: Equatable {
  public static func == (_ lhs: NEDictionaryTextProvider, _ rhs: NEDictionaryTextProvider) -> Bool {
    lhs.values == rhs.values
  }
}

// MARK: - NEDefaultTextProvider

/// Default text provider. Uses text in the animation file
public final class NEDefaultTextProvider: NEAnimationKeypathTextProvider, NELegacyAnimationTextProvider {
  // MARK: Lifecycle

  public init() {}

  // MARK: Public

  public func textFor(keypathName _: String, sourceText: String) -> String {
    sourceText
  }

  public func text(for _: NEAnimationKeypath, sourceText: String) -> String {
    sourceText
  }
}

// MARK: Equatable

extension NEDefaultTextProvider: Equatable {
  public static func == (_: NEDefaultTextProvider, _: NEDefaultTextProvider) -> Bool {
    true
  }
}
