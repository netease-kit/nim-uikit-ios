// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NEGroupNodeProperties

final class NEGroupNodeProperties: NENodePropertyMap, NEKeypathSearchable {
  // MARK: Lifecycle

  init(transform: NEShapeTransform?) {
    if let transform {
      anchor = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: transform.anchor.keyframes))
      position = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: transform.position.keyframes))
      scale = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: transform.scale.keyframes))
      rotationX = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: transform.rotationX.keyframes))
      rotationY = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: transform.rotationY.keyframes))
      rotationZ = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: transform.rotationZ.keyframes))
      opacity = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: transform.opacity.keyframes))
      skew = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: transform.skew.keyframes))
      skewAxis = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: transform.skewAxis.keyframes))
    } else {
      /// NETransform node missing. Default to empty transform.
      anchor = NENodeProperty(provider: NESingleValueProvider(NELottieVector3D(x: CGFloat(0), y: CGFloat(0), z: CGFloat(0))))
      position = NENodeProperty(provider: NESingleValueProvider(NELottieVector3D(x: CGFloat(0), y: CGFloat(0), z: CGFloat(0))))
      scale = NENodeProperty(provider: NESingleValueProvider(NELottieVector3D(x: CGFloat(100), y: CGFloat(100), z: CGFloat(100))))
      rotationX = NENodeProperty(provider: NESingleValueProvider(NELottieVector1D(0)))
      rotationY = NENodeProperty(provider: NESingleValueProvider(NELottieVector1D(0)))
      rotationZ = NENodeProperty(provider: NESingleValueProvider(NELottieVector1D(0)))
      opacity = NENodeProperty(provider: NESingleValueProvider(NELottieVector1D(100)))
      skew = NENodeProperty(provider: NESingleValueProvider(NELottieVector1D(0)))
      skewAxis = NENodeProperty(provider: NESingleValueProvider(NELottieVector1D(0)))
    }
    keypathProperties = [
      "Anchor Point": anchor,
      NEPropertyName.position.rawValue: position,
      NEPropertyName.scale.rawValue: scale,
      NEPropertyName.rotation.rawValue: rotationZ,
      "Rotation X": rotationX,
      "Rotation Y": rotationY,
      "Rotation Z": rotationZ,
      NEPropertyName.opacity.rawValue: opacity,
      "Skew": skew,
      "Skew Axis": skewAxis,
    ]
    properties = Array(keypathProperties.values)
  }

  // MARK: Internal

  var keypathName = "NETransform"

  var childKeypaths: [NEKeypathSearchable] = []

  let keypathProperties: [String: NEAnyNodeProperty]
  let properties: [NEAnyNodeProperty]

  let anchor: NENodeProperty<NELottieVector3D>
  let position: NENodeProperty<NELottieVector3D>
  let scale: NENodeProperty<NELottieVector3D>
  let rotationX: NENodeProperty<NELottieVector1D>
  let rotationY: NENodeProperty<NELottieVector1D>
  let rotationZ: NENodeProperty<NELottieVector1D>

  let opacity: NENodeProperty<NELottieVector1D>
  let skew: NENodeProperty<NELottieVector1D>
  let skewAxis: NENodeProperty<NELottieVector1D>

  var caTransform: CATransform3D {
    CATransform3D.makeTransform(
      anchor: anchor.value.pointValue,
      position: position.value.pointValue,
      scale: scale.value.sizeValue,
      rotationX: rotationX.value.cgFloatValue,
      rotationY: rotationY.value.cgFloatValue,
      rotationZ: rotationZ.value.cgFloatValue,
      skew: skew.value.cgFloatValue,
      skewAxis: skewAxis.value.cgFloatValue
    )
  }
}

// MARK: - NEGroupNode

final class NEGroupNode: NEAnimatorNode {
  // MARK: Lifecycle

  // MARK: Initializer

  init(name: String, parentNode: NEAnimatorNode?, tree: NENodeTree) {
    self.parentNode = parentNode
    keypathName = name
    rootNode = tree.rootNode
    properties = NEGroupNodeProperties(transform: tree.transform)
    groupOutput = NEGroupOutputNode(parent: parentNode?.outputNode, rootNode: rootNode?.outputNode)
    var childKeypaths: [NEKeypathSearchable] = tree.childrenNodes
    childKeypaths.append(properties)
    self.childKeypaths = childKeypaths

    for childContainer in tree.renderContainers {
      container.insertRenderLayer(childContainer)
    }
  }

  // MARK: Internal

  // MARK: Properties

  let groupOutput: NEGroupOutputNode

  let properties: NEGroupNodeProperties

  let rootNode: NEAnimatorNode?

  var container = NEShapeContainerLayer()

  // MARK: Keypath Searchable

  let keypathName: String

  let childKeypaths: [NEKeypathSearchable]

  let parentNode: NEAnimatorNode?
  var hasLocalUpdates = false
  var hasUpstreamUpdates = false
  var lastUpdateFrame: CGFloat? = nil

  var keypathLayer: CALayer? {
    container
  }

  // MARK: Animator Node Protocol

  var propertyMap: NENodePropertyMap & NEKeypathSearchable {
    properties
  }

  var outputNode: NENodeOutput {
    groupOutput
  }

  var isEnabled = true {
    didSet {
      container.isHidden = !isEnabled
    }
  }

  func performAdditionalLocalUpdates(frame: CGFloat, forceLocalUpdate: Bool) -> Bool {
    rootNode?.updateContents(frame, forceLocalUpdate: forceLocalUpdate) ?? false
  }

  func performAdditionalOutputUpdates(_ frame: CGFloat, forceOutputUpdate: Bool) {
    rootNode?.updateOutputs(frame, forceOutputUpdate: forceOutputUpdate)
  }

  func rebuildOutputs(frame: CGFloat) {
    container.opacity = Float(properties.opacity.value.cgFloatValue) * 0.01
    container.transform = properties.caTransform
    groupOutput.setTransform(container.transform, forFrame: frame)
  }
}
