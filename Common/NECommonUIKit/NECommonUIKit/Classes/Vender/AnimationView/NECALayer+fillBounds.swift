
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - CALayer + neFillBoundsOfSuperlayer

extension CALayer {
  /// Updates the `bounds` of this layer to fill the bounds of its `superlayer`
  /// without setting `frame` (which is not permitted if the layer can rotate)
  @nonobjc
  func neFillBoundsOfSuperlayer() {
    guard let superlayer else { return }

    if let customLayerLayer = self as? NECustomLayoutLayer {
      customLayerLayer.layout(superlayerBounds: superlayer.bounds)
    }

    else {
      // By default the `anchorPoint` of a layer is `CGPoint(x: 0.5, y: 0.5)`.
      // Setting it to `.zero` makes the layer have the same coordinate space
      // as its superlayer, which lets use use `superlayer.bounds` directly.
      anchorPoint = .zero

      bounds = superlayer.bounds
    }
  }
}

// MARK: - NECustomLayoutLayer

/// A `CALayer` that sets a custom `bounds` and `anchorPoint` relative to its superlayer
protocol NECustomLayoutLayer: CALayer {
  func layout(superlayerBounds: CGRect)
}
