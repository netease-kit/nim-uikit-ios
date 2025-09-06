// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NEShapeItemLayer

/// A CALayer type that renders an array of `[NEShapeItem]`s,
/// from a `NEGroup` in a `NEShapeLayerModel`.
final class NEShapeItemLayer: NEBaseAnimationLayer {
  // MARK: Lifecycle

  /// Initializes a `NEShapeItemLayer` that renders a `NEGroup` from a `NEShapeLayerModel`
  /// - Parameters:
  ///   - shape: The `NEShapeItem` in this group that renders a `GGPath`
  ///   - otherItems: Other items in this group that affect the appearance of the shape
  init(shape: Item, otherItems: [Item], context: NELayerContext) throws {
    self.shape = shape
    self.otherItems = otherItems

    try context.compatibilityAssert(
      shape.item.drawsCGPath,
      "`NEShapeItemLayer` must contain exactly one `NEShapeItem` that draws a `GPPath`"
    )

    try context.compatibilityAssert(
      !otherItems.contains(where: { $0.item.drawsCGPath }),
      "`NEShapeItemLayer` must contain exactly one `NEShapeItem` that draws a `GPPath`"
    )

    super.init()

    setupLayerHierarchy()
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

    shape = typedLayer.shape
    otherItems = typedLayer.otherItems
    super.init(layer: typedLayer)
  }

  // MARK: Internal

  /// An item that can be displayed by this layer
  struct Item {
    /// A `NEShapeItem` that should be rendered by this layer
    let item: NEShapeItem

    /// The set of groups that this item descends from
    ///  - Due to the way `NEGroupLayer`s are setup, the original `NEShapeItem`
    ///    hierarchy from the `NEShapeLayer` data model may no longer exactly
    ///    match the hierarchy of `NEGroupLayer` / `NEShapeItemLayer`s constructed
    ///    at runtime. Since animation keypaths need to match the original
    ///    structure of the `NEShapeLayer` data model, we track that info here.
    let groupPath: [String]
  }

  override func setupAnimations(context: NELayerAnimationContext) throws {
    try super.setupAnimations(context: context)

    guard let sublayerConfiguration else { return }

    switch sublayerConfiguration.fill {
    case let .solidFill(shapeLayer):
      try setupSolidFillAnimations(shapeLayer: shapeLayer, context: context)

    case let .gradientFill(gradientLayers):
      try setupGradientFillAnimations(layers: gradientLayers, context: context)
    }

    if let gradientStrokeConfiguration = sublayerConfiguration.gradientStroke {
      try setupGradientStrokeAnimations(layers: gradientStrokeConfiguration, context: context)
    }
  }

  // MARK: Private

  private struct GradientLayers {
    /// The `CALayer` that renders the RGB components of the gradient
    let gradientColorLayer: NENEGradientRenderLayer
    /// The `CALayer` that renders the alpha components of the gradient,
    /// masking the `gradientColorLayer`
    let gradientAlphaLayer: NENEGradientRenderLayer?
    /// The `CAShapeLayer` that clips the gradient layers to the expected shape
    let shapeMaskLayer: CAShapeLayer
    /// The top-most `CAShapeLayer` used to render `NEStroke`s over the gradient if necessary
    let overlayLayer: CAShapeLayer?
  }

  /// The configuration of this layer's `fill` sublayers
  private enum FillLayerConfiguration {
    /// This layer displays a single `CAShapeLayer`
    case solidFill(CAShapeLayer)

    /// This layer displays a `NENEGradientRenderLayer` masked by a `CAShapeLayer`.
    case gradientFill(GradientLayers)
  }

  /// The `NEShapeItem` in this group that renders a `GGPath`
  private let shape: Item

  /// Other items in this group that affect the appearance of the shape
  private let otherItems: [Item]

  /// The current configuration of this layer's sublayer(s)
  private var sublayerConfiguration: (fill: FillLayerConfiguration, gradientStroke: GradientLayers?)?

