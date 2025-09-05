// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics
import Foundation

// MARK: - NEFillNodeProperties

final class NEFillNodeProperties: NENodePropertyMap, NEKeypathSearchable {
  // MARK: Lifecycle

  init(fill: NEFill) {
    keypathName = fill.name
    color = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: fill.color.keyframes))
    opacity = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: fill.opacity.keyframes))
    type = fill.fillRule
    keypathProperties = [
      NEPropertyName.opacity.rawValue: opacity,
      NEPropertyName.color.rawValue: color,
    ]
    properties = Array(keypathProperties.values)
  }

  // MARK: Internal

  var keypathName: String

  let opacity: NENodeProperty<NELottieVector1D>
  let color: NENodeProperty<NELottieColor>
  let type: NEFillRule

  let keypathProperties: [String: NEAnyNodeProperty]
  let properties: [NEAnyNodeProperty]
}

// MARK: - NEFillNode

final class NEFillNode: NEAnimatorNode, NERenderNode {
  // MARK: Lifecycle

  init(parentNode: NEAnimatorNode?, fill: NEFill) {
    fillRender = NEFillRenderer(parent: parentNode?.outputNode)
    fillProperties = NEFillNodeProperties(fill: fill)
    self.parentNode = parentNode
  }

  // MARK: Internal

  let fillRender: NEFillRenderer

  let fillProperties: NEFillNodeProperties

  let parentNode: NEAnimatorNode?
  var hasLocalUpdates = false
  var hasUpstreamUpdates = false
  var lastUpdateFrame: CGFloat? = nil

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
    fillRender.color = fillProperties.color.value.cgColorValue
    fillRender.opacity = fillProperties.opacity.value.cgFloatValue * 0.01
    fillRender.fillRule = fillProperties.type
  }
}
