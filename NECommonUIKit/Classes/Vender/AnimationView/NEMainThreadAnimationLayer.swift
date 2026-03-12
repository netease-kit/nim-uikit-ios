// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NEMainThreadAnimationLayer

/// The base `CALayer` for the Main Thread rendering engine
///
/// This layer holds a single composition container and allows for animation of
/// the currentFrame property.
final class NEMainThreadAnimationLayer: CALayer, NERootAnimationLayer {
  // MARK: Lifecycle

  init(animation: NELottieAnimation,
       imageProvider: NEAnimationImageProvider,
       textProvider: NEAnimationKeypathTextProvider,
       fontProvider: NEAnimationFontProvider,
       maskAnimationToBounds: Bool,
       logger: NELottieLogger) {
    layerImageProvider = NELayerImageProvider(imageProvider: imageProvider, assets: animation.assetLibrary?.imageAssets)
    layerTextProvider = NELayerTextProvider(textProvider: textProvider)
    layerFontProvider = NELayerFontProvider(fontProvider: fontProvider)
    animationLayers = []
    self.logger = logger
    super.init()
    masksToBounds = maskAnimationToBounds
    bounds = animation.bounds
    let layers = animation.layers.initializeCompositionLayers(
      assetLibrary: animation.assetLibrary,
      layerImageProvider: layerImageProvider,
      layerTextProvider: layerTextProvider,
      textProvider: textProvider,
      fontProvider: fontProvider,
      frameRate: CGFloat(animation.framerate),
      rootAnimationLayer: self
    )

    var imageLayers = [NEImageCompositionLayer]()
    var textLayers = [NETextCompositionLayer]()

    var mattedLayer: NECompositionLayer? = nil

    for layer in layers.reversed() {
      layer.bounds = bounds
      animationLayers.append(layer)
      if let imageLayer = layer as? NEImageCompositionLayer {
        imageLayers.append(imageLayer)
      }
      if let textLayer = layer as? NETextCompositionLayer {
        textLayers.append(textLayer)
      }
      if let matte = mattedLayer {
        /// The previous layer requires this layer to be its matte
        matte.matteLayer = layer
        mattedLayer = nil
        continue
      }
      if
        let matte = layer.matteType,
        matte == .add || matte == .invert {
        /// We have a layer that requires a matte.
        mattedLayer = layer
      }
      addSublayer(layer)
    }

    layerImageProvider.addImageLayers(imageLayers)
    layerImageProvider.reloadImages()
    layerTextProvider.addTextLayers(textLayers)
    layerTextProvider.reloadTexts()
    layerFontProvider.addTextLayers(textLayers)
    layerFontProvider.reloadTexts()
    setNeedsDisplay()
  }

