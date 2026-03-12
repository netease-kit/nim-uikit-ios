// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NEMaskCompositionLayer

/// The CALayer type responsible for rendering the `NEMask` of a `NEBaseCompositionLayer`
final class NEMaskCompositionLayer: CALayer {
  // MARK: Lifecycle

  init(masks: [NEMask]) {
    maskLayers = masks.map(NEMaskLayer.init(mask:))
    super.init()

    var containerLayer = NEBaseAnimationLayer()
    var firstObject = true
    for maskLayer in maskLayers {
      if maskLayer.maskModel.mode.usableMode == .none {
        continue
      } else if maskLayer.maskModel.mode.usableMode == .add || firstObject {
        firstObject = false
        containerLayer.addSublayer(maskLayer)
      } else {
        containerLayer.mask = maskLayer
        let newContainer = NEBaseAnimationLayer()
        newContainer.addSublayer(containerLayer)
        containerLayer = newContainer
      }
    }

    addSublayer(containerLayer)
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

    maskLayers = typedLayer.maskLayers
    super.init(layer: typedLayer)
  }

  // MARK: Internal

  override func layoutSublayers() {
    super.layoutSublayers()

    for sublayer in sublayers ?? [] {
      sublayer.neFillBoundsOfSuperlayer()
    }
  }

  // MARK: Private

  private let maskLayers: [NEMaskLayer]
}

// MARK: NEAnimationLayer

extension NEMaskCompositionLayer: NEAnimationLayer {
  func setupAnimations(context: NELayerAnimationContext) throws {
    for maskLayer in maskLayers {
      try maskLayer.setupAnimations(context: context)
    }
  }
}

// MARK: NEMaskCompositionLayer.NEMaskLayer

extension NEMaskCompositionLayer {
  final class NEMaskLayer: CAShapeLayer {
    // MARK: Lifecycle

    init(mask: NEMask) {
      maskModel = mask
      super.init()

      fillRule = .evenOdd
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

      maskModel = typedLayer.maskModel
      super.init(layer: typedLayer)
    }

    // MARK: Internal

    let maskModel: NEMask
  }
}

// MARK: - NEMaskCompositionLayer.NEMaskLayer + NEAnimationLayer

extension NEMaskCompositionLayer.NEMaskLayer: NEAnimationLayer {
  func setupAnimations(context: NELayerAnimationContext) throws {
    let shouldInvertMask = (maskModel.mode.usableMode == .subtract && !maskModel.inverted)
      || (maskModel.mode.usableMode == .add && maskModel.inverted)

    try addAnimations(
      for: maskModel.shape,
      context: context,
      transformPath: { maskPath in
        // If the mask is using `NEMaskMode.subtract` or has `inverted: true`,
        // we have to invert the area filled by the path. We can do that by
        // drawing a rectangle, and then adding a path (which is subtracted
        // from the rectangle based on the .evenOdd fill mode).
        if shouldInvertMask {
          let path = CGMutablePath()
          path.addRect(.veryLargeRect)
          path.addPath(maskPath)
          return path
        } else {
          return maskPath
        }
      }
    )
  }
}
