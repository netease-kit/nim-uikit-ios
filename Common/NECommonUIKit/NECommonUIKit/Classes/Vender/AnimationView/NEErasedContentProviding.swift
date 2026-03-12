// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEErasedContentProviding

/// The capability of providing an type-erased `Equatable` content instance.
protocol NEErasedContentProviding {
  /// The type-erased content instance of this model, else `nil` if there is no content.
  ///
  /// If there was an `NEAnyEquatable` type, we could store this property using it. Instead we need
  /// need to store `isErasedContentEqual` to determine equality.
  var erasedContent: Any? { get }

  /// A closure that can be called to determine whether the given `model`'s `erasedContent` is equal
  /// to this model's `erasedContent`, else `nil` if there is no content or the content is always
  /// equal.
  var isErasedContentEqual: ((Self) -> Bool)? { get }
}

// MARK: - NEEpoxyModeled

extension NEEpoxyModeled where Self: NEErasedContentProviding {
  // MARK: Internal

  /// The type-erased content instance of this model, else `nil` if there is no content.
  var erasedContent: Any? {
    get { self[contentProperty] }
    set { self[contentProperty] = newValue }
  }

  /// A closure that can be called to determine whether the given `model`'s `erasedContent` is equal
  /// to this model's `erasedContent`, else `nil` if there is no content or the content is always
  /// equal.
  var isErasedContentEqual: ((Self) -> Bool)? {
    get { self[isContentEqualProperty] }
    set { self[isContentEqualProperty] = newValue }
  }

  // MARK: Private

  private var contentProperty: NEEpoxyModelProperty<Any?> {
    .init(keyPath: \Self.erasedContent, defaultValue: nil, updateStrategy: .replace)
  }

  private var isContentEqualProperty: NEEpoxyModelProperty<((Self) -> Bool)?> {
    .init(keyPath: \Self.isErasedContentEqual, defaultValue: nil, updateStrategy: .replace)
  }
}
