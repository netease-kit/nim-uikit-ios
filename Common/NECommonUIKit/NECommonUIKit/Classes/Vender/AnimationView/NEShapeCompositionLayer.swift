// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics
import Foundation

/// A NECompositionLayer responsible for initializing and rendering shapes
final class NEShapeCompositionLayer: NECompositionLayer {
  // MARK: Lifecycle

  init(shapeLayer: NEShapeLayerModel) {
    let results = shapeLayer.items.initializeNodeTree()
    let renderContainer = NEShapeContainerLayer()
    self.renderContainer = renderContainer
    rootNode = results.rootNode
    super.init(layer: shapeLayer, size: .zero)
    contentsLayer.addSublayer(renderContainer)
    for container in results.renderContainers {
      renderContainer.insertRenderLayer(container)
    }
    rootNode?.updateTree(0, forceUpdates: true)
    childKeypaths.append(contentsOf: results.childrenNodes)
  }

  override init(layer: Any) {
    guard let layer = layer as? NEShapeCompositionLayer else {
      fatalError("init(layer:) wrong class.")
    }
    rootNode = nil
    renderContainer = nil
    super.init(layer: layer)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Internal

  let rootNode: NEAnimatorNode?
  let renderContainer: NEShapeContainerLayer?

  override func displayContentsWithFrame(frame: CGFloat, forceUpdates: Bool) {
    rootNode?.updateTree(frame, forceUpdates: forceUpdates)
    renderContainer?.markRenderUpdates(forFrame: frame)
  }

  override func updateRenderScale() {
    super.updateRenderScale()
    renderContainer?.renderScale = renderScale
  }
}