  private func setupLayerHierarchy() {
    // We have to build a different layer hierarchy depending on if
    // we're rendering a gradient (a `CAGradientLayer` masked by a `CAShapeLayer`)
    // or a solid shape (a simple `CAShapeLayer`).
    let fillLayerConfiguration: FillLayerConfiguration
    if let gradientFill = otherItems.first(NEGradientFill.self) {
      fillLayerConfiguration = setupGradientFillLayerHierarchy(for: gradientFill)
    } else {
      fillLayerConfiguration = setupSolidFillLayerHierarchy()
    }

    let gradientStrokeConfiguration: GradientLayers?
    if let gradientStroke = otherItems.first(NEGradientStroke.self) {
      gradientStrokeConfiguration = setupGradientStrokeLayerHierarchy(for: gradientStroke)
    } else {
      gradientStrokeConfiguration = nil
    }

    sublayerConfiguration = (fillLayerConfiguration, gradientStrokeConfiguration)
  }

  private func setupSolidFillLayerHierarchy() -> FillLayerConfiguration {
    let shapeLayer = CAShapeLayer()
    addSublayer(shapeLayer)

    // `CAShapeLayer.fillColor` defaults to black, so we have to
    // nil out the background color if there isn't an expected fill color
    if !otherItems.contains(where: { $0.item is NEFill }) {
      shapeLayer.fillColor = nil
    }

    return .solidFill(shapeLayer)
  }

  private func setupGradientFillLayerHierarchy(
    for gradientFill: NEGradientFill)
    -> FillLayerConfiguration {
    let container = NEBaseAnimationLayer()
    let pathContainer = NEBaseAnimationLayer()

    let pathMask = CAShapeLayer()
    pathMask.fillColor = .neRgb(0, 0, 0)
    pathContainer.mask = pathMask

    let rgbGradientLayer = NENEGradientRenderLayer()
    pathContainer.addSublayer(rgbGradientLayer)
    container.addSublayer(pathContainer)

    let overlayLayer = CAShapeLayer()
    overlayLayer.fillColor = nil
    container.addSublayer(overlayLayer)

    addSublayer(container)

    let alphaGradientLayer: NENEGradientRenderLayer?
    if gradientFill.hasAlphaComponent {
      alphaGradientLayer = NENEGradientRenderLayer()
      rgbGradientLayer.mask = alphaGradientLayer
    } else {
      alphaGradientLayer = nil
    }

    return .gradientFill(GradientLayers(
      gradientColorLayer: rgbGradientLayer,
      gradientAlphaLayer: alphaGradientLayer,
      shapeMaskLayer: pathMask,
      overlayLayer: overlayLayer
    ))
  }

  private func setupGradientStrokeLayerHierarchy(
    for gradientStroke: NEGradientStroke)
    -> GradientLayers {
    let container = NEBaseAnimationLayer()

    let pathMask = CAShapeLayer()
    pathMask.fillColor = nil
    pathMask.strokeColor = .neRgb(0, 0, 0)
    container.mask = pathMask

    let rgbGradientLayer = NENEGradientRenderLayer()
    container.addSublayer(rgbGradientLayer)
    addSublayer(container)

    let alphaGradientLayer: NENEGradientRenderLayer?
    if gradientStroke.hasAlphaComponent {
      alphaGradientLayer = NENEGradientRenderLayer()
      rgbGradientLayer.mask = alphaGradientLayer
    } else {
      alphaGradientLayer = nil
    }

    return GradientLayers(
      gradientColorLayer: rgbGradientLayer,
      gradientAlphaLayer: alphaGradientLayer,
      shapeMaskLayer: pathMask,
      overlayLayer: nil
    )
  }

