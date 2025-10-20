// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics

/// A node that has an output of a NEBezierPath
class NEPathOutputNode: NENodeOutput {
  // MARK: Lifecycle

  init(parent: NENodeOutput?) {
    self.parent = parent
  }

  // MARK: Internal

  let parent: NENodeOutput?

  fileprivate(set) var outputPath: CGPath?

  var lastUpdateFrame: CGFloat?
  var lastPathBuildFrame: CGFloat?
  var isEnabled = true
  fileprivate(set) var totalLength: CGFloat = 0
  fileprivate(set) var pathObjects: [NECompoundBezierPath] = []

  func hasOutputUpdates(_ forFrame: CGFloat) -> Bool {
    guard isEnabled else {
      let upstreamUpdates = parent?.hasOutputUpdates(forFrame) ?? false
      outputPath = parent?.outputPath
      return upstreamUpdates
    }

    /// Ask if parent was updated
    let upstreamUpdates = parent?.hasOutputUpdates(forFrame) ?? false

    /// If parent was updated and the path hasn't been built for this frame, clear the path.
    if upstreamUpdates && lastPathBuildFrame != forFrame {
      outputPath = nil
    }

    if outputPath == nil {
      /// If the path is clear, build the new path.
      lastPathBuildFrame = forFrame
      let newPath = CGMutablePath()
      if let parentNode = parent, let parentPath = parentNode.outputPath {
        newPath.addPath(parentPath)
      }
      for path in pathObjects {
        for subPath in path.paths {
          newPath.addPath(subPath.cgPath())
        }
      }
      outputPath = newPath
    }

    /// Return true if there were upstream updates or if this node was updated.
    return upstreamUpdates || (lastUpdateFrame == forFrame)
  }

  @discardableResult
  func removePaths(updateFrame: CGFloat?) -> [NECompoundBezierPath] {
    lastUpdateFrame = updateFrame
    let returnPaths = pathObjects
    outputPath = nil
    totalLength = 0
    pathObjects = []
    return returnPaths
  }

  func setPath(_ path: NEBezierPath, updateFrame: CGFloat) {
    lastUpdateFrame = updateFrame
    outputPath = nil
    totalLength = path.length
    pathObjects = [NECompoundBezierPath(path: path)]
  }

  func appendPath(_ path: NECompoundBezierPath, updateFrame: CGFloat) {
    lastUpdateFrame = updateFrame
    outputPath = nil
    totalLength = totalLength + path.length
    pathObjects.append(path)
  }
}
