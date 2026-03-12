// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics
import Foundation

// MARK: - NERectNodeProperties

final class NERectNodeProperties: NENodePropertyMap, NEKeypathSearchable {
  // MARK: Lifecycle

  init(rectangle: NERectangle) {
    keypathName = rectangle.name
    direction = rectangle.direction
    position = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: rectangle.position.keyframes))
    size = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: rectangle.size.keyframes))
    cornerRadius = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: rectangle.cornerRadius.keyframes))

    keypathProperties = [
      NEPropertyName.position.rawValue: position,
      "Size": size,
      "Roundness": cornerRadius,
    ]

    properties = Array(keypathProperties.values)
  }

  // MARK: Internal

  var keypathName: String

  let keypathProperties: [String: NEAnyNodeProperty]
  let properties: [NEAnyNodeProperty]

  let direction: NEPathDirection
  let position: NENodeProperty<NELottieVector3D>
  let size: NENodeProperty<NELottieVector3D>
  let cornerRadius: NENodeProperty<NELottieVector1D>
}

// MARK: - NERectangleNode

final class NERectangleNode: NEAnimatorNode, NEPathNode {
  // MARK: Lifecycle

  init(parentNode: NEAnimatorNode?, rectangle: NERectangle) {
    properties = NERectNodeProperties(rectangle: rectangle)
    pathOutput = NEPathOutputNode(parent: parentNode?.outputNode)
    self.parentNode = parentNode
  }

  // MARK: Internal

  let properties: NERectNodeProperties

  let pathOutput: NEPathOutputNode
  let parentNode: NEAnimatorNode?
  var hasLocalUpdates = false
  var hasUpstreamUpdates = false
  var lastUpdateFrame: CGFloat? = nil

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
      .rectangle(
        position: properties.position.value.pointValue,
        size: properties.size.value.sizeValue,
        cornerRadius: properties.cornerRadius.value.cgFloatValue,
        direction: properties.direction
      ),
      updateFrame: frame
    )
  }
}

// MARK: - NEBezierPath + rectangle

extension NEBezierPath {
  /// Constructs a `NEBezierPath` in the shape of a rectangle, optionally with rounded corners
  static func rectangle(position: CGPoint,
                        size inputSize: CGSize,
                        cornerRadius: CGFloat,
                        direction: NEPathDirection)
    -> NEBezierPath {
    let size = inputSize * 0.5
    let radius = min(min(cornerRadius, size.width), size.height)

    var bezierPath = NEBezierPath()
    let points: [NECurveVertex]

    if radius <= 0 {
      /// No Corners
      points = [
        /// Lead In
        NECurveVertex(
          point: CGPoint(x: size.width, y: -size.height),
          inTangentRelative: .zero,
          outTangentRelative: .zero
        )
        .translated(position),
        /// Corner 1
        NECurveVertex(
          point: CGPoint(x: size.width, y: size.height),
          inTangentRelative: .zero,
          outTangentRelative: .zero
        )
        .translated(position),
        /// Corner 2
        NECurveVertex(
          point: CGPoint(x: -size.width, y: size.height),
          inTangentRelative: .zero,
          outTangentRelative: .zero
        )
        .translated(position),
        /// Corner 3
        NECurveVertex(
          point: CGPoint(x: -size.width, y: -size.height),
          inTangentRelative: .zero,
          outTangentRelative: .zero
        )
        .translated(position),
        /// Corner 4
        NECurveVertex(
          point: CGPoint(x: size.width, y: -size.height),
          inTangentRelative: .zero,
          outTangentRelative: .zero
        )
        .translated(position),
      ]
    } else {
      let controlPoint = radius * NEEllipseNode.ControlPointConstant
      points = [
        /// Lead In
        NECurveVertex(
          CGPoint(x: radius, y: 0),
          CGPoint(x: radius, y: 0),
          CGPoint(x: radius, y: 0)
        )
        .translated(CGPoint(x: -radius, y: radius))
        .translated(CGPoint(x: size.width, y: -size.height))
        .translated(position),
        /// Corner 1
        NECurveVertex(
          CGPoint(x: radius, y: 0), // In tangent
          CGPoint(x: radius, y: 0), // Point
          CGPoint(x: radius, y: controlPoint)
        )
        .translated(CGPoint(x: -radius, y: -radius))
        .translated(CGPoint(x: size.width, y: size.height))
        .translated(position),
        NECurveVertex(
          CGPoint(x: controlPoint, y: radius), // In tangent
          CGPoint(x: 0, y: radius), // Point
          CGPoint(x: 0, y: radius)
        ) // Out Tangent
        .translated(CGPoint(x: -radius, y: -radius))
        .translated(CGPoint(x: size.width, y: size.height))
        .translated(position),
        /// Corner 2
        NECurveVertex(
          CGPoint(x: 0, y: radius), // In tangent
          CGPoint(x: 0, y: radius), // Point
          CGPoint(x: -controlPoint, y: radius)
        ) // Out tangent
        .translated(CGPoint(x: radius, y: -radius))
        .translated(CGPoint(x: -size.width, y: size.height))
        .translated(position),
        NECurveVertex(
          CGPoint(x: -radius, y: controlPoint), // In tangent
          CGPoint(x: -radius, y: 0), // Point
          CGPoint(x: -radius, y: 0)
        ) // Out tangent
        .translated(CGPoint(x: radius, y: -radius))
        .translated(CGPoint(x: -size.width, y: size.height))
        .translated(position),
        /// Corner 3
        NECurveVertex(
          CGPoint(x: -radius, y: 0), // In tangent
          CGPoint(x: -radius, y: 0), // Point
          CGPoint(x: -radius, y: -controlPoint)
        ) // Out tangent
        .translated(CGPoint(x: radius, y: radius))
        .translated(CGPoint(x: -size.width, y: -size.height))
        .translated(position),
        NECurveVertex(
          CGPoint(x: -controlPoint, y: -radius), // In tangent
          CGPoint(x: 0, y: -radius), // Point
          CGPoint(x: 0, y: -radius)
        ) // Out tangent
        .translated(CGPoint(x: radius, y: radius))
        .translated(CGPoint(x: -size.width, y: -size.height))
        .translated(position),
        /// Corner 4
        NECurveVertex(
          CGPoint(x: 0, y: -radius), // In tangent
          CGPoint(x: 0, y: -radius), // Point
          CGPoint(x: controlPoint, y: -radius)
        ) // Out tangent
        .translated(CGPoint(x: -radius, y: radius))
        .translated(CGPoint(x: size.width, y: -size.height))
        .translated(position),
        NECurveVertex(
          CGPoint(x: radius, y: -controlPoint), // In tangent
          CGPoint(x: radius, y: 0), // Point
          CGPoint(x: radius, y: 0)
        ) // Out tangent
        .translated(CGPoint(x: -radius, y: radius))
        .translated(CGPoint(x: size.width, y: -size.height))
        .translated(position),
      ]
    }
    let reversed = direction == .counterClockwise
    let pathPoints = reversed ? points.reversed() : points
    for point in pathPoints {
      bezierPath.addVertex(reversed ? point.reversed() : point)
    }
    bezierPath.close()
    return bezierPath
  }
}