  private func setupSolidFillAnimations(shapeLayer: CAShapeLayer,
                                        context: NELayerAnimationContext)
    throws {
    var trimPathMultiplier: PathMultiplier? = nil
    if let (trim, context) = otherItems.first(NETrim.self, where: { !$0.isEmpty }, context: context) {
      trimPathMultiplier = try shapeLayer.addAnimations(for: trim, context: context)

      try context.compatibilityAssert(
        otherItems.first(NEFill.self) == nil,
        """
        The Core Animation rendering engine doesn't currently support applying
        trims to filled shapes (only stroked shapes).
        """
      )
    }

    try shapeLayer.addAnimations(
      for: shape.item,
      context: context.for(shape),
      pathMultiplier: trimPathMultiplier ?? 1,
      roundedCorners: otherItems.first(NERoundedCorners.self)
    )

    if let (fill, context) = otherItems.first(NEFill.self, context: context) {
      try shapeLayer.addAnimations(for: fill, context: context)
    }

    if let (stroke, context) = otherItems.first(NEStroke.self, context: context) {
      try shapeLayer.addStrokeAnimations(for: stroke, context: context)
    }
  }

  private func setupGradientFillAnimations(layers: GradientLayers,
                                           context: NELayerAnimationContext)
    throws {
    let pathLayers = [layers.shapeMaskLayer, layers.overlayLayer]
    for pathLayer in pathLayers {
      try pathLayer?.addAnimations(
        for: shape.item,
        context: context.for(shape),
        pathMultiplier: 1,
        roundedCorners: otherItems.first(NERoundedCorners.self)
      )
    }

    if let (gradientFill, context) = otherItems.first(NEGradientFill.self, context: context) {
      layers.shapeMaskLayer.fillRule = gradientFill.fillRule.caFillRule
      try layers.gradientColorLayer.addGradientAnimations(for: gradientFill, type: .rgb, context: context)
      try layers.gradientAlphaLayer?.addGradientAnimations(for: gradientFill, type: .alpha, context: context)
    }

    if let (stroke, context) = otherItems.first(NEStroke.self, context: context) {
      try layers.overlayLayer?.addStrokeAnimations(for: stroke, context: context)
    }
  }

  private func setupGradientStrokeAnimations(layers: GradientLayers,
                                             context: NELayerAnimationContext)
    throws {
    var trimPathMultiplier: PathMultiplier? = nil
    if let (trim, context) = otherItems.first(NETrim.self, context: context) {
      trimPathMultiplier = try layers.shapeMaskLayer.addAnimations(for: trim, context: context)
    }

    try layers.shapeMaskLayer.addAnimations(
      for: shape.item,
      context: context.for(shape),
      pathMultiplier: trimPathMultiplier ?? 1,
      roundedCorners: otherItems.first(NERoundedCorners.self)
    )

    if let (gradientStroke, context) = otherItems.first(NEGradientStroke.self, context: context) {
      try layers.gradientColorLayer.addGradientAnimations(for: gradientStroke, type: .rgb, context: context)
      try layers.gradientAlphaLayer?.addGradientAnimations(for: gradientStroke, type: .alpha, context: context)

      try layers.shapeMaskLayer.addStrokeAnimations(for: gradientStroke, context: context)
    }
  }
}

// MARK: - [NEShapeItem] helpers

extension [NEShapeItemLayer.Item] {
  /// The first `NEShapeItem` in this array of the given type
  func first<ItemType: NEShapeItem>(_: ItemType.Type,
                                    where condition: (ItemType) -> Bool = { _ in true },
                                    context: NELayerAnimationContext)
    -> (item: ItemType, context: NELayerAnimationContext)? {
    for item in self {
      if let match = item.item as? ItemType, condition(match) {
        return (match, context.for(item))
      }
    }

    return nil
  }

  /// The first `NEShapeItem` in this array of the given type
  func first<ItemType: NEShapeItem>(_: ItemType.Type) -> ItemType? {
    for item in self {
      if let match = item.item as? ItemType {
        return match
      }
    }

    return nil
  }
}

extension NELayerAnimationContext {
  /// An updated `LayerAnimationContext` with the`AnimationKeypath`
  /// that refers to this specific `NEShapeItem`.
  func `for`(_ item: NEShapeItemLayer.Item) -> NELayerAnimationContext {
    var context = self

    for parentGroupName in item.groupPath {
      context.currentKeypath.keys.append(parentGroupName)
    }

    context.currentKeypath.keys.append(item.item.name)
    return context
  }
}
