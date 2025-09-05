// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import QuartzCore

// MARK: - NETrimPathProperties

final class NETrimPathProperties: NENodePropertyMap, NEKeypathSearchable {
  // MARK: Lifecycle

  init(trim: NETrim) {
    keypathName = trim.name
    start = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: trim.start.keyframes))
    end = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: trim.end.keyframes))
    offset = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: trim.offset.keyframes))
    type = trim.trimType
    keypathProperties = [
      "Start": start,
      "End": end,
      "Offset": offset,
    ]
    properties = Array(keypathProperties.values)
  }

  // MARK: Internal

  let keypathProperties: [String: NEAnyNodeProperty]
  let properties: [NEAnyNodeProperty]
  let keypathName: String

  let start: NENodeProperty<NELottieVector1D>
  let end: NENodeProperty<NELottieVector1D>
  let offset: NENodeProperty<NELottieVector1D>
  let type: NETrimType
}

// MARK: - NETrimPathNode

final class NETrimPathNode: NEAnimatorNode {
  // MARK: Lifecycle

  init(parentNode: NEAnimatorNode?, trim: NETrim, upstreamPaths: [NEPathOutputNode]) {
    outputNode = NEPassThroughOutputNode(parent: parentNode?.outputNode)
    self.parentNode = parentNode
    properties = NETrimPathProperties(trim: trim)
    self.upstreamPaths = upstreamPaths
  }

  // MARK: Internal

  let properties: NETrimPathProperties

  let parentNode: NEAnimatorNode?
  let outputNode: NENodeOutput
  var hasLocalUpdates = false
  var hasUpstreamUpdates = false
  var lastUpdateFrame: CGFloat? = nil
  var isEnabled = true

  // MARK: Animator Node

  var propertyMap: NENodePropertyMap & NEKeypathSearchable {
    properties
  }

  func forceUpstreamOutputUpdates() -> Bool {
    hasLocalUpdates || hasUpstreamUpdates
  }

