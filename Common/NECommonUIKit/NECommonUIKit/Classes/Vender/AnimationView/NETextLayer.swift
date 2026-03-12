// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

/// The `CALayer` type responsible for rendering `NETextLayer`s
final class NETextLayer: NEBaseCompositionLayer {
  // MARK: Lifecycle

  init(textLayerModel: NETextLayerModel,
       context: NELayerContext)
    throws {
    self.textLayerModel = textLayerModel
    super.init(layerModel: textLayerModel)
    setupSublayers()
    try configureRenderLayer(with: context)
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

    textLayerModel = typedLayer.textLayerModel
    super.init(layer: typedLayer)
  }

  // MARK: Internal

  override func setupAnimations(context: NELayerAnimationContext) throws {
    try super.setupAnimations(context: context)
    let textAnimationContext = context.addingKeypathComponent(textLayerModel.name)

    let sourceText = try textLayerModel.text.exactlyOneKeyframe(
      context: textAnimationContext,
      description: "text layer text"
    )

    // Prior to Lottie 4.3.0 the Core Animation rendering engine always just used `NELegacyAnimationTextProvider`
    // but incorrectly called it with the full keypath string, unlike the Main Thread rendering engine
    // which only used the last component of the keypath. Starting in Lottie 4.3.0 we use `NEAnimationKeypathTextProvider`
    // instead if implemented.
    if let keypathTextValue = context.textProvider.text(for: textAnimationContext.currentKeypath, sourceText: sourceText.text) {
      renderLayer.text = keypathTextValue
    } else if let legacyTextProvider = context.textProvider as? NELegacyAnimationTextProvider {
      renderLayer.text = legacyTextProvider.textFor(
        keypathName: textAnimationContext.currentKeypath.fullPath,
        sourceText: sourceText.text
      )
    } else {
      renderLayer.text = sourceText.text
    }

    renderLayer.sizeToFit()
  }

  func configureRenderLayer(with context: NELayerContext) throws {
    // We can't use `CATextLayer`, because it doesn't support enough features we use.
    // Instead, we use the same `NECoreTextRenderLayer` (with a custom `draw` implementation)
    // used by the Main Thread rendering engine. This means the Core Animation engine can't
    // _animate_ text properties, but it can display static text without any issues.
    let text = try textLayerModel.text.exactlyOneKeyframe(context: context, description: "text layer text")

    // The Core Animation engine doesn't currently support `NETextAnimator`s.
    //  - We could add support for animating the transform-related properties without much trouble.
    //  - We may be able to support animating `fillColor` by getting clever with layer blend modes
    //    or masks (e.g. use `NECoreTextRenderLayer` to draw black glyphs, and then fill them in
    //    using a `CAShapeLayer`).
    if !textLayerModel.animators.isEmpty {
      try context.logCompatibilityIssue("""
      The Core Animation rendering engine currently doesn't support text animators.
      """)
    }

    renderLayer.font = context.fontProvider.fontFor(family: text.fontFamily, size: CGFloat(text.fontSize))

    renderLayer.alignment = text.justification.textAlignment
    renderLayer.lineHeight = CGFloat(text.lineHeight)
    renderLayer.tracking = (CGFloat(text.fontSize) * CGFloat(text.tracking)) / 1000

    renderLayer.fillColor = text.fillColorData?.cgColorValue
    renderLayer.strokeColor = text.strokeColorData?.cgColorValue
    renderLayer.strokeWidth = CGFloat(text.strokeWidth ?? 0)
    renderLayer.strokeOnTop = text.strokeOverFill ?? false

    renderLayer.preferredSize = text.textFrameSize?.sizeValue
    renderLayer.sizeToFit()

    renderLayer.transform = CATransform3DIdentity
    renderLayer.position = text.textFramePosition?.pointValue ?? .zero
  }

  // MARK: Private

  private let textLayerModel: NETextLayerModel
  private let renderLayer = NECoreTextRenderLayer()

  private func setupSublayers() {
    // Place the text render layer in an additional container
    //  - Direct sublayers of a `NEBaseCompositionLayer` always fill the bounds
    //    of their superlayer -- so this container will be the bounds of self,
    //    and the text render layer can be positioned anywhere.
    let textContainerLayer = CALayer()
    textContainerLayer.addSublayer(renderLayer)
    addSublayer(textContainerLayer)
  }
}
