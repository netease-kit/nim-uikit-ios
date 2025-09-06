// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEEpoxyModeled

/// A protocol that all concrete Epoxy declarative UI model types conform to.
///
/// This protocol should be conditionally extended to fulfill provider protocols and with chainable
/// setters for those providers that concrete model types can receive by declaring conformance to
/// provider protocols.
protocol NEEpoxyModeled {
  /// The underlying storage of this model that stores the current property values.
  var storage: NEEpoxyModelStorage { get set }
}

// MARK: Extensions

extension NEEpoxyModeled {
  /// Stores or retrieves a value of the specified property in `storage`.
  ///
  /// If the value was set previously for the given `property`, the conflict is resolved using the
  /// `NEEpoxyModelProperty.UpdateStrategy` of the `property`.
  subscript<Property>(property: NEEpoxyModelProperty<Property>) -> Property {
    get { storage[property] }
    set { storage[property] = newValue }
  }

  /// Returns a copy of this model with the given property updated to the provided value.
  ///
  /// Typically called from within the context of a chainable setter to allow fluent setting of a
  /// property, e.g.:
  ///
  /// ````
  /// internal func title(_ value: String?) -> Self {
  ///   copy(updating: titleProperty, to: value)
  /// }
  /// ````
  ///
  /// If a `value` was set previously for the given `property`, the conflict is resolved using the
  /// `NEEpoxyModelProperty.UpdateStrategy` of the `property`.
  func copy<Value>(updating property: NEEpoxyModelProperty<Value>, to value: Value) -> Self {
    var copy = self
    copy.storage[property] = value
    return copy
  }

  /// Returns a copy of this model produced by merging the given `other` model's storage into this
  /// model's storage.
  func merging(_ other: NEEpoxyModeled) -> Self {
    var copy = self
    copy.storage.merge(other.storage)
    return copy
  }
}
