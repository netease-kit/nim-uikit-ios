
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEBehaviorsConfigurableView

/// A view that can be configured with a `Behaviors` instance that contains the view's non-
/// `Equatable` properties that can be updated on view instances after initialization, e.g. callback
/// closures or delegates.
///
/// Since it is not possible to establish the equality of two `Behaviors` instances, `Behaviors`
/// will be set more often than `NEContentConfigurableView.Content`, needing to be updated every time
/// the view's corresponding `NEEpoxyModeled` instance is updated. As such, setting behaviors should
/// be as lightweight as possible.
///
/// Properties of `Behaviors` should be mutually exclusive with the properties in the
/// `NEStyledView.Style` and `NEContentConfigurableView.Content`.
///
/// - SeeAlso: `NEContentConfigurableView`
/// - SeeAlso: `NEStyledView`
/// - SeeAlso: `NEEpoxyableView`
protocol NEBehaviorsConfigurableView: NEViewType {
  /// The non-`Equatable` properties that can be changed over of the lifecycle this View's
  /// instances, e.g. callback closures or delegates.
  ///
  /// Defaults to `Never` for views that do not have `Behaviors`.
  associatedtype Behaviors = Never

  /// Updates the behaviors of this view to those in the given `behaviors`, else resets the
  /// behaviors if `nil`.
  ///
  /// Behaviors are optional as they must be "resettable" in order for Epoxy to reset the behaviors
  /// on your view when no behaviors are provided.
  func setBehaviors(_ behaviors: Self.Behaviors?)
}

// MARK: Defaults

extension NEBehaviorsConfigurableView where Behaviors == Never {
  func setBehaviors(_ behaviors: Never?) {
    switch behaviors {
    case nil:
      break
    }
  }
}
