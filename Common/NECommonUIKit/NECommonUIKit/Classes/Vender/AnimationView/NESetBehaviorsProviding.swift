// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NESetBehaviorsProviding

/// A sentinel protocol for enabling an `NECallbackContextEpoxyModeled` to provide a `setBehaviors`
/// closure property.
protocol NESetBehaviorsProviding {}

// MARK: - NECallbackContextEpoxyModeled

extension NECallbackContextEpoxyModeled where Self: NESetBehaviorsProviding {
  // MARK: Internal

  /// A closure that's called to set the content on this model's view with behaviors (e.g. tap handler
  /// closures) whenever this model is updated.
  typealias SetBehaviors = (CallbackContext) -> Void

  /// A closure that's called to set the content on this model's view with behaviors (e.g. tap handler
  /// closures) whenever this model is updated.
  var setBehaviors: SetBehaviors? {
    get { self[setBehaviorsProperty] }
    set { self[setBehaviorsProperty] = newValue }
  }

  /// Returns a copy of this model with the set behaviors closure called after the current set
  /// behaviors closure of this model, if there is one.
  func setBehaviors(_ value: SetBehaviors?) -> Self {
    copy(updating: setBehaviorsProperty, to: value)
  }

  // MARK: Private

  private var setBehaviorsProperty: NEEpoxyModelProperty<SetBehaviors?> {
    .init(keyPath: \Self.setBehaviors, defaultValue: nil, updateStrategy: .chain())
  }
}
