
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEContentConfigurableView

/// A view that can be configured with a `Content` instance that contains the view's `Equatable`
/// properties that can be updated on existing view instances, e.g. text `String`s or image `URL`s.
///
/// For performance, it is generally expected that `Content` is only set when it is not equal to the
/// previous `Content` instance that has been set on a view instance. As a further optimization,
/// this view can guard updates on the equality of each property of the `Content` against the
/// current property value when set.
///
/// Properties of `Content` should be mutually exclusive with the properties of the
/// `NEStyledView.Style` and `NEBehaviorsConfigurableView.Behaviors`.
///
/// - SeeAlso: `NEBehaviorsConfigurableView`
/// - SeeAlso: `NEStyledView`
/// - SeeAlso: `NEEpoxyableView`
protocol NEContentConfigurableView: NEViewType {
  /// The `Equatable` properties that can be updated on instances of this view, e.g. text `String`s
  /// or image `URL`s.
  ///
  /// Defaults to `Never` for views that do not have `Content`.
  associatedtype Content: Equatable = Never

  /// Updates the content of this view to the properties of the given `content`, optionally
  /// animating the updates.
  func setContent(_ content: Self.Content, animated: Bool)
}

// MARK: Defaults

extension NEContentConfigurableView where Content == Never {
  func setContent(_: Never, animated _: Bool) {}
}
