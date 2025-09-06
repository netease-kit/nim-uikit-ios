
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEDidSelectProviding

/// A sentinel protocol for enabling an `NECallbackContextEpoxyModeled` to provide a `didSelect`
/// closure property.
protocol NEDidSelectProviding {}

// MARK: - NECallbackContextEpoxyModeled

extension NECallbackContextEpoxyModeled where Self: NEDidSelectProviding {
  // MARK: Internal

  /// A closure that's called to handle this model's view being selected.
  typealias DidSelect = (CallbackContext) -> Void

  /// A closure that's called to handle this model's view being selected.
  var didSelect: DidSelect? {
    get { self[didSelectProperty] }
    set { self[didSelectProperty] = newValue }
  }

  /// Returns a copy of this model with the given did select closure called after the current did
  /// select closure of this model, if there is one.
  func didSelect(_ value: DidSelect?) -> Self {
    copy(updating: didSelectProperty, to: value)
  }

  // MARK: Private

  private var didSelectProperty: NEEpoxyModelProperty<DidSelect?> {
    .init(keyPath: \Self.didSelect, defaultValue: nil, updateStrategy: .chain())
  }
}
