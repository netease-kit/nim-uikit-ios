// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NESetContentProviding

/// A sentinel protocol for enabling an `NECallbackContextEpoxyModeled` to provide a `setContent`
/// closure property.
protocol NESetContentProviding {}

// MARK: - NECallbackContextEpoxyModeled

extension NECallbackContextEpoxyModeled where Self: NESetContentProviding {
  // MARK: Internal

  /// A closure that's called to set the content on this model's view when it is first created and
  /// subsequently when the content changes.
  typealias SetContent = (CallbackContext) -> Void

  /// A closure that's called to set the content on this model's view when it is first created and
  /// subsequently when the content changes.
  var setContent: SetContent? {
    get { self[setContentProperty] }
    set { self[setContentProperty] = newValue }
  }

  /// Returns a copy of this model with the given setContent view closure called after the current
  /// setContent view closure of this model, if there is one.
  func setContent(_ value: SetContent?) -> Self {
    copy(updating: setContentProperty, to: value)
  }

  // MARK: Private

  private var setContentProperty: NEEpoxyModelProperty<SetContent?> {
    .init(keyPath: \Self.setContent, defaultValue: nil, updateStrategy: .chain())
  }
}
