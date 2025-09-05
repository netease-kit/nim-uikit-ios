
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics
import Foundation

extension [NELayerModel] {
  func initializeCompositionLayers(assetLibrary: NEAssetLibrary?,
                                   layerImageProvider: NELayerImageProvider,
                                   layerTextProvider: NELayerTextProvider,
                                   textProvider: NEAnimationKeypathTextProvider,
                                   fontProvider: NEAnimationFontProvider,
                                   frameRate: CGFloat,
                                   rootAnimationLayer: NEMainThreadAnimationLayer?)
    -> [NECompositionLayer] {
    var compositionLayers = [NECompositionLayer]()
    var layerMap = [Int: NECompositionLayer]()

    /// Organize the assets into a dictionary of [ID : NEImageAsset]
    var childLayers = [NELayerModel]()

    for layer in self {
      if layer.hidden == true {
        let genericLayer = NENullCompositionLayer(layer: layer)
        compositionLayers.append(genericLayer)
        layerMap[layer.index] = genericLayer
      } else if let shapeLayer = layer as? NEShapeLayerModel {
        let shapeContainer = NEShapeCompositionLayer(shapeLayer: shapeLayer)
        compositionLayers.append(shapeContainer)
        layerMap[layer.index] = shapeContainer
      } else if let solidLayer = layer as? NESolidLayerModel {
        let solidContainer = NESolidCompositionLayer(solid: solidLayer)
        compositionLayers.append(solidContainer)
        layerMap[layer.index] = solidContainer
      } else if
        let precompLayer = layer as? NEPreCompLayerModel,
        let assetLibrary,
        let precompAsset = assetLibrary.precompAssets[precompLayer.referenceID] {
        let precompContainer = NEPreCompositionLayer(
          precomp: precompLayer,
          asset: precompAsset,
          layerImageProvider: layerImageProvider,
          layerTextProvider: layerTextProvider,
          textProvider: textProvider,
          fontProvider: fontProvider,
          assetLibrary: assetLibrary,
          frameRate: frameRate,
          rootAnimationLayer: rootAnimationLayer
        )
        compositionLayers.append(precompContainer)
        layerMap[layer.index] = precompContainer
      } else if
        let imageLayer = layer as? NEImageLayerModel,
        let assetLibrary,
        let imageAsset = assetLibrary.imageAssets[imageLayer.referenceID] {
        let imageContainer = NEImageCompositionLayer(
          imageLayer: imageLayer,
          size: CGSize(width: imageAsset.width, height: imageAsset.height)
        )
        compositionLayers.append(imageContainer)
        layerMap[layer.index] = imageContainer
      } else if let textLayer = layer as? NETextLayerModel {
        let textContainer = NETextCompositionLayer(
          textLayer: textLayer,
          textProvider: textProvider,
          fontProvider: fontProvider,
          rootAnimationLayer: rootAnimationLayer
        )
        compositionLayers.append(textContainer)
        layerMap[layer.index] = textContainer
      } else {
        let genericLayer = NENullCompositionLayer(layer: layer)
        compositionLayers.append(genericLayer)
        layerMap[layer.index] = genericLayer
      }
      if layer.parent != nil {
        childLayers.append(layer)
      }
    }

    /// Now link children with their parents
    for layerModel in childLayers {
      if let parentID = layerModel.parent {
        let childLayer = layerMap[layerModel.index]
        let parentLayer = layerMap[parentID]
        childLayer?.transformNode.parentNode = parentLayer?.transformNode
      }
    }

    return compositionLayers
  }
}
