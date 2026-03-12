// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

/// The base layer that holds Shapes and NEShape Renderers
class NEShapeContainerLayer: CALayer {
  // MARK: Lifecycle

  override init() {
    super.init()
    actions = [
      "position": NSNull(),
      "bounds": NSNull(),
      "anchorPoint": NSNull(),
      "transform": NSNull(),
      "opacity": NSNull(),
      "hidden": NSNull(),
    ]
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override init(layer: Any) {
    guard let layer = layer as? NEShapeContainerLayer else {
      fatalError("init(layer:) wrong class.")
    }
    super.init(layer: layer)
  }

  // MARK: Internal

  private(set) var renderLayers: [NEShapeContainerLayer] = []

  var renderScale: CGFloat = 1 {
    didSet {
      updateRenderScale()
    }
  }

  func insertRenderLayer(_ layer: NEShapeContainerLayer) {
    renderLayers.append(layer)
    insertSublayer(layer, at: 0)
  }

  func markRenderUpdates(forFrame: CGFloat) {
    if hasRenderUpdate(forFrame: forFrame) {
      rebuildContents(forFrame: forFrame)
    }
    guard isHidden == false else { return }
    for renderLayer in renderLayers {
      renderLayer.markRenderUpdates(forFrame: forFrame)
    }
  }

  func hasRenderUpdate(forFrame _: CGFloat) -> Bool {
    false
  }

  func rebuildContents(forFrame _: CGFloat) {
    /// Override
  }

  func updateRenderScale() {
    contentsScale = renderScale
    for renderLayer in renderLayers {
      renderLayer.renderScale = renderScale
    }
  }
}
