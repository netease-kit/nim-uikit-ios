
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NEBaseCompositionLayer

/// The base type of `NEAnimationLayer` that can contain other `NEAnimationLayer`s
class NEBaseCompositionLayer: NEBaseAnimationLayer {
  // MARK: Lifecycle

  init(layerModel: NELayerModel) {
    baseLayerModel = layerModel
    super.init()

    setupSublayers()
    compositingFilter = layerModel.blendMode.filterName
    name = layerModel.name
    contentsLayer.name = "\(layerModel.name) (Content)"
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

    baseLayerModel = typedLayer.baseLayerModel
    super.init(layer: typedLayer)
  }

  // MARK: Internal

  /// The layer that content / sublayers should be rendered in.
  /// This is the layer that transform animations are applied to.
  let contentsLayer = NEBaseAnimationLayer()

  /// Whether or not this layer render should render any visible content
  var renderLayerContents: Bool { true }

  /// Sets up the base `NELayerModel` animations for this layer,
  /// and all child `NEAnimationLayer`s.
  ///  - Can be overridden by subclasses, which much call `super`.
  override func setupAnimations(context: NELayerAnimationContext) throws {
    let layerContext = context.addingKeypathComponent(baseLayerModel.name)
    let childContext = renderLayerContents ? layerContext : context

    try setupLayerAnimations(context: layerContext)
    try setupChildAnimations(context: childContext)
  }

  func setupLayerAnimations(context: NELayerAnimationContext) throws {
    let transformContext = context.addingKeypathComponent("NETransform")

    try contentsLayer.addTransformAnimations(for: baseLayerModel.transform, context: transformContext)

    if renderLayerContents {
      try contentsLayer.addOpacityAnimation(for: baseLayerModel.transform, context: transformContext)

      try contentsLayer.addVisibilityAnimation(
        inFrame: CGFloat(baseLayerModel.inFrame),
        outFrame: CGFloat(baseLayerModel.outFrame),
        context: context
      )

      // There are two different drop shadow schemas, either using `NEDropShadowEffect` or `NEDropShadowStyle`.
      // If both happen to be present, prefer the `NEDropShadowEffect` (which is the drop shadow schema
      // supported on other platforms).
      let dropShadowEffect = baseLayerModel.effects.first(where: { $0 is NEDropShadowEffect }) as? NEDropShadowModel
      let dropShadowStyle = baseLayerModel.styles.first(where: { $0 is NEDropShadowStyle }) as? NEDropShadowModel
      if let dropShadowModel = dropShadowEffect ?? dropShadowStyle {
        try contentsLayer.addDropShadowAnimations(for: dropShadowModel, context: context)
      }
    }
  }

  func setupChildAnimations(context: NELayerAnimationContext) throws {
    try super.setupAnimations(context: context)
  }

  override func addSublayer(_ layer: CALayer) {
    if layer === contentsLayer {
      super.addSublayer(contentsLayer)
    } else {
      contentsLayer.addSublayer(layer)
    }
  }

  // MARK: Private

  private let baseLayerModel: NELayerModel

  private func setupSublayers() {
    addSublayer(contentsLayer)

    if
      renderLayerContents,
      let masks = baseLayerModel.masks?.filter({ $0.mode != .none }),
      !masks.isEmpty {
      contentsLayer.mask = NEMaskCompositionLayer(masks: masks)
    }
  }
}
