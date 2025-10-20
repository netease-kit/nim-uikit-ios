// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics
import Foundation

// MARK: - NEShapeNodeProperties

final class NEShapeNodeProperties: NENodePropertyMap, NEKeypathSearchable {
  // MARK: Lifecycle

  init(shape: NEShape) {
    keypathName = shape.name
    path = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: shape.path.keyframes))
    keypathProperties = [
      "Path": path,
    ]
    properties = Array(keypathProperties.values)
  }

  // MARK: Internal

  var keypathName: String

  let path: NENodeProperty<NEBezierPath>
  let keypathProperties: [String: NEAnyNodeProperty]
  let properties: [NEAnyNodeProperty]
}

// MARK: - NEShapeNode

final class NEShapeNode: NEAnimatorNode, NEPathNode {
  // MARK: Lifecycle

  init(parentNode: NEAnimatorNode?, shape: NEShape) {
    pathOutput = NEPathOutputNode(parent: parentNode?.outputNode)
    properties = NEShapeNodeProperties(shape: shape)
    self.parentNode = parentNode
  }

  // MARK: Internal

  let properties: NEShapeNodeProperties

  let pathOutput: NEPathOutputNode

  let parentNode: NEAnimatorNode?
  var hasLocalUpdates = false
  var hasUpstreamUpdates = false
  var lastUpdateFrame: CGFloat?

  // MARK: Animator Node

  var propertyMap: NENodePropertyMap & NEKeypathSearchable {
    properties
  }

  var isEnabled = true {
    didSet {
      pathOutput.isEnabled = isEnabled
    }
  }

  func rebuildOutputs(frame: CGFloat) {
    pathOutput.setPath(properties.path.value, updateFrame: frame)
  }
}
