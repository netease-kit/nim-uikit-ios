// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import QuartzCore

// MARK: - NERoundedCornersProperties

final class NERoundedCornersProperties: NENodePropertyMap, NEKeypathSearchable {
  // MARK: Lifecycle

  init(roundedCorners: NERoundedCorners) {
    keypathName = roundedCorners.name
    radius = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: roundedCorners.radius.keyframes))
    keypathProperties = ["Radius": radius]
    properties = Array(keypathProperties.values)
  }

  // MARK: Internal

  let keypathProperties: [String: NEAnyNodeProperty]
  let properties: [NEAnyNodeProperty]
  let keypathName: String

  let radius: NENodeProperty<NELottieVector1D>
}

// MARK: - NERoundedCornersNode

final class NERoundedCornersNode: NEAnimatorNode {
  // MARK: Lifecycle

  init(parentNode: NEAnimatorNode?, roundedCorners: NERoundedCorners, upstreamPaths: [NEPathOutputNode]) {
    outputNode = NEPassThroughOutputNode(parent: parentNode?.outputNode)
    self.parentNode = parentNode
    properties = NERoundedCornersProperties(roundedCorners: roundedCorners)
    self.upstreamPaths = upstreamPaths
  }

  // MARK: Internal

  let properties: NERoundedCornersProperties

  let parentNode: NEAnimatorNode?
  let outputNode: NENodeOutput
  var hasLocalUpdates = false
  var hasUpstreamUpdates = false
  var lastUpdateFrame: CGFloat?
  var isEnabled = true

  // MARK: Animator Node

  var propertyMap: NENodePropertyMap & NEKeypathSearchable {
    properties
  }

  func forceUpstreamOutputUpdates() -> Bool {
    hasLocalUpdates || hasUpstreamUpdates
  }

  func rebuildOutputs(frame: CGFloat) {
    for pathContainer in upstreamPaths {
      let pathObjects = pathContainer.removePaths(updateFrame: frame)
      for path in pathObjects {
        let cornerRadius = properties.radius.value.cgFloatValue
        if cornerRadius != 0 {
          pathContainer.appendPath(
            path.roundCorners(radius: cornerRadius),
            updateFrame: frame
          )
        } else {
          pathContainer.appendPath(path, updateFrame: frame)
        }
      }
    }
  }

  // MARK: Fileprivate

  fileprivate let upstreamPaths: [NEPathOutputNode]
}
