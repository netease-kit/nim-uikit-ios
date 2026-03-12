
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEAnyEpoxyModelProperty

/// An erased `NEEpoxyModelProperty`, with the ability to call the `UpdateStrategy` even when the type
/// has been erased.
protocol NEAnyEpoxyModelProperty {
  /// Returns the updated property from updating from given old to new property.
  func update(old: Any, new: Any) -> Any
}

// MARK: - NEEpoxyModelProperty + NEAnyEpoxyModelProperty

extension NEEpoxyModelProperty: NEAnyEpoxyModelProperty {
  func update(old: Any, new: Any) -> Any {
    guard let typedOld = old as? Value else {
      NEEpoxyLogger.shared.assertionFailure(
        "Expected old to be of type \(Value.self), instead found \(old). This is programmer error.")
      return defaultValue()
    }
    guard let typedNew = new as? Value else {
      NEEpoxyLogger.shared.assertionFailure(
        "Expected new to be of type \(Value.self), instead found \(old). This is programmer error.")
      return defaultValue()
    }
    return updateStrategy.update(typedOld, typedNew)
  }
}
