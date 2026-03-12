// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEWillDisplayProviding

/// A sentinel protocol for enabling an `NECallbackContextEpoxyModeled` to provide a `willDisplay`
/// closure property.
///
/// - SeeAlso: `NEDidDisplayProviding`
/// - SeeAlso: `NEDidEndDisplayingProviding`
protocol NEWillDisplayProviding {}

// MARK: - NECallbackContextEpoxyModeled

extension NECallbackContextEpoxyModeled where Self: NEWillDisplayProviding {
  // MARK: Internal

  /// A closure that's called when a view is about to be displayed, before it has been added to the
  /// view hierarcy.
  typealias WillDisplay = (_ context: CallbackContext) -> Void

  /// A closure that's called when the view is about to be displayed, before it has been added to
  /// the view hierarcy.
  var willDisplay: WillDisplay? {
    get { self[willDisplayProperty] }
    set { self[willDisplayProperty] = newValue }
  }

  /// Returns a copy of this model with the given will display closure called after the current will
  /// display closure of this model, if there is one.
  func willDisplay(_ value: WillDisplay?) -> Self {
    copy(updating: willDisplayProperty, to: value)
  }

  // MARK: Private

  private var willDisplayProperty: NEEpoxyModelProperty<WillDisplay?> {
    .init(keyPath: \Self.willDisplay, defaultValue: nil, updateStrategy: .chain())
  }
}
