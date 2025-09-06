// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NENEGradientRenderLayer

/// A `CAGradientLayer` subclass used to render a gradient _outside_ the normal layer bounds
///
///  - `NEGradientFill.startPoint` and `NEGradientFill.endPoint` are expressed
///    with respect to the `bounds` of the `NEShapeItemLayer`.
///
///  - The gradient itself is supposed to be rendered infinitely in all directions
///    (e.g. including outside of `bounds`). This is because `NEShapeItemLayer` paths
///    don't necessarily sit within the layer's `bounds`.
///
///  - To support this, `NENEGradientRenderLayer` tracks a `gradientReferenceBounds`
///    that `startPoint` / `endPoint` are calculated relative to.
///    The _actual_ `bounds` of this layer is padded by a large amount so that
///    the gradient can be drawn outside of the `gradientReferenceBounds`.
///
final class NENEGradientRenderLayer: CAGradientLayer {
  // MARK: Internal

  /// The reference bounds within this layer that the gradient's
  /// `startPoint` and `endPoint` should be calculated relative to
  var gradientReferenceBounds: CGRect = .zero {
    didSet {
      if oldValue != gradientReferenceBounds {
        updateLayout()
      }
    }
  }

  /// Converts the given `CGPoint` within `gradientReferenceBounds`
  /// to a percentage value relative to the full `bounds` of this layer
  ///  - This converts absolute `startPoint` and `endPoint` values into
  ///    the percent-based values expected by Core Animation,
  ///    with respect to the custom bounds geometry used by this layer type.
  func percentBasedPointInBounds(from referencePoint: CGPoint) -> CGPoint {
    guard bounds.width > 0, bounds.height > 0 else {
      NELottieLogger.shared.assertionFailure("Size must be non-zero before an animation can be played")
      return .zero
    }

    let pointInBounds = CGPoint(
      x: referencePoint.x + CALayer.veryLargeLayerPadding,
      y: referencePoint.y + CALayer.veryLargeLayerPadding
    )

    return CGPoint(
      x: CGFloat(pointInBounds.x) / bounds.width,
      y: CGFloat(pointInBounds.y) / bounds.height
    )
  }

  // MARK: Private

  private func updateLayout() {
    anchorPoint = .zero

    bounds = CGRect(
      x: gradientReferenceBounds.origin.x,
      y: gradientReferenceBounds.origin.y,
      width: CALayer.veryLargeLayerPadding + gradientReferenceBounds.width + CALayer.veryLargeLayerPadding,
      height: CALayer.veryLargeLayerPadding + gradientReferenceBounds.height + CALayer.veryLargeLayerPadding
    )

    // Align the center of this layer to be at the center point of its parent layer
    let superlayerSize = superlayer?.frame.size ?? gradientReferenceBounds.size

    transform = CATransform3DMakeTranslation(
      (superlayerSize.width - bounds.width) / 2,
      (superlayerSize.height - bounds.height) / 2,
      0
    )
  }
}

// MARK: NECustomLayoutLayer

extension NENEGradientRenderLayer: NECustomLayoutLayer {
  func layout(superlayerBounds: CGRect) {
    gradientReferenceBounds = superlayerBounds

    if let gradientMask = mask as? NENEGradientRenderLayer {
      gradientMask.layout(superlayerBounds: superlayerBounds)
    }
  }
}

extension CALayer {
  /// Extra padding to add around layers that should be very large or "infinite" in size.
  /// Examples include `NENEGradientRenderLayer` and `NEInfiniteOpaqueAnimationLayer`.
  ///  - This specific value is arbitrary and can be increased if necessary.
  ///  - Theoretically this should be "infinite", to match the behavior of
  ///    `CGContext.drawLinearGradient` with `[.drawsAfterEndLocation, .drawsBeforeStartLocation]` etc.
  static let veryLargeLayerPadding: CGFloat = 10000
}
