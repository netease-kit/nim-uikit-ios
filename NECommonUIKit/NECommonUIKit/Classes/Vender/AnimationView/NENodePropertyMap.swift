// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NENodePropertyMap

protocol NENodePropertyMap {
  var properties: [NEAnyNodeProperty] { get }
}

extension NENodePropertyMap {
  var childKeypaths: [NEKeypathSearchable] {
    []
  }

  var keypathLayer: CALayer? {
    nil
  }

  /// Checks if the node's local contents need to be rebuilt.
  func needsLocalUpdate(frame: CGFloat) -> Bool {
    for property in properties {
      if property.needsUpdate(frame: frame) {
        return true
      }
    }
    return false
  }

  /// Rebuilds only the local nodes that have an update for the frame
  func updateNodeProperties(frame: CGFloat) {
    for property in properties {
      property.update(frame: frame)
    }
  }
}
