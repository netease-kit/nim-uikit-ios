// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - ExpandedAnimationLayer

/// A `NEBaseAnimationLayer` subclass that renders its background color
/// as if the layer is infinitely large, without affecting its bounds
/// or the bounds of its sublayers
final class NEInfiniteOpaqueAnimationLayer: NEBaseAnimationLayer {
  // MARK: Lifecycle

  override init() {
    super.init()
    addSublayer(additionalPaddingLayer)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// Called by CoreAnimation to create a shadow copy of this layer
  /// More details: https://developer.apple.com/documentation/quartzcore/calayer/1410842-init
  override init(layer: Any) {
    super.init(layer: layer)
  }

  // MARK: Internal

  override func layoutSublayers() {
    super.layoutSublayers()

    masksToBounds = false
    additionalPaddingLayer.backgroundColor = backgroundColor

    // Scale `additionalPaddingLayer` to be larger than this layer
    // by `additionalPadding` at each size, and centered at the center
    // of this layer. Since `additionalPadding` is very large, this has
    // the affect of making `additionalPaddingLayer` appear infinite.
    let scaleRatioX = (bounds.width + (CALayer.veryLargeLayerPadding * 2)) / bounds.width
    let scaleRatioY = (bounds.height + (CALayer.veryLargeLayerPadding * 2)) / bounds.height

    additionalPaddingLayer.transform = CATransform3DScale(
      CATransform3DMakeTranslation(-CALayer.veryLargeLayerPadding, -CALayer.veryLargeLayerPadding, 0),
      scaleRatioX,
      scaleRatioY,
      1
    )
  }

  // MARK: Private

  private let additionalPaddingLayer = CALayer()
}
