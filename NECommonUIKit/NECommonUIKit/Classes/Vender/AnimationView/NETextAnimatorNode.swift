// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NETextAnimatorNodeProperties

final class NETextAnimatorNodeProperties: NENodePropertyMap, NEKeypathSearchable {
  // MARK: Lifecycle

  init(textAnimator: NETextAnimator) {
    keypathName = textAnimator.name
    var properties = [String: NEAnyNodeProperty]()

    if let keyframeGroup = textAnimator.anchor {
      anchor = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: keyframeGroup.keyframes))
      properties["Anchor"] = anchor
    } else {
      anchor = nil
    }

    if let keyframeGroup = textAnimator.position {
      position = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: keyframeGroup.keyframes))
      properties[NEPropertyName.position.rawValue] = position
    } else {
      position = nil
    }

    if let keyframeGroup = textAnimator.scale {
      scale = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: keyframeGroup.keyframes))
      properties[NEPropertyName.scale.rawValue] = scale
    } else {
      scale = nil
    }

    if let keyframeGroup = textAnimator.skew {
      skew = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: keyframeGroup.keyframes))
      properties["Skew"] = skew
    } else {
      skew = nil
    }

    if let keyframeGroup = textAnimator.skewAxis {
      skewAxis = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: keyframeGroup.keyframes))
      properties["Skew Axis"] = skewAxis
    } else {
      skewAxis = nil
    }

    if let keyframeGroup = textAnimator.rotationX {
      rotationX = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: keyframeGroup.keyframes))
      properties["Rotation X"] = rotationX
    } else {
      rotationX = nil
    }

    if let keyframeGroup = textAnimator.rotationY {
      rotationY = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: keyframeGroup.keyframes))
      properties["Rotation Y"] = rotationY
    } else {
      rotationY = nil
    }

    if let keyframeGroup = textAnimator.rotationZ {
      rotationZ = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: keyframeGroup.keyframes))
      properties["Rotation Z"] = rotationZ
      properties[NEPropertyName.rotation.rawValue] = rotationZ
    } else {
      rotationZ = nil
    }

    if let keyframeGroup = textAnimator.opacity {
      opacity = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: keyframeGroup.keyframes))
      properties[NEPropertyName.opacity.rawValue] = opacity
    } else {
      opacity = nil
    }

    if let keyframeGroup = textAnimator.strokeColor {
      strokeColor = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: keyframeGroup.keyframes))
      properties["NEStroke Color"] = strokeColor
    } else {
      strokeColor = nil
    }

    if let keyframeGroup = textAnimator.fillColor {
      fillColor = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: keyframeGroup.keyframes))
      properties["NEFill Color"] = fillColor
    } else {
      fillColor = nil
    }

    if let keyframeGroup = textAnimator.strokeWidth {
      strokeWidth = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: keyframeGroup.keyframes))
      properties[NEPropertyName.strokeWidth.rawValue] = strokeWidth
    } else {
      strokeWidth = nil
    }

    if let keyframeGroup = textAnimator.tracking {
      tracking = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: keyframeGroup.keyframes))
      properties["Tracking"] = tracking
    } else {
      tracking = nil
    }

    keypathProperties = properties

    self.properties = Array(keypathProperties.values)
  }

  // MARK: Internal

  let keypathName: String

  let anchor: NENodeProperty<NELottieVector3D>?
  let position: NENodeProperty<NELottieVector3D>?
  let scale: NENodeProperty<NELottieVector3D>?
  let skew: NENodeProperty<NELottieVector1D>?
  let skewAxis: NENodeProperty<NELottieVector1D>?
  let rotationX: NENodeProperty<NELottieVector1D>?
  let rotationY: NENodeProperty<NELottieVector1D>?
  let rotationZ: NENodeProperty<NELottieVector1D>?
  let opacity: NENodeProperty<NELottieVector1D>?
  let strokeColor: NENodeProperty<NELottieColor>?
  let fillColor: NENodeProperty<NELottieColor>?
  let strokeWidth: NENodeProperty<NELottieVector1D>?
  let tracking: NENodeProperty<NELottieVector1D>?

  let keypathProperties: [String: NEAnyNodeProperty]
  let properties: [NEAnyNodeProperty]

  var caTransform: CATransform3D {
    CATransform3D.makeTransform(
      anchor: anchor?.value.pointValue ?? .zero,
      position: position?.value.pointValue ?? .zero,
      scale: scale?.value.sizeValue ?? CGSize(width: 100, height: 100),
      rotationX: rotationX?.value.cgFloatValue ?? 0,
      rotationY: rotationY?.value.cgFloatValue ?? 0,
      rotationZ: rotationZ?.value.cgFloatValue ?? 0,
      skew: skew?.value.cgFloatValue,
      skewAxis: skewAxis?.value.cgFloatValue
    )
  }
}

