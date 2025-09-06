
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics
import Foundation

/// The container for the value of a property.
protocol NEAnyValueContainer: AnyObject {
  /// The stored value of the container
  var value: Any { get }

  /// Notifies the provider that it should update its container
  func setNeedsUpdate()

  /// When true the container needs to have its value updated by its provider
  var needsUpdate: Bool { get }

  /// The frame time of the last provided update
  var lastUpdateFrame: CGFloat { get }
}
