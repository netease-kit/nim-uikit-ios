// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics

class NEPassThroughOutputNode: NENodeOutput {
  // MARK: Lifecycle

  init(parent: NENodeOutput?) {
    self.parent = parent
  }

  // MARK: Internal

  let parent: NENodeOutput?

  var hasUpdate = false
  var isEnabled = true

  var outputPath: CGPath? {
    if let parent {
      return parent.outputPath
    }
    return nil
  }

  func hasOutputUpdates(_ forFrame: CGFloat) -> Bool {
    /// Changes to this node do not affect downstream nodes.
    let parentUpdate = parent?.hasOutputUpdates(forFrame) ?? false
    /// Changes to upstream nodes do, however, affect this nodes state.
    hasUpdate = hasUpdate || parentUpdate
    return parentUpdate
  }

  func hasRenderUpdates(_ forFrame: CGFloat) -> Bool {
    /// Return true if there are upstream updates or if this node has updates
    let upstreamUpdates = parent?.hasOutputUpdates(forFrame) ?? false
    hasUpdate = hasUpdate || upstreamUpdates
    return hasUpdate
  }
}
