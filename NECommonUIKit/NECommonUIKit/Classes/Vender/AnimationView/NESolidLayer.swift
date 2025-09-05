// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NESolidLayer

final class NESolidLayer: NEBaseCompositionLayer {
  // MARK: Lifecycle

  init(_ solidLayer: NESolidLayerModel) {
    self.solidLayer = solidLayer
    super.init(layerModel: solidLayer)
    setupContentLayer()
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// Called by CoreAnimation to create a shadow copy of this layer
  /// More details: https://developer.apple.com/documentation/quartzcore/calayer/1410842-init
  override init(layer: Any) {
    guard let typedLayer = layer as? Self else {
      fatalError("\(Self.self).init(layer:) incorrectly called with \(type(of: layer))")
    }

    solidLayer = typedLayer.solidLayer
    super.init(layer: typedLayer)
  }

  // MARK: Internal

  override func setupAnimations(context: NELayerAnimationContext) throws {
    try super.setupAnimations(context: context)

    var context = context
    context = context.addingKeypathComponent(solidLayer.name)

    // Even though the Lottie json schema provides a fixed `solidLayer.colorHex` value,
    // we still need to create a set of keyframes and go through the standard `CAAnimation`
    // codepath so that this value can be customized using the custom `NEValueProvider`s API.
    try shapeLayer.neAddAnimation(
      for: .fillColor,
      keyframes: NEKeyframeGroup(solidLayer.colorHex.lottieColor),
      value: { $0.cgColorValue },
      context: context
    )
  }

  // MARK: Private

  private let solidLayer: NESolidLayerModel

  /// Render the fill color in a child `CAShapeLayer`
  ///  - Using a `CAShapeLayer` specifically, instead of a `CALayer` with a `backgroundColor`,
  ///    allows the size of the fill shape to be different from `contentsLayer.size`.
  private let shapeLayer = CAShapeLayer()

  private func setupContentLayer() {
    shapeLayer.path = CGPath(rect: .init(x: 0, y: 0, width: solidLayer.width, height: solidLayer.height), transform: nil)
    addSublayer(shapeLayer)
  }
}
