// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics
import Foundation

/// A container for a node value that is Typed to T.
class NEValueContainer<T>: NEAnyValueContainer {
  // MARK: Lifecycle

  init(_ value: T) {
    outputValue = value
  }

  // MARK: Internal

  private(set) var lastUpdateFrame = CGFloat.infinity

  fileprivate(set) var needsUpdate = true

  var value: Any {
    outputValue as Any
  }

  var outputValue: T {
    didSet {
      needsUpdate = false
    }
  }

  func setValue(_ value: Any, forFrame: CGFloat) {
    if let typedValue = value as? T {
      needsUpdate = false
      lastUpdateFrame = forFrame
      outputValue = typedValue
    }
  }

  func setNeedsUpdate() {
    needsUpdate = true
  }
}
