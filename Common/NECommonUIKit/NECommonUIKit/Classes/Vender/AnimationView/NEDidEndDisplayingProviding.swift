
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEDidEndDisplayingProviding

/// A sentinel protocol for enabling an `NECallbackContextEpoxyModeled` to provide a
/// `didEndDisplaying` closure property.
protocol NEDidEndDisplayingProviding {}

// MARK: - NECallbackContextEpoxyModeled

extension NECallbackContextEpoxyModeled where Self: NEDidEndDisplayingProviding {
  // MARK: Internal

  /// A closure that's called when a view is no longer displayed following any disappearance
  /// animations and when it has been removed from the view hierarchy.
  typealias DidEndDisplaying = (_ context: CallbackContext) -> Void

  /// A closure that's called when the view is no longer displayed following any disappearance
  /// animations and when it has been removed from the view hierarchy.
  var didEndDisplaying: DidEndDisplaying? {
    get { self[didEndDisplayingProperty] }
    set { self[didEndDisplayingProperty] = newValue }
  }

  /// Returns a copy of this model with the given did end displaying closure called after the
  /// current did end displaying closure of this model, if there is one.
  func didEndDisplaying(_ value: DidEndDisplaying?) -> Self {
    copy(updating: didEndDisplayingProperty, to: value)
  }

  // MARK: Private

  private var didEndDisplayingProperty: NEEpoxyModelProperty<DidEndDisplaying?> {
    .init(
      keyPath: \Self.didEndDisplaying,
      defaultValue: nil,
      updateStrategy: .chain()
    )
  }
}