  /// Called by CoreAnimation to create a shadow copy of this layer
  /// More details: https://developer.apple.com/documentation/quartzcore/calayer/1410842-init
  override init(layer: Any) {
    guard let typedLayer = layer as? Self else {
      fatalError("\(Self.self).init(layer:) incorrectly called with \(type(of: layer))")
    }

    animationLayers = []
    layerImageProvider = NELayerImageProvider(imageProvider: NEBlankImageProvider(), assets: nil)
    layerTextProvider = NELayerTextProvider(textProvider: NEDefaultTextProvider())
    layerFontProvider = NELayerFontProvider(fontProvider: NEDefaultFontProvider())
    logger = typedLayer.logger
    super.init(layer: layer)

    currentFrame = typedLayer.currentFrame
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Public

  public var respectAnimationFrameRate = false

  // MARK: CALayer Animations

  override public class func needsDisplay(forKey key: String) -> Bool {
    if key == "currentFrame" {
      return true
    }
    return super.needsDisplay(forKey: key)
  }

  override public func action(forKey event: String) -> CAAction? {
    if event == "currentFrame" {
      let animation = CABasicAnimation(keyPath: event)
      animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
      animation.fromValue = presentation()?.currentFrame
      return animation
    }
    return super.action(forKey: event)
  }

  override public func display() {
    guard Thread.isMainThread else { return }
    var newFrame: CGFloat
    if
      let animationKeys = animationKeys(),
      !animationKeys.isEmpty {
      newFrame = presentation()?.currentFrame ?? currentFrame
    } else {
      // We ignore the presentation's frame if there's no animation in the layer.
      newFrame = currentFrame
    }
    if respectAnimationFrameRate {
      newFrame = floor(newFrame)
    }
    for animationLayer in animationLayers {
      animationLayer.displayWithFrame(frame: newFrame, forceUpdates: forceDisplayUpdateOnEachFrame)
    }
  }

  // MARK: Internal

  /// The animatable Current Frame Property
  @NSManaged var currentFrame: CGFloat

  /// The parent `NELottieAnimationLayer` that manages this layer
  weak var lottieAnimationLayer: NELottieAnimationLayer?

  /// Whether or not to use `forceDisplayUpdate()` when rendering each individual frame.
  ///  - The main thread rendering engine implements optimizations to decrease the amount
  ///    of properties that have to be re-rendered on each frame. There are some cases
  ///    where this can result in bugs / incorrect behavior, so we allow it to be disabled.
  ///  - Forcing a full render on every frame will decrease performance, and is not recommended
  ///    except as a workaround to a bug in the main thread rendering engine.
  var forceDisplayUpdateOnEachFrame = false

  var animationLayers: ContiguousArray<NECompositionLayer>

  var primaryAnimationKey: NEAnimationKey {
    .managed
  }

  var isAnimationPlaying: Bool? {
    nil // this state is managed by `NELottieAnimationView`
  }

  var _animationLayers: [CALayer] {
    Array(animationLayers)
  }

  var imageProvider: NEAnimationImageProvider {
    get {
      layerImageProvider.imageProvider
    }
    set {
      layerImageProvider.imageProvider = newValue
    }
  }

  var renderScale: CGFloat = 1 {
    didSet {
      for animationLayer in animationLayers {
        animationLayer.renderScale = renderScale
      }
    }
  }

  var textProvider: NEAnimationKeypathTextProvider {
    get { layerTextProvider.textProvider }
    set { layerTextProvider.textProvider = newValue }
  }

  var fontProvider: NEAnimationFontProvider {
    get { layerFontProvider.fontProvider }
    set { layerFontProvider.fontProvider = newValue }
  }

  func reloadImages() {
    layerImageProvider.reloadImages()
  }

  func removeAnimations() {
    // no-op, since the primary animation is managed by the `NELottieAnimationView`.
  }

  /// Forces the view to update its drawing.
  func forceDisplayUpdate() {
    for animationLayer in animationLayers {
      animationLayer.displayWithFrame(frame: currentFrame, forceUpdates: true)
    }
  }

  func logHierarchyKeypaths() {
    logger.info("Lottie: Logging Animation Keypaths")

    for keypath in allHierarchyKeypaths() {
      logger.info(keypath)
    }
  }

  func allHierarchyKeypaths() -> [String] {
    animationLayers.flatMap { $0.allKeypaths() }
  }

  func setValueProvider(_ valueProvider: NEAnyValueProvider, keypath: NEAnimationKeypath) {
    for layer in animationLayers {
      if let foundProperties = layer.nodeProperties(for: keypath) {
        for property in foundProperties {
          property.setProvider(provider: valueProvider)
        }
        layer.displayWithFrame(frame: presentation()?.currentFrame ?? currentFrame, forceUpdates: true)
      }
    }
  }

  func getValue(for keypath: NEAnimationKeypath, atFrame: CGFloat?) -> Any? {
    for layer in animationLayers {
      if
        let foundProperties = layer.nodeProperties(for: keypath),
        let first = foundProperties.first {
        return first.valueProvider.value(frame: atFrame ?? currentFrame)
      }
    }
    return nil
  }

  func getOriginalValue(for keypath: NEAnimationKeypath, atFrame: NEAnimationFrameTime?) -> Any? {
    for layer in animationLayers {
      if
        let foundProperties = layer.nodeProperties(for: keypath),
        let first = foundProperties.first {
        return first.originalValueProvider.value(frame: atFrame ?? currentFrame)
      }
    }
    return nil
  }

  func layer(for keypath: NEAnimationKeypath) -> CALayer? {
    for layer in animationLayers {
      if let foundLayer = layer.layer(for: keypath) {
        return foundLayer
      }
    }
    return nil
  }

  func keypath(for layerToFind: CALayer) -> NEAnimationKeypath? {
    for layer in animationLayers {
      if let foundKeypath = layer.keypath(for: layerToFind) {
        return foundKeypath
      }
    }
    return nil
  }

  func animatorNodes(for keypath: NEAnimationKeypath) -> [NEAnimatorNode]? {
    var results = [NEAnimatorNode]()
    for layer in animationLayers {
      if let nodes = layer.animatorNodes(for: keypath) {
        results.append(contentsOf: nodes)
      }
    }
    if results.count == 0 {
      return nil
    }
    return results
  }

  // MARK: Fileprivate

  fileprivate let layerImageProvider: NELayerImageProvider
  fileprivate let layerTextProvider: NELayerTextProvider
  fileprivate let layerFontProvider: NELayerFontProvider
  fileprivate let logger: NELottieLogger
}

// MARK: - NEBlankImageProvider

private class NEBlankImageProvider: NEAnimationImageProvider {
  func imageForAsset(asset _: NEImageAsset) -> CGImage? {
    nil
  }
}
