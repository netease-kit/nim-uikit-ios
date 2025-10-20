// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics
import Foundation

// MARK: - NEGradientStrokeProperties

final class NEGradientStrokeProperties: NENodePropertyMap, NEKeypathSearchable {
  // MARK: Lifecycle

  init(gradientStroke: NEGradientStroke) {
    keypathName = gradientStroke.name
    opacity = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: gradientStroke.opacity.keyframes))
    startPoint = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: gradientStroke.startPoint.keyframes))
    endPoint = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: gradientStroke.endPoint.keyframes))
    colors = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: gradientStroke.colors.keyframes))
    gradientType = gradientStroke.gradientType
    numberOfColors = gradientStroke.numberOfColors
    width = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: gradientStroke.width.keyframes))
    miterLimit = CGFloat(gradientStroke.miterLimit)
    lineCap = gradientStroke.lineCap
    lineJoin = gradientStroke.lineJoin

    if let dashes = gradientStroke.dashPattern {
      var dashPatterns = ContiguousArray<ContiguousArray<NEKeyframe<NELottieVector1D>>>()
      var dashPhase = ContiguousArray<NEKeyframe<NELottieVector1D>>()
      for dash in dashes {
        if dash.type == .offset {
          dashPhase = dash.value.keyframes
        } else {
          dashPatterns.append(dash.value.keyframes)
        }
      }
      dashPattern = NENodeProperty(provider: NEGroupInterpolator(keyframeGroups: dashPatterns))
      self.dashPhase = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: dashPhase))
    } else {
      dashPattern = NENodeProperty(provider: NESingleValueProvider([NELottieVector1D]()))
      dashPhase = NENodeProperty(provider: NESingleValueProvider(NELottieVector1D(0)))
    }
    keypathProperties = [
      NEPropertyName.opacity.rawValue: opacity,
      "Start Point": startPoint,
      "End Point": endPoint,
      NEPropertyName.gradientColors.rawValue: colors,
      NEPropertyName.strokeWidth.rawValue: width,
      "Dashes": dashPattern,
      "Dash Phase": dashPhase,
    ]
    properties = Array(keypathProperties.values)
  }

  // MARK: Internal

  var keypathName: String

  let opacity: NENodeProperty<NELottieVector1D>
  let startPoint: NENodeProperty<NELottieVector3D>
  let endPoint: NENodeProperty<NELottieVector3D>
  let colors: NENodeProperty<[Double]>
  let width: NENodeProperty<NELottieVector1D>

  let dashPattern: NENodeProperty<[NELottieVector1D]>
  let dashPhase: NENodeProperty<NELottieVector1D>

  let lineCap: NELineCap
  let lineJoin: NELineJoin
  let miterLimit: CGFloat
  let gradientType: NEGradientType
  let numberOfColors: Int

  let keypathProperties: [String: NEAnyNodeProperty]
  let properties: [NEAnyNodeProperty]
}

// MARK: - NEGradientStrokeNode

final class NEGradientStrokeNode: NEAnimatorNode, NERenderNode {
  // MARK: Lifecycle

  init(parentNode: NEAnimatorNode?, gradientStroke: NEGradientStroke) {
    strokeRender = NEGradientStrokeRenderer(parent: parentNode?.outputNode)
    strokeProperties = NEGradientStrokeProperties(gradientStroke: gradientStroke)
    self.parentNode = parentNode
  }

  // MARK: Internal

  let strokeRender: NEGradientStrokeRenderer

  let strokeProperties: NEGradientStrokeProperties

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
    /// Update gradient properties
    strokeRender.gradientRender.start = strokeProperties.startPoint.value.pointValue
    strokeRender.gradientRender.end = strokeProperties.endPoint.value.pointValue
    strokeRender.gradientRender.opacity = strokeProperties.opacity.value.cgFloatValue
    strokeRender.gradientRender.colors = strokeProperties.colors.value.map { CGFloat($0) }
    strokeRender.gradientRender.type = strokeProperties.gradientType
    strokeRender.gradientRender.numberOfColors = strokeProperties.numberOfColors

    /// Now update stroke properties
    strokeRender.strokeRender.opacity = strokeProperties.opacity.value.cgFloatValue
    strokeRender.strokeRender.width = strokeProperties.width.value.cgFloatValue
    strokeRender.strokeRender.miterLimit = strokeProperties.miterLimit
    strokeRender.strokeRender.lineCap = strokeProperties.lineCap
    strokeRender.strokeRender.lineJoin = strokeProperties.lineJoin

    /// Get dash lengths
    let dashLengths = strokeProperties.dashPattern.value.map { $0.cgFloatValue }
    if dashLengths.count > 0, dashLengths.isSupportedLayerDashPattern {
      strokeRender.strokeRender.dashPhase = strokeProperties.dashPhase.value.cgFloatValue
      strokeRender.strokeRender.dashLengths = dashLengths
    } else {
      strokeRender.strokeRender.dashLengths = nil
      strokeRender.strokeRender.dashPhase = nil
    }
  }
}
