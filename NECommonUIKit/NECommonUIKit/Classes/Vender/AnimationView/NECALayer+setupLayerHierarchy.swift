
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

extension CALayer {
  // MARK: Internal

  /// Sets up an `NEAnimationLayer` / `CALayer` hierarchy in this layer,
  /// using the given list of layers.
  @nonobjc
  func neSetupLayerHierarchy(for layers: [NELayerModel],
                             context: NELayerContext)
    throws {
    // A `NELottieAnimation`'s `NELayerModel`s are listed from front to back,
    // but `CALayer.sublayers` are listed from back to front.
    // We reverse the layer ordering to match what Core Animation expects.
    // The final view hierarchy must display the layers in this exact order.
    let layersInZAxisOrder = layers.reversed()

    let layersByIndex = Dictionary(grouping: layersInZAxisOrder, by: \.index)
      .compactMapValues(\.first)

    /// Layers specify a `parent` layer. Child layers inherit the `transform` of their parent.
    ///  - We can't add the child as a sublayer of the parent `CALayer`, since that would
    ///    break the ordering specified in `layersInZAxisOrder`.
    ///  - Instead, we create an invisible `NETransformLayer` to handle the parent
    ///    transform animations, and add the child layer to that `NETransformLayer`.
    func neMakeParentTransformLayer(childLayerModel: NELayerModel,
                                    childLayer: CALayer,
                                    name: (NELayerModel) -> String)
      -> CALayer {
      guard
        let parentIndex = childLayerModel.parent,
        let parentLayerModel = layersByIndex[parentIndex]
      else { return childLayer }

      let parentLayer = NETransformLayer(layerModel: parentLayerModel)
      parentLayer.name = name(parentLayerModel)
      parentLayer.addSublayer(childLayer)

      return neMakeParentTransformLayer(
        childLayerModel: parentLayerModel,
        childLayer: parentLayer,
        name: name
      )
    }

    // Create an `NEAnimationLayer` for each `NELayerModel`
    for (layerModel, mask) in try layersInZAxisOrder.nePairedLayersAndMasks() {
      guard let layer = try layerModel.makeAnimationLayer(context: context) else {
        continue
      }

      // If this layer has a `parent`, we create an invisible `NETransformLayer`
      // to handle displaying / animating the parent transform.
      let parentTransformLayer = neMakeParentTransformLayer(
        childLayerModel: layerModel,
        childLayer: layer,
        name: { parentLayerModel in
          "\(layerModel.name) (parent, \(parentLayerModel.name))"
        }
      )

      // Create the `mask` layer for this layer, if it has a `NEMatteType`
      if
        let mask,
        let maskLayer = try neMaskLayer(for: mask.model, type: mask.matteType, context: context) {
        let maskParentTransformLayer = neMakeParentTransformLayer(
          childLayerModel: mask.model,
          childLayer: maskLayer,
          name: { parentLayerModel in
            "\(mask.model.name) (mask of \(layerModel.name)) (parent, \(parentLayerModel.name))"
          }
        )

        // Set up a parent container to host both the layer
        // and its mask in the same coordinate space
        let maskContainer = NEBaseAnimationLayer()
        maskContainer.name = "\(layerModel.name) (parent, masked)"
        maskContainer.addSublayer(parentTransformLayer)

        // Core Animation will silently fail to apply a mask if a `mask` layer
        // itself _also_ has a `mask`. As a workaround, we can wrap this layer's
        // mask in an additional container layer which never has its own `mask`.
        let additionalMaskParent = NEBaseAnimationLayer()
        additionalMaskParent.addSublayer(maskParentTransformLayer)
        maskContainer.mask = additionalMaskParent

        addSublayer(maskContainer)
      }

      else {
        addSublayer(parentTransformLayer)
      }
    }
  }

  // MARK: Fileprivate

  /// Creates a mask `CALayer` from the given matte layer model, using the `MatteType`
  /// from the layer that is being masked.
  fileprivate func neMaskLayer(for matteLayerModel: NELayerModel,
                               type: NEMatteType,
                               context: NELayerContext)
    throws -> CALayer? {
    switch type {
    case .add:
      return try matteLayerModel.makeAnimationLayer(context: context)

    case .invert:
      guard let maskLayer = try matteLayerModel.makeAnimationLayer(context: context) else {
        return nil
      }

      // We can invert the mask layer by having a large solid black layer with the
      // given mask layer subtracted out using the `xor` blend mode. When applied to the
      // layer being masked, this creates an inverted mask where only areas _outside_
      // of the mask layer are visible.
      // https://developer.apple.com/documentation/coregraphics/cgblendMode/xor
      //  - The inverted mask is supposed to expand infinitely around the shape,
      //    so we use `NEInfiniteOpaqueAnimationLayer`
      let base = NEInfiniteOpaqueAnimationLayer()
      base.backgroundColor = .neRgb(0, 0, 0)
      base.addSublayer(maskLayer)
      maskLayer.compositingFilter = "xor"
      return base

    case .none, .unknown:
      return nil
    }
  }
}

private extension Collection<NELayerModel> {
  /// Pairs each `NELayerModel` within this array with
  /// a `NELayerModel` to use as its mask, if applicable
  /// based on the layer's `NEMatteType` configuration.
  ///  - Assumes the layers are sorted in z-axis order.
  func nePairedLayersAndMasks() throws
    -> [(layer: NELayerModel, mask: (model: NELayerModel, matteType: NEMatteType)?)] {
    var layersAndMasks = [(layer: NELayerModel, mask: (model: NELayerModel, matteType: NEMatteType)?)]()
    var unprocessedLayers = reversed()

    while let layer = unprocessedLayers.popLast() {
      /// If a layer has a `NEMatteType`, then the next layer will be used as its `mask`
      if
        let matteType = layer.matte,
        matteType != .none,
        let maskLayer = unprocessedLayers.popLast() {
        layersAndMasks.append((layer: layer, mask: (model: maskLayer, matteType: matteType)))
      }

      else {
        layersAndMasks.append((layer: layer, mask: nil))
      }
    }

    return layersAndMasks
  }
}
