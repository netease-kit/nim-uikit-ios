// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import QuartzCore

// MARK: - NEPolygonNodeProperties

final class NEPolygonNodeProperties: NENodePropertyMap, NEKeypathSearchable {
  // MARK: Lifecycle

  init(star: NEStar) {
    keypathName = star.name
    direction = star.direction
    position = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: star.position.keyframes))
    outerRadius = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: star.outerRadius.keyframes))
    outerRoundedness = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: star.outerRoundness.keyframes))
    rotation = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: star.rotation.keyframes))
    points = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: star.points.keyframes))
    keypathProperties = [
      NEPropertyName.position.rawValue: position,
      "Outer Radius": outerRadius,
      "Outer Roundedness": outerRoundedness,
      NEPropertyName.rotation.rawValue: rotation,
      "Points": points,
    ]
    properties = Array(keypathProperties.values)
  }

  // MARK: Internal

  var keypathName: String

  var childKeypaths: [NEKeypathSearchable] = []

  let keypathProperties: [String: NEAnyNodeProperty]
  let properties: [NEAnyNodeProperty]

  let direction: NEPathDirection
  let position: NENodeProperty<NELottieVector3D>
  let outerRadius: NENodeProperty<NELottieVector1D>
  let outerRoundedness: NENodeProperty<NELottieVector1D>
  let rotation: NENodeProperty<NELottieVector1D>
  let points: NENodeProperty<NELottieVector1D>
}

// MARK: - NEPolygonNode

final class NEPolygonNode: NEAnimatorNode, NEPathNode {
  // MARK: Lifecycle

  init(parentNode: NEAnimatorNode?, star: NEStar) {
    pathOutput = NEPathOutputNode(parent: parentNode?.outputNode)
    properties = NEPolygonNodeProperties(star: star)
    self.parentNode = parentNode
  }

  // MARK: Internal

  /// Magic number needed for constructing path.
  static let PolygonConstant: CGFloat = 0.25

  let properties: NEPolygonNodeProperties

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
    let path = NEBezierPath.polygon(
      position: properties.position.value.pointValue,
      numberOfPoints: properties.points.value.cgFloatValue,
      outerRadius: properties.outerRadius.value.cgFloatValue,
      outerRoundedness: properties.outerRoundedness.value.cgFloatValue,
      rotation: properties.rotation.value.cgFloatValue,
      direction: properties.direction
    )

    pathOutput.setPath(path, updateFrame: frame)
  }
}

extension NEBezierPath {
  /// Creates a `NEBezierPath` in the shape of a polygon
  static func polygon(position: CGPoint,
                      numberOfPoints: CGFloat,
                      outerRadius: CGFloat,
                      outerRoundedness inputOuterRoundedness: CGFloat,
                      rotation: CGFloat,
                      direction: NEPathDirection)
    -> NEBezierPath {
    var currentAngle = (rotation - 90).toRadians()
    let anglePerPoint = ((2 * CGFloat.pi) / numberOfPoints)
    let outerRoundedness = inputOuterRoundedness * 0.01

    var point = CGPoint(
      x: outerRadius * cos(currentAngle),
      y: outerRadius * sin(currentAngle)
    )
    var vertices = [NECurveVertex(point: point + position, inTangentRelative: .zero, outTangentRelative: .zero)]

    var previousPoint = point
    currentAngle += anglePerPoint
    for _ in 0 ..< Int(ceil(numberOfPoints)) {
      previousPoint = point
      point = CGPoint(
        x: outerRadius * cos(currentAngle),
        y: outerRadius * sin(currentAngle)
      )

      if outerRoundedness != 0 {
        let cp1Theta = (atan2(previousPoint.y, previousPoint.x) - CGFloat.pi / 2)
        let cp1Dx = cos(cp1Theta)
        let cp1Dy = sin(cp1Theta)

        let cp2Theta = (atan2(point.y, point.x) - CGFloat.pi / 2)
        let cp2Dx = cos(cp2Theta)
        let cp2Dy = sin(cp2Theta)

        let cp1 = CGPoint(
          x: outerRadius * outerRoundedness * NEPolygonNode.PolygonConstant * cp1Dx,
          y: outerRadius * outerRoundedness * NEPolygonNode.PolygonConstant * cp1Dy
        )
        let cp2 = CGPoint(
          x: outerRadius * outerRoundedness * NEPolygonNode.PolygonConstant * cp2Dx,
          y: outerRadius * outerRoundedness * NEPolygonNode.PolygonConstant * cp2Dy
        )

        let previousVertex = vertices[vertices.endIndex - 1]
        vertices[vertices.endIndex - 1] = NECurveVertex(
          previousVertex.inTangent,
          previousVertex.point,
          previousVertex.point - cp1
        )
        vertices.append(NECurveVertex(point: point + position, inTangentRelative: cp2, outTangentRelative: .zero))
      } else {
        vertices.append(NECurveVertex(point: point + position, inTangentRelative: .zero, outTangentRelative: .zero))
      }
      currentAngle += anglePerPoint
    }
    let reverse = direction == .counterClockwise
    if reverse {
      vertices = vertices.reversed()
    }
    var path = NEBezierPath()
    for vertex in vertices {
      path.addVertex(reverse ? vertex.reversed() : vertex)
    }
    path.close()
    return path
  }
}
