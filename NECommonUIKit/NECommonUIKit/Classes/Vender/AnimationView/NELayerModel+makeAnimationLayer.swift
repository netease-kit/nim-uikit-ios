// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NELayerContext

/// Context available when constructing an `NEAnimationLayer`
struct NELayerContext {
  let animation: NELottieAnimation
  let imageProvider: NEAnimationImageProvider
  let textProvider: NEAnimationKeypathTextProvider
  let fontProvider: NEAnimationFontProvider
  let compatibilityTracker: NECompatibilityTracker
  var layerName: String

  func forLayer(_ layer: NELayerModel) -> NELayerContext {
    var context = self
    context.layerName = layer.name
    return context
  }
}

// MARK: - NELayerModel + makeAnimationLayer

extension NELayerModel {
  /// Constructs an `NEAnimationLayer` / `CALayer` that represents this `NELayerModel`
  func makeAnimationLayer(context: NELayerContext) throws -> NEBaseCompositionLayer? {
    let context = context.forLayer(self)

    if hidden {
      return NETransformLayer(layerModel: self)
    }

    switch (type, self) {
    case let (.precomp, preCompLayerModel as NEPreCompLayerModel):
      let preCompLayer = NEPreCompLayer(preCompLayer: preCompLayerModel)
      try preCompLayer.setup(context: context)
      return preCompLayer

    case let (.solid, solidLayerModel as NESolidLayerModel):
      return NESolidLayer(solidLayerModel)

    case let (.shape, shapeLayerModel as NEShapeLayerModel):
      return try NEShapeLayer(shapeLayer: shapeLayerModel, context: context)

    case let (.image, imageLayerModel as NEImageLayerModel):
      return NEImageLayer(imageLayer: imageLayerModel, context: context)

    case let (.text, textLayerModel as NETextLayerModel):
      return try NETextLayer(textLayerModel: textLayerModel, context: context)

    case (.null, _):
      return NETransformLayer(layerModel: self)

    case (.unknown, _), (.precomp, _), (.solid, _), (.image, _), (.shape, _), (.text, _):
      return nil
    }
  }
}
