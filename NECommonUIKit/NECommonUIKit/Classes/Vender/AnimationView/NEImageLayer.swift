// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NEImageLayer

/// The `CALayer` type responsible for rendering `NEImageLayerModel`s
final class NEImageLayer: NEBaseCompositionLayer {
  // MARK: Lifecycle

  init(imageLayer: NEImageLayerModel,
       context: NELayerContext) {
    self.imageLayer = imageLayer
    super.init(layerModel: imageLayer)
    setupImage(context: context)
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

    imageLayer = typedLayer.imageLayer
    super.init(layer: typedLayer)
  }

  // MARK: Internal

  func setupImage(context: NELayerContext) {
    guard
      let imageAsset = context.animation.assetLibrary?.imageAssets[imageLayer.referenceID],
      let image = context.imageProvider.imageForAsset(asset: imageAsset)
    else {
      self.imageAsset = nil
      contentsLayer.contents = nil
      return
    }

    self.imageAsset = imageAsset
    contentsLayer.contents = image
    contentsLayer.contentsGravity = context.imageProvider.contentsGravity(for: imageAsset)
    setNeedsLayout()
  }

  // MARK: Private

  private let imageLayer: NEImageLayerModel
  private var imageAsset: NEImageAsset?
}

// MARK: NECustomLayoutLayer

extension NEImageLayer: NECustomLayoutLayer {
  func layout(superlayerBounds: CGRect) {
    anchorPoint = .zero

    guard let imageAsset else {
      bounds = superlayerBounds
      return
    }

    // Image layers specifically need to use the size of the image itself
    bounds = CGRect(
      x: superlayerBounds.origin.x,
      y: superlayerBounds.origin.y,
      width: CGFloat(imageAsset.width),
      height: CGFloat(imageAsset.height)
    )
  }
}
