// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import QuartzCore

// MARK: - NEEllipseNodeProperties

final class NEEllipseNodeProperties: NENodePropertyMap, NEKeypathSearchable {
  // MARK: Lifecycle

  init(ellipse: NEEllipse) {
    keypathName = ellipse.name
    direction = ellipse.direction
    position = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: ellipse.position.keyframes))
    size = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: ellipse.size.keyframes))
    keypathProperties = [
      NEPropertyName.position.rawValue: position,
      "Size": size,
    ]
    properties = Array(keypathProperties.values)
  }

  // MARK: Internal

  var keypathName: String

  let direction: NEPathDirection
  let position: NENodeProperty<NELottieVector3D>
  let size: NENodeProperty<NELottieVector3D>

  let keypathProperties: [String: NEAnyNodeProperty]
  let properties: [NEAnyNodeProperty]
}

// MARK: - NEEllipseNode

final class NEEllipseNode: NEAnimatorNode, NEPathNode {
  // MARK: Lifecycle

  init(parentNode: NEAnimatorNode?, ellipse: NEEllipse) {
    pathOutput = NEPathOutputNode(parent: parentNode?.outputNode)
    properties = NEEllipseNodeProperties(ellipse: ellipse)
    self.parentNode = parentNode
  }

  // MARK: Internal

  static let ControlPointConstant: CGFloat = 0.55228

  let pathOutput: NEPathOutputNode

  let properties: NEEllipseNodeProperties

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
    pathOutput.setPath(
      .ellipse(
        size: properties.size.value.sizeValue,
        center: properties.position.value.pointValue,
        direction: properties.direction
      ),
      updateFrame: frame
    )
  }
}

extension NEBezierPath {
  /// Constructs a `NEBezierPath` in the shape of an ellipse
  static func ellipse(size: CGSize,
                      center: CGPoint,
                      direction: NEPathDirection)
    -> NEBezierPath {
    // Unfortunately we HAVE to manually build out the ellipse.
    // Every Apple method constructs an ellipse from the 3 o-clock position
    // After effects constructs from the Noon position.
    // After effects does clockwise, but also has a flag for reversed.
    var half = size * 0.5
    if direction == .counterClockwise {
      half.width = half.width * -1
    }

    let q1 = CGPoint(x: center.x, y: center.y - half.height)
    let q2 = CGPoint(x: center.x + half.width, y: center.y)
    let q3 = CGPoint(x: center.x, y: center.y + half.height)
    let q4 = CGPoint(x: center.x - half.width, y: center.y)

    let cp = half * NEEllipseNode.ControlPointConstant

    var path = NEBezierPath(startPoint: NECurveVertex(
      point: q1,
      inTangentRelative: CGPoint(x: -cp.width, y: 0),
      outTangentRelative: CGPoint(x: cp.width, y: 0)
    ))
    path.addVertex(NECurveVertex(
      point: q2,
      inTangentRelative: CGPoint(x: 0, y: -cp.height),
      outTangentRelative: CGPoint(x: 0, y: cp.height)
    ))

    path.addVertex(NECurveVertex(
      point: q3,
      inTangentRelative: CGPoint(x: cp.width, y: 0),
      outTangentRelative: CGPoint(x: -cp.width, y: 0)
    ))

    path.addVertex(NECurveVertex(
      point: q4,
      inTangentRelative: CGPoint(x: 0, y: cp.height),
      outTangentRelative: CGPoint(x: 0, y: -cp.height)
    ))

    path.addVertex(NECurveVertex(
      point: q1,
      inTangentRelative: CGPoint(x: -cp.width, y: 0),
      outTangentRelative: CGPoint(x: cp.width, y: 0)
    ))
    path.close()
    return path
  }
}
