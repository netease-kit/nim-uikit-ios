// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NELayerTransformProperties

final class NELayerTransformProperties: NENodePropertyMap, NEKeypathSearchable {
  // MARK: Lifecycle

  init(transform: NETransform) {
    anchor = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: transform.anchorPoint.keyframes))
    scale = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: transform.scale.keyframes))
    rotationX = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: transform.rotationX.keyframes))
    rotationY = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: transform.rotationY.keyframes))
    rotationZ = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: transform.rotationZ.keyframes))
    opacity = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: transform.opacity.keyframes))

    var propertyMap: [String: NEAnyNodeProperty] = [
      "Anchor Point": anchor,
      NEPropertyName.scale.rawValue: scale,
      NEPropertyName.rotation.rawValue: rotationZ,
      "Rotation X": rotationX,
      "Rotation Y": rotationY,
      "Rotation Z": rotationZ,
      NEPropertyName.opacity.rawValue: opacity,
    ]

    if
      let positionKeyframesX = transform.positionX?.keyframes,
      let positionKeyframesY = transform.positionY?.keyframes {
      let xPosition: NENodeProperty<NELottieVector1D> = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: positionKeyframesX))
      let yPosition: NENodeProperty<NELottieVector1D> = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: positionKeyframesY))
      propertyMap["X Position"] = xPosition
      propertyMap["Y Position"] = yPosition
      positionX = xPosition
      positionY = yPosition
      position = nil
    } else if let positionKeyframes = transform.position?.keyframes {
      let position: NENodeProperty<NELottieVector3D> = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: positionKeyframes))
      propertyMap[NEPropertyName.position.rawValue] = position
      self.position = position
      positionX = nil
      positionY = nil
    } else {
      position = nil
      positionY = nil
      positionX = nil
    }

    keypathProperties = propertyMap
    properties = Array(propertyMap.values)
  }

  // MARK: Internal

  let keypathProperties: [String: NEAnyNodeProperty]
  var keypathName = "NETransform"

  let properties: [NEAnyNodeProperty]

  let anchor: NENodeProperty<NELottieVector3D>
  let scale: NENodeProperty<NELottieVector3D>
  let rotationX: NENodeProperty<NELottieVector1D>
  let rotationY: NENodeProperty<NELottieVector1D>
  let rotationZ: NENodeProperty<NELottieVector1D>
  let position: NENodeProperty<NELottieVector3D>?
  let positionX: NENodeProperty<NELottieVector1D>?
  let positionY: NENodeProperty<NELottieVector1D>?
  let opacity: NENodeProperty<NELottieVector1D>

  var childKeypaths: [NEKeypathSearchable] {
    []
  }
}

// MARK: - NELayerTransformNode

class NELayerTransformNode: NEAnimatorNode {
  // MARK: Lifecycle

  init(transform: NETransform) {
    transformProperties = NELayerTransformProperties(transform: transform)
  }

  // MARK: Internal

  let outputNode: NENodeOutput = NEPassThroughOutputNode(parent: nil)

  let transformProperties: NELayerTransformProperties

  var parentNode: NEAnimatorNode?
  var hasLocalUpdates = false
  var hasUpstreamUpdates = false
  var lastUpdateFrame: CGFloat?
  var isEnabled = true

  var opacity: Float = 1
  var localTransform: CATransform3D = CATransform3DIdentity
  var globalTransform: CATransform3D = CATransform3DIdentity

  // MARK: Animator Node Protocol

  var propertyMap: NENodePropertyMap & NEKeypathSearchable {
    transformProperties
  }

  func shouldRebuildOutputs(frame _: CGFloat) -> Bool {
    hasLocalUpdates || hasUpstreamUpdates
  }

  func rebuildOutputs(frame _: CGFloat) {
    opacity = Float(transformProperties.opacity.value.cgFloatValue) * 0.01

    let position: CGPoint
    if let point = transformProperties.position?.value.pointValue {
      position = point
    } else if
      let xPos = transformProperties.positionX?.value.cgFloatValue,
      let yPos = transformProperties.positionY?.value.cgFloatValue {
      position = CGPoint(x: xPos, y: yPos)
    } else {
      position = .zero
    }

    localTransform = CATransform3D.makeTransform(
      anchor: transformProperties.anchor.value.pointValue,
      position: position,
      scale: transformProperties.scale.value.sizeValue,
      rotationX: transformProperties.rotationX.value.cgFloatValue,
      rotationY: transformProperties.rotationY.value.cgFloatValue,
      rotationZ: transformProperties.rotationZ.value.cgFloatValue,
      skew: nil,
      skewAxis: nil
    )

    if let parentNode = parentNode as? NELayerTransformNode {
      globalTransform = CATransform3DConcat(localTransform, parentNode.globalTransform)
    } else {
      globalTransform = localTransform
    }
  }
}
