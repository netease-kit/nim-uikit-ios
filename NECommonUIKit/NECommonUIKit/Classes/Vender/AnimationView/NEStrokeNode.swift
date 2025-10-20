// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import QuartzCore

// MARK: - NEStrokeNodeProperties

final class NEStrokeNodeProperties: NENodePropertyMap, NEKeypathSearchable {
  // MARK: Lifecycle

  init(stroke: NEStroke) {
    keypathName = stroke.name
    color = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: stroke.color.keyframes))
    opacity = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: stroke.opacity.keyframes))
    width = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: stroke.width.keyframes))
    miterLimit = CGFloat(stroke.miterLimit)
    lineCap = stroke.lineCap
    lineJoin = stroke.lineJoin

    if let dashes = stroke.dashPattern {
      let (dashPatterns, dashPhase) = dashes.shapeLayerConfiguration
      dashPattern = NENodeProperty(provider: NEGroupInterpolator(keyframeGroups: dashPatterns))
      if dashPhase.count == 0 {
        self.dashPhase = NENodeProperty(provider: NESingleValueProvider(NELottieVector1D(0)))
      } else {
        self.dashPhase = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: dashPhase))
      }
    } else {
      dashPattern = NENodeProperty(provider: NESingleValueProvider([NELottieVector1D]()))
      dashPhase = NENodeProperty(provider: NESingleValueProvider(NELottieVector1D(0)))
    }
    keypathProperties = [
      NEPropertyName.opacity.rawValue: opacity,
      NEPropertyName.color.rawValue: color,
      NEPropertyName.strokeWidth.rawValue: width,
      "Dashes": dashPattern,
      "Dash Phase": dashPhase,
    ]
    properties = Array(keypathProperties.values)
  }

  // MARK: Internal

  let keypathName: String
  let keypathProperties: [String: NEAnyNodeProperty]
  let properties: [NEAnyNodeProperty]

  let opacity: NENodeProperty<NELottieVector1D>
  let color: NENodeProperty<NELottieColor>
  let width: NENodeProperty<NELottieVector1D>

  let dashPattern: NENodeProperty<[NELottieVector1D]>
  let dashPhase: NENodeProperty<NELottieVector1D>

  let lineCap: NELineCap
  let lineJoin: NELineJoin
  let miterLimit: CGFloat
}

// MARK: - NEStrokeNode

/// Node that manages stroking a path
final class NEStrokeNode: NEAnimatorNode, NERenderNode {
  // MARK: Lifecycle

  init(parentNode: NEAnimatorNode?, stroke: NEStroke) {
    strokeRender = NEStrokeRenderer(parent: parentNode?.outputNode)
    strokeProperties = NEStrokeNodeProperties(stroke: stroke)
    self.parentNode = parentNode
  }

  // MARK: Internal

  let strokeRender: NEStrokeRenderer

  let strokeProperties: NEStrokeNodeProperties

  let parentNode: NEAnimatorNode?
  var hasLocalUpdates = false
  var hasUpstreamUpdates = false
  var lastUpdateFrame: CGFloat?

  var renderer: NENodeOutput & NERenderable {
    strokeRender
  }

  // MARK: Animator Node Protocol

  var propertyMap: NENodePropertyMap & NEKeypathSearchable {
    strokeProperties
  }

  var isEnabled = true {
    didSet {
      strokeRender.isEnabled = isEnabled
    }
  }

  func localUpdatesPermeateDownstream() -> Bool {
    false
  }

  func rebuildOutputs(frame _: CGFloat) {
    strokeRender.color = strokeProperties.color.value.cgColorValue
    strokeRender.opacity = strokeProperties.opacity.value.cgFloatValue * 0.01
    strokeRender.width = strokeProperties.width.value.cgFloatValue
    strokeRender.miterLimit = strokeProperties.miterLimit
    strokeRender.lineCap = strokeProperties.lineCap
    strokeRender.lineJoin = strokeProperties.lineJoin

    /// Get dash lengths
    let dashLengths = strokeProperties.dashPattern.value.map { $0.cgFloatValue }
    if dashLengths.count > 0, dashLengths.isSupportedLayerDashPattern {
      strokeRender.dashPhase = strokeProperties.dashPhase.value.cgFloatValue
      strokeRender.dashLengths = dashLengths
    } else {
      strokeRender.dashLengths = nil
      strokeRender.dashPhase = nil
    }
  }
}

// MARK: - [NEDashElement] + shapeLayerConfiguration

extension [NEDashElement] {
  typealias ShapeLayerConfiguration = (
    dashPatterns: ContiguousArray<ContiguousArray<NEKeyframe<NELottieVector1D>>>,
    dashPhase: ContiguousArray<NEKeyframe<NELottieVector1D>>
  )

  /// Converts the `[NEDashElement]` data model into `lineDashPattern` and `lineDashPhase`
  /// representations usable in a `CAShapeLayer`
  var shapeLayerConfiguration: ShapeLayerConfiguration {
    var dashPatterns = ContiguousArray<ContiguousArray<NEKeyframe<NELottieVector1D>>>()
    var dashPhase = ContiguousArray<NEKeyframe<NELottieVector1D>>()
    for dash in self {
      if dash.type == .offset {
        dashPhase = dash.value.keyframes
      } else {
        dashPatterns.append(dash.value.keyframes)
      }
    }

    dashPatterns = ContiguousArray(dashPatterns.map { pattern in
      ContiguousArray(pattern.map { keyframe -> NEKeyframe<NELottieVector1D> in
        // The recommended way to create a stroke of round dots, in theory,
        // is to use a value of 0 followed by the stroke width, but for
        // some reason Core Animation incorrectly (?) renders these as pills
        // instead of circles. As a workaround, for parity with Lottie on other
        // platforms, we can change `0`s to `0.01`: https://stackoverflow.com/a/38036486
        if keyframe.value.cgFloatValue == 0 {
          return keyframe.withValue(NELottieVector1D(0.01))
        } else {
          return keyframe
        }
      })
    })

    return (dashPatterns, dashPhase)
  }
}

extension [CGFloat] {
  // If all of the items in the dash pattern are zeros, then we shouldn't attempt to render it.
  // This causes Core Animation to have extremely poor performance for some reason, even though
  // it doesn't affect the appearance of the animation.
  //  - We check for `== 0.01` instead of `== 0` because `dashPattern.shapeLayerConfiguration`
  //    converts all `0` values to `0.01` to work around a different Core Animation rendering issue.
  var isSupportedLayerDashPattern: Bool {
    !allSatisfy { $0 == 0.01 }
  }
}