// MARK: - NETextOutputNode

final class NETextOutputNode: NENodeOutput {
  // MARK: Lifecycle

  init(parent: NETextOutputNode?) {
    parentTextNode = parent
  }

  // MARK: Internal

  var parentTextNode: NETextOutputNode?
  var isEnabled = true

  var outputPath: CGPath?

  var parent: NENodeOutput? {
    parentTextNode
  }

  var xform: CATransform3D {
    get {
      _xform ?? parentTextNode?.xform ?? CATransform3DIdentity
    }
    set {
      _xform = newValue
    }
  }

  var opacity: CGFloat {
    get {
      _opacity ?? parentTextNode?.opacity ?? 1
    }
    set {
      _opacity = newValue
    }
  }

  var strokeColor: CGColor? {
    get {
      _strokeColor ?? parentTextNode?.strokeColor
    }
    set {
      _strokeColor = newValue
    }
  }

  var fillColor: CGColor? {
    get {
      _fillColor ?? parentTextNode?.fillColor
    }
    set {
      _fillColor = newValue
    }
  }

  var tracking: CGFloat {
    get {
      _tracking ?? parentTextNode?.tracking ?? 0
    }
    set {
      _tracking = newValue
    }
  }

  var strokeWidth: CGFloat {
    get {
      _strokeWidth ?? parentTextNode?.strokeWidth ?? 0
    }
    set {
      _strokeWidth = newValue
    }
  }

  func hasOutputUpdates(_: CGFloat) -> Bool {
    // TODO: Fix This
    true
  }

  // MARK: Fileprivate

  fileprivate var _xform: CATransform3D?
  fileprivate var _opacity: CGFloat?
  fileprivate var _strokeColor: CGColor?
  fileprivate var _fillColor: CGColor?
  fileprivate var _tracking: CGFloat?
  fileprivate var _strokeWidth: CGFloat?
}

// MARK: - NETextAnimatorNode

class NETextAnimatorNode: NEAnimatorNode {
  // MARK: Lifecycle

  init(parentNode: NETextAnimatorNode?, textAnimator: NETextAnimator) {
    textOutputNode = NETextOutputNode(parent: parentNode?.textOutputNode)
    textAnimatorProperties = NETextAnimatorNodeProperties(textAnimator: textAnimator)
    self.parentNode = parentNode
  }

  // MARK: Internal

  let textOutputNode: NETextOutputNode

  let textAnimatorProperties: NETextAnimatorNodeProperties

  let parentNode: NEAnimatorNode?
  var hasLocalUpdates = false
  var hasUpstreamUpdates = false
  var lastUpdateFrame: CGFloat?
  var isEnabled = true

  var outputNode: NENodeOutput {
    textOutputNode
  }

  // MARK: Animator Node Protocol

  var propertyMap: NENodePropertyMap & NEKeypathSearchable {
    textAnimatorProperties
  }

  func localUpdatesPermeateDownstream() -> Bool {
    true
  }

  func rebuildOutputs(frame _: CGFloat) {
    textOutputNode.xform = textAnimatorProperties.caTransform
    textOutputNode.opacity = (textAnimatorProperties.opacity?.value.cgFloatValue ?? 100) * 0.01
    textOutputNode.strokeColor = textAnimatorProperties.strokeColor?.value.cgColorValue
    textOutputNode.fillColor = textAnimatorProperties.fillColor?.value.cgColorValue
    textOutputNode.tracking = textAnimatorProperties.tracking?.value.cgFloatValue ?? 1
    textOutputNode.strokeWidth = textAnimatorProperties.strokeWidth?.value.cgFloatValue ?? 0
  }
}
