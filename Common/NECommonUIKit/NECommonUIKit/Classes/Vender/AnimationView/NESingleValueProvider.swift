// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import QuartzCore

/// Returns a value for every frame.
final class NESingleValueProvider<ValueType: NEAnyInterpolatable>: NEValueProvider {
  // MARK: Lifecycle

  init(_ value: ValueType) {
    self.value = value
  }

  // MARK: Internal

  var value: ValueType {
    didSet {
      hasUpdate = true
    }
  }

  var storage: NEValueProviderStorage<ValueType> {
    .singleValue(value)
  }

  var valueType: Any.Type {
    ValueType.self
  }

  func hasUpdate(frame _: CGFloat) -> Bool {
    hasUpdate
  }

  // MARK: Private

  private var hasUpdate = true
}
