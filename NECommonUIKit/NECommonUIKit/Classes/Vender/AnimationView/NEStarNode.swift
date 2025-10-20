// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import QuartzCore

// MARK: - NEStarNodeProperties

final class NEStarNodeProperties: NENodePropertyMap, NEKeypathSearchable {
  // MARK: Lifecycle

  init(star: NEStar) {
    keypathName = star.name
    direction = star.direction
    position = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: star.position.keyframes))
    outerRadius = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: star.outerRadius.keyframes))
    outerRoundedness = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: star.outerRoundness.keyframes))
    if let innerRadiusKeyframes = star.innerRadius?.keyframes {
      innerRadius = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: innerRadiusKeyframes))
    } else {
      innerRadius = NENodeProperty(provider: NESingleValueProvider(NELottieVector1D(0)))
    }
    if let innderRoundedness = star.innerRoundness?.keyframes {
      innerRoundedness = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: innderRoundedness))
    } else {
      innerRoundedness = NENodeProperty(provider: NESingleValueProvider(NELottieVector1D(0)))
    }
    rotation = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: star.rotation.keyframes))
    points = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: star.points.keyframes))
    keypathProperties = [
      NEPropertyName.position.rawValue: position,
      "Outer Radius": outerRadius,
      "Outer Roundedness": outerRoundedness,
      "Inner Radius": innerRadius,
      "Inner Roundedness": innerRoundedness,
      NEPropertyName.rotation.rawValue: rotation,
      "Points": points,
    ]
    properties = Array(keypathProperties.values)
  }

  // MARK: Internal

  var keypathName: String

  let keypathProperties: [String: NEAnyNodeProperty]
  let properties: [NEAnyNodeProperty]

  let direction: NEPathDirection
  let position: NENodeProperty<NELottieVector3D>
  let outerRadius: NENodeProperty<NELottieVector1D>
  let outerRoundedness: NENodeProperty<NELottieVector1D>
  let innerRadius: NENodeProperty<NELottieVector1D>
  let innerRoundedness: NENodeProperty<NELottieVector1D>
  let rotation: NENodeProperty<NELottieVector1D>
  let points: NENodeProperty<NELottieVector1D>
}

// MARK: - NEStarNode

final class NEStarNode: NEAnimatorNode, NEPathNode {
  // MARK: Lifecycle

  init(parentNode: NEAnimatorNode?, star: NEStar) {
    pathOutput = NEPathOutputNode(parent: parentNode?.outputNode)
    properties = NEStarNodeProperties(star: star)
    self.parentNode = parentNode
  }

  // MARK: Internal

  /// Magic number needed for building path data
  static let PolystarConstant: CGFloat = 0.47829

  let properties: NEStarNodeProperties

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
    let path = NEBezierPath.star(
      position: properties.position.value.pointValue,
      outerRadius: properties.outerRadius.value.cgFloatValue,
      innerRadius: properties.innerRadius.value.cgFloatValue,
      outerRoundedness: properties.outerRoundedness.value.cgFloatValue,
      innerRoundedness: properties.innerRoundedness.value.cgFloatValue,
      numberOfPoints: properties.points.value.cgFloatValue,
      rotation: properties.rotation.value.cgFloatValue,
      direction: properties.direction
    )

    pathOutput.setPath(path, updateFrame: frame)
  }
}

extension NEBezierPath {
  /// Constructs a `NEBezierPath` in the shape of a star
  static func star(position: CGPoint,
                   outerRadius: CGFloat,
                   innerRadius: CGFloat,
                   outerRoundedness inoutOuterRoundedness: CGFloat,
                   innerRoundedness inputInnerRoundedness: CGFloat,
                   numberOfPoints: CGFloat,
                   rotation: CGFloat,
                   direction: NEPathDirection)
    -> NEBezierPath {
    var currentAngle = (rotation - 90).toRadians()
    let anglePerPoint = (2 * CGFloat.pi) / numberOfPoints
    let halfAnglePerPoint = anglePerPoint / 2.0
    let partialPointAmount = numberOfPoints - floor(numberOfPoints)
    let outerRoundedness = inoutOuterRoundedness * 0.01
    let innerRoundedness = inputInnerRoundedness * 0.01

    var point: CGPoint = .zero

    var partialPointRadius: CGFloat = 0
    if partialPointAmount != 0 {
      currentAngle += halfAnglePerPoint * (1 - partialPointAmount)
      partialPointRadius = innerRadius + partialPointAmount * (outerRadius - innerRadius)
      point.x = (partialPointRadius * cos(currentAngle))
      point.y = (partialPointRadius * sin(currentAngle))
      currentAngle += anglePerPoint * partialPointAmount / 2
    } else {
      point.x = (outerRadius * cos(currentAngle))
      point.y = (outerRadius * sin(currentAngle))
      currentAngle += halfAnglePerPoint
    }

    var vertices = [NECurveVertex]()
    vertices.append(NECurveVertex(point: point + position, inTangentRelative: .zero, outTangentRelative: .zero))

    var previousPoint = point
    var longSegment = false
    let numPoints = Int(ceil(numberOfPoints) * 2)
    for i in 0 ..< numPoints {
      var radius = longSegment ? outerRadius : innerRadius
      var dTheta = halfAnglePerPoint
      if partialPointRadius != 0, i == numPoints - 2 {
        dTheta = anglePerPoint * partialPointAmount / 2
      }
      if partialPointRadius != 0, i == numPoints - 1 {
        radius = partialPointRadius
      }
      previousPoint = point
      point.x = (radius * cos(currentAngle))
      point.y = (radius * sin(currentAngle))

      if innerRoundedness == 0, outerRoundedness == 0 {
        vertices.append(NECurveVertex(point: point + position, inTangentRelative: .zero, outTangentRelative: .zero))
      } else {
        let cp1Theta = (atan2(previousPoint.y, previousPoint.x) - CGFloat.pi / 2)
        let cp1Dx = cos(cp1Theta)
        let cp1Dy = sin(cp1Theta)

        let cp2Theta = (atan2(point.y, point.x) - CGFloat.pi / 2)
        let cp2Dx = cos(cp2Theta)
        let cp2Dy = sin(cp2Theta)

        let cp1Roundedness = longSegment ? innerRoundedness : outerRoundedness
        let cp2Roundedness = longSegment ? outerRoundedness : innerRoundedness
        let cp1Radius = longSegment ? innerRadius : outerRadius
        let cp2Radius = longSegment ? outerRadius : innerRadius

        var cp1 = CGPoint(
          x: cp1Radius * cp1Roundedness * NEStarNode.PolystarConstant * cp1Dx,
          y: cp1Radius * cp1Roundedness * NEStarNode.PolystarConstant * cp1Dy
        )
        var cp2 = CGPoint(
          x: cp2Radius * cp2Roundedness * NEStarNode.PolystarConstant * cp2Dx,
          y: cp2Radius * cp2Roundedness * NEStarNode.PolystarConstant * cp2Dy
        )
        if partialPointAmount != 0 {
          if i == 0 {
            cp1 = cp1 * partialPointAmount
          } else if i == numPoints - 1 {
            cp2 = cp2 * partialPointAmount
          }
        }
        let previousVertex = vertices[vertices.endIndex - 1]
        vertices[vertices.endIndex - 1] = NECurveVertex(
          previousVertex.inTangent,
          previousVertex.point,
          previousVertex.point - cp1
        )
        vertices.append(NECurveVertex(point: point + position, inTangentRelative: cp2, outTangentRelative: .zero))
      }
      currentAngle += dTheta
      longSegment = !longSegment
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
