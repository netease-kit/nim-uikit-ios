// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

final class NEPreCompositionLayer: NECompositionLayer {
  // MARK: Lifecycle

  init(precomp: NEPreCompLayerModel,
       asset: NEPrecompAsset,
       layerImageProvider: NELayerImageProvider,
       layerTextProvider: NELayerTextProvider,
       textProvider: NEAnimationKeypathTextProvider,
       fontProvider: NEAnimationFontProvider,
       assetLibrary: NEAssetLibrary?,
       frameRate: CGFloat,
       rootAnimationLayer: NEMainThreadAnimationLayer?) {
    animationLayers = []
    if let keyframes = precomp.timeRemapping?.keyframes {
      remappingNode = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: keyframes))
    } else {
      remappingNode = nil
    }
    self.frameRate = frameRate
    super.init(layer: precomp, size: CGSize(width: precomp.width, height: precomp.height))
    bounds = CGRect(origin: .zero, size: CGSize(width: precomp.width, height: precomp.height))
    contentsLayer.masksToBounds = true
    contentsLayer.bounds = bounds

    let layers = asset.layers.initializeCompositionLayers(
      assetLibrary: assetLibrary,
      layerImageProvider: layerImageProvider,
      layerTextProvider: layerTextProvider,
      textProvider: textProvider,
      fontProvider: fontProvider,
      frameRate: frameRate,
      rootAnimationLayer: rootAnimationLayer
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
      contentsLayer.addSublayer(layer)
    }

    childKeypaths.append(contentsOf: layers)

    layerImageProvider.addImageLayers(imageLayers)
    layerTextProvider.addTextLayers(textLayers)
  }

  override init(layer: Any) {
    /// Used for creating shadow model layers. Read More here: https://developer.apple.com/documentation/quartzcore/calayer/1410842-init
    guard let layer = layer as? NEPreCompositionLayer else {
      fatalError("init(layer:) Wrong Layer Class")
    }
    frameRate = layer.frameRate
    remappingNode = nil
    animationLayers = []

    super.init(layer: layer)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Internal

  let frameRate: CGFloat
  let remappingNode: NENodeProperty<NELottieVector1D>?

  override var keypathProperties: [String: NEAnyNodeProperty] {
    guard let remappingNode else {
      return super.keypathProperties
    }
    return ["Time Remap": remappingNode]
  }

  override func displayContentsWithFrame(frame: CGFloat, forceUpdates: Bool) {
    let localFrame: CGFloat
    if let remappingNode {
      remappingNode.update(frame: frame)
      localFrame = remappingNode.value.cgFloatValue * frameRate
    } else {
      localFrame = (frame - startFrame) / timeStretch
    }
    for animationLayer in animationLayers {
      animationLayer.displayWithFrame(frame: localFrame, forceUpdates: forceUpdates)
    }
  }

  override func updateRenderScale() {
    super.updateRenderScale()
    for animationLayer in animationLayers {
      animationLayer.renderScale = renderScale
    }
  }

  // MARK: Fileprivate

  fileprivate var animationLayers: [NECompositionLayer]
}
