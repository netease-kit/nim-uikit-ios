// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

/// A layer that inverses the alpha output of its input layer.
///
/// WARNING: This is experimental and probably not very performant.
final class NEInvertedMatteLayer: CALayer, NECompositionLayerDelegate {
  // MARK: Lifecycle

  init(inputMatte: NECompositionLayer) {
    self.inputMatte = inputMatte
    super.init()
    inputMatte.layerDelegate = self
    anchorPoint = .zero
    bounds = inputMatte.bounds
    setNeedsDisplay()
  }

  override init(layer: Any) {
    guard let layer = layer as? NEInvertedMatteLayer else {
      fatalError("init(layer:) wrong class.")
    }
    inputMatte = nil
    super.init(layer: layer)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Internal

  let inputMatte: NECompositionLayer?

  func frameUpdated(frame _: CGFloat) {
    setNeedsDisplay()
    displayIfNeeded()
  }

  override func draw(in ctx: CGContext) {
    guard let inputMatte else { return }
    ctx.setFillColor(.neRgb(0, 0, 0))
    ctx.fill(bounds)
    ctx.setBlendMode(.destinationOut)
    inputMatte.render(in: ctx)
  }
}
