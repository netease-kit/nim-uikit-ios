// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import QuartzCore

// MARK: - NEGradientFillProperties

final class NEGradientFillProperties: NENodePropertyMap, NEKeypathSearchable {
  // MARK: Lifecycle

  init(gradientfill: NEGradientFill) {
    keypathName = gradientfill.name
    opacity = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: gradientfill.opacity.keyframes))
    startPoint = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: gradientfill.startPoint.keyframes))
    endPoint = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: gradientfill.endPoint.keyframes))
    colors = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: gradientfill.colors.keyframes))
    gradientType = gradientfill.gradientType
    numberOfColors = gradientfill.numberOfColors
    fillRule = gradientfill.fillRule
    keypathProperties = [
      NEPropertyName.opacity.rawValue: opacity,
      "Start Point": startPoint,
      "End Point": endPoint,
      NEPropertyName.gradientColors.rawValue: colors,
    ]
    properties = Array(keypathProperties.values)
  }

  // MARK: Internal

  var keypathName: String

  let opacity: NENodeProperty<NELottieVector1D>
  let startPoint: NENodeProperty<NELottieVector3D>
  let endPoint: NENodeProperty<NELottieVector3D>
  let colors: NENodeProperty<[Double]>

  let gradientType: NEGradientType
  let numberOfColors: Int
  let fillRule: NEFillRule

  let keypathProperties: [String: NEAnyNodeProperty]
  let properties: [NEAnyNodeProperty]
}

// MARK: - NEGradientFillNode

final class NEGradientFillNode: NEAnimatorNode, NERenderNode {
  // MARK: Lifecycle

  init(parentNode: NEAnimatorNode?, gradientFill: NEGradientFill) {
    fillRender = NEGradientFillRenderer(parent: parentNode?.outputNode)
    fillProperties = NEGradientFillProperties(gradientfill: gradientFill)
    self.parentNode = parentNode
  }

  // MARK: Internal

  let fillRender: NEGradientFillRenderer

  let fillProperties: NEGradientFillProperties

  let parentNode: NEAnimatorNode?
  var hasLocalUpdates = false
  var hasUpstreamUpdates = false
  var lastUpdateFrame: CGFloat?

  var renderer: NENodeOutput & NERenderable {
    fillRender
  }

  // MARK: Animator Node Protocol

  var propertyMap: NENodePropertyMap & NEKeypathSearchable {
    fillProperties
  }

  var isEnabled = true {
    didSet {
      fillRender.isEnabled = isEnabled
    }
  }

  func localUpdatesPermeateDownstream() -> Bool {
    false
  }

  func rebuildOutputs(frame _: CGFloat) {
    fillRender.start = fillProperties.startPoint.value.pointValue
    fillRender.end = fillProperties.endPoint.value.pointValue
    fillRender.opacity = fillProperties.opacity.value.cgFloatValue * 0.01
    fillRender.colors = fillProperties.colors.value.map { CGFloat($0) }
    fillRender.type = fillProperties.gradientType
    fillRender.numberOfColors = fillProperties.numberOfColors
    fillRender.fillRule = fillProperties.fillRule.caFillRule
  }
}
