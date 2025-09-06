// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics
import Foundation

/// A node property that holds a reference to a T NEValueProvider and a T NEValueContainer.
class NENodeProperty<T>: NEAnyNodeProperty {
  // MARK: Lifecycle

  init(provider: NEAnyValueProvider) {
    valueProvider = provider
    originalValueProvider = valueProvider
    typedContainer = NEValueContainer<T>(provider.value(frame: 0) as! T)
    typedContainer.setNeedsUpdate()
  }

  // MARK: Internal

  var valueProvider: NEAnyValueProvider
  var originalValueProvider: NEAnyValueProvider

  var valueType: Any.Type { T.self }

  var value: T {
    typedContainer.outputValue
  }

  var valueContainer: NEAnyValueContainer {
    typedContainer
  }

  func needsUpdate(frame: CGFloat) -> Bool {
    valueContainer.needsUpdate || valueProvider.hasUpdate(frame: frame)
  }

  func setProvider(provider: NEAnyValueProvider) {
    guard provider.valueType == valueType else { return }
    valueProvider = provider
    valueContainer.setNeedsUpdate()
  }

  func update(frame: CGFloat) {
    typedContainer.setValue(valueProvider.value(frame: frame), forFrame: frame)
  }

  // MARK: Fileprivate

  fileprivate var typedContainer: NEValueContainer<T>
}
