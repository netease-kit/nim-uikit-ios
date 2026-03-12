// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEStyledView

/// A view that can be initialized with a `Style` instance that contains the view's invariant
/// configuration parameters, e.g. the `UIButton.ButtonType` of a `UIButton`.
///
/// A `Style` is expected to be invariant over the lifecycle of the view; it should not possible to
/// change the `Style` of a view after it is created. All variant properties of the view should
/// either be included in the `NEContentConfigurableView.Content` if they are `Equatable` (e.g. a
/// title `String`) or the `NEBehaviorsConfigurableView.Behaviors` if they are not (e.g. a callback
/// closure).
///
/// A `Style` is `Hashable` to allow views of the same type with equal `Style`s to be reused by
/// establishing whether their invariant `Style` instances are equal.
///
/// Properties of `Style` should be mutually exclusive with the properties of the
/// `NEContentConfigurableView.Content` and `NEBehaviorsConfigurableView.Behaviors`.
///
/// - SeeAlso: `NEContentConfigurableView`
/// - SeeAlso: `NEBehaviorsConfigurableView`
/// - SeeAlso: `NEEpoxyableView`
protocol NEStyledView: NEViewType {
  /// The style type of this view, passed into its initializer to configure the resulting instance.
  ///
  /// Defaults to `Never` for views that do not have a `Style`.
  associatedtype Style: Hashable = Never

  /// Creates an instance of this view configured with the given `Style` instance.
  init(style: Style)
}

// MARK: Defaults

extension NEStyledView where Style == Never {
  init(style: Never) {
    // An empty switch is required to silence the "'self.init' isn't called on all paths before
    // returning from initializer" error.
    switch style {}
  }
}
