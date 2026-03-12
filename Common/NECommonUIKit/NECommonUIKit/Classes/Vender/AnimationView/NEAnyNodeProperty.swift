
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics
import Foundation

// MARK: - NEAnyNodeProperty

/// A property of a node. The node property holds a provider and a container
protocol NEAnyNodeProperty {
  /// Returns true if the property needs to recompute its stored value
  func needsUpdate(frame: CGFloat) -> Bool

  /// Updates the property for the frame
  func update(frame: CGFloat)

  /// The stored value container for the property
  var valueContainer: NEAnyValueContainer { get }

  /// The value provider for the property
  var valueProvider: NEAnyValueProvider { get }

  /// The original value provider for the property
  var originalValueProvider: NEAnyValueProvider { get }

  /// The Type of the value provider
  var valueType: Any.Type { get }

  /// Sets the value provider for the property.
  func setProvider(provider: NEAnyValueProvider)
}

extension NEAnyNodeProperty {
  /// Returns the most recently computed value for the keypath, returns nil if property wasn't found
  func getValueOfType<T>() -> T? {
    valueContainer.value as? T
  }

  /// Returns the most recently computed value for the keypath, returns nil if property wasn't found
  func getValue() -> Any? {
    valueContainer.value
  }
}
