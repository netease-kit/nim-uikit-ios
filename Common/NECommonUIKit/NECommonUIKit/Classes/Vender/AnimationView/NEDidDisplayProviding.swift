
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEDidDisplayProviding

/// A sentinel protocol for enabling an `NECallbackContextEpoxyModeled` to provide a `didDisplay`
/// closure property.
///
/// - SeeAlso: `NEWillDisplayProviding`
/// - SeeAlso: `NEDidEndDisplayingProviding`
protocol NEDidDisplayProviding {}

// MARK: - NECallbackContextEpoxyModeled

extension NECallbackContextEpoxyModeled where Self: NEDidDisplayProviding {
  // MARK: Internal

  /// A closure that's called after a view has been added to the view hierarchy following any
  /// appearance animations.
  typealias DidDisplay = (_ context: CallbackContext) -> Void

  /// A closure that's called after the view has been added to the view hierarchy following any
  /// appearance animations.
  var didDisplay: DidDisplay? {
    get { self[didDisplayProperty] }
    set { self[didDisplayProperty] = newValue }
  }

  /// Returns a copy of this model with the given did display closure called after the current did
  /// display closure of this model, if there is one.
  func didDisplay(_ value: DidDisplay?) -> Self {
    copy(updating: didDisplayProperty, to: value)
  }

  // MARK: Private

  private var didDisplayProperty: NEEpoxyModelProperty<DidDisplay?> {
    .init(keyPath: \Self.didDisplay, defaultValue: nil, updateStrategy: .chain())
  }
}