  func rebuildOutputs(frame: CGFloat) {
    /// Make sure there is a trim.
    let startValue = properties.start.value.cgFloatValue * 0.01
    let endValue = properties.end.value.cgFloatValue * 0.01
    let start = min(startValue, endValue)
    let end = max(startValue, endValue)

    let offset = properties.offset.value.cgFloatValue.truncatingRemainder(dividingBy: 360) / 360

    /// No need to trim, it's a full path
    if start == 0, end == 1 {
      return
    }

    /// All paths are empty.
    if start == end {
      for pathContainer in upstreamPaths {
        pathContainer.removePaths(updateFrame: frame)
      }
      return
    }

    if properties.type == .simultaneously {
      /// Just trim each path
      for pathContainer in upstreamPaths {
        let pathObjects = pathContainer.removePaths(updateFrame: frame)
        for path in pathObjects {
          // We are treating each compount path as an individual path. Its subpaths are treated as a whole.
          pathContainer.appendPath(
            path.trim(fromPosition: start, toPosition: end, offset: offset, trimSimultaneously: false),
            updateFrame: frame
          )
        }
      }
      return
    }

    /// Individual path trimming.

    /// Brace yourself for the below code.

    /// Normalize lengths with offset.
    var startPosition = (start + offset).truncatingRemainder(dividingBy: 1)
    var endPosition = (end + offset).truncatingRemainder(dividingBy: 1)

    if startPosition < 0 {
      startPosition = 1 + startPosition
    }

    if endPosition < 0 {
      endPosition = 1 + endPosition
    }
    if startPosition == 1 {
      startPosition = 0
    }
    if endPosition == 0 {
      endPosition = 1
    }

    /// First get the total length of all paths.
    var totalLength: CGFloat = 0
    for upstreamPath in upstreamPaths {
      totalLength = totalLength + upstreamPath.totalLength
    }

    /// Now determine the start and end cut lengths
    let startLength = startPosition * totalLength
    let endLength = endPosition * totalLength
    var pathStart: CGFloat = 0

    /// Now loop through all path containers
    for pathContainer in upstreamPaths {
      let pathEnd = pathStart + pathContainer.totalLength

      if
        !startLength.isInRange(pathStart, pathEnd) &&
        endLength.isInRange(pathStart, pathEnd) {
        // pathStart|=======E----------------------|pathEnd
        // Cut path components, removing after end.

        let pathCutLength = endLength - pathStart
        let subpaths = pathContainer.removePaths(updateFrame: frame)
        var subpathStart: CGFloat = 0
        for path in subpaths {
          let subpathEnd = subpathStart + path.length
          if pathCutLength < subpathEnd {
            /// This is the subpath that needs to be cut.
            let cutLength = pathCutLength - subpathStart
            let newPath = path.trim(fromPosition: 0, toPosition: cutLength / path.length, offset: 0, trimSimultaneously: false)
            pathContainer.appendPath(newPath, updateFrame: frame)
            break
          } else {
            /// Add to container and move on
            pathContainer.appendPath(path, updateFrame: frame)
          }
          if pathCutLength == subpathEnd {
            /// Right on the end. The next subpath is not included. Break.
            break
          }
          subpathStart = subpathEnd
        }

      } else if
        !endLength.isInRange(pathStart, pathEnd) &&
        startLength.isInRange(pathStart, pathEnd) {
        // pathStart|-------S======================|pathEnd
        //

        // Cut path components, removing before beginning.
        let pathCutLength = startLength - pathStart
        // Clear paths from container
        let subpaths = pathContainer.removePaths(updateFrame: frame)
        var subpathStart: CGFloat = 0
        for path in subpaths {
          let subpathEnd = subpathStart + path.length

          if subpathStart < pathCutLength, pathCutLength < subpathEnd {
            /// This is the subpath that needs to be cut.
            let cutLength = pathCutLength - subpathStart
            let newPath = path.trim(fromPosition: cutLength / path.length, toPosition: 1, offset: 0, trimSimultaneously: false)
            pathContainer.appendPath(newPath, updateFrame: frame)
          } else if pathCutLength <= subpathStart {
            pathContainer.appendPath(path, updateFrame: frame)
          }
          subpathStart = subpathEnd
        }
      } else if
        endLength.isInRange(pathStart, pathEnd) &&
        startLength.isInRange(pathStart, pathEnd) {
        // pathStart|-------S============E---------|endLength
        // pathStart|=====E----------------S=======|endLength
        // trim from path beginning to endLength.

        // Cut path components, removing before beginnings.
        let startCutLength = startLength - pathStart
        let endCutLength = endLength - pathStart
        // Clear paths from container
        let subpaths = pathContainer.removePaths(updateFrame: frame)
        var subpathStart: CGFloat = 0
        for path in subpaths {
          let subpathEnd = subpathStart + path.length

          if
            !startCutLength.isInRange(subpathStart, subpathEnd),
            !endCutLength.isInRange(subpathStart, subpathEnd) {
            // The whole path is included. Add
            // S|==============================|E
            pathContainer.appendPath(path, updateFrame: frame)

          } else if
            startCutLength.isInRange(subpathStart, subpathEnd),
            !endCutLength.isInRange(subpathStart, subpathEnd) {
            /// The start of the path needs to be trimmed
            //  |-------S======================|E
            let cutLength = startCutLength - subpathStart
            let newPath = path.trim(fromPosition: cutLength / path.length, toPosition: 1, offset: 0, trimSimultaneously: false)
            pathContainer.appendPath(newPath, updateFrame: frame)
          } else if
            !startCutLength.isInRange(subpathStart, subpathEnd),
            endCutLength.isInRange(subpathStart, subpathEnd) {
            // S|=======E----------------------|
            let cutLength = endCutLength - subpathStart
            let newPath = path.trim(fromPosition: 0, toPosition: cutLength / path.length, offset: 0, trimSimultaneously: false)
            pathContainer.appendPath(newPath, updateFrame: frame)
            break
          } else if
            startCutLength.isInRange(subpathStart, subpathEnd),
            endCutLength.isInRange(subpathStart, subpathEnd) {
            //  |-------S============E---------|
            let cutFromLength = startCutLength - subpathStart
            let cutToLength = endCutLength - subpathStart
            let newPath = path.trim(
              fromPosition: cutFromLength / path.length,
              toPosition: cutToLength / path.length,
              offset: 0,
              trimSimultaneously: false
            )
            pathContainer.appendPath(newPath, updateFrame: frame)
            break
          }

          subpathStart = subpathEnd
        }
      } else if
        (endLength <= pathStart && pathEnd <= startLength) ||
        (startLength <= pathStart && endLength <= pathStart) ||
        (pathEnd <= startLength && pathEnd <= endLength) {
        /// The Path needs to be cleared
        pathContainer.removePaths(updateFrame: frame)
      }

      pathStart = pathEnd
    }
  }

  // MARK: Fileprivate

  fileprivate let upstreamPaths: [NEPathOutputNode]
}
