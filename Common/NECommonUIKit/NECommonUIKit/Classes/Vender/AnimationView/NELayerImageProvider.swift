// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// Connects a LottieImageProvider to a group of image layers
final class NELayerImageProvider {
  // MARK: Lifecycle

  init(imageProvider: NEAnimationImageProvider, assets: [String: NEImageAsset]?) {
    self.imageProvider = imageProvider
    imageLayers = [NEImageCompositionLayer]()
    if let assets {
      imageAssets = assets
    } else {
      imageAssets = [:]
    }
    reloadImages()
  }

  // MARK: Internal

  private(set) var imageLayers: [NEImageCompositionLayer]
  let imageAssets: [String: NEImageAsset]

  var imageProvider: NEAnimationImageProvider {
    didSet {
      reloadImages()
    }
  }

  func addImageLayers(_ layers: [NEImageCompositionLayer]) {
    for layer in layers {
      if imageAssets[layer.imageReferenceID] != nil {
        /// Found a linking asset in our asset library. Add layer
        imageLayers.append(layer)
      }
    }
  }

  func reloadImages() {
    for imageLayer in imageLayers {
      if let asset = imageAssets[imageLayer.imageReferenceID] {
        imageLayer.image = imageProvider.imageForAsset(asset: asset)
        imageLayer.imageContentsGravity = imageProvider.contentsGravity(for: asset)
      }
    }
  }
}
