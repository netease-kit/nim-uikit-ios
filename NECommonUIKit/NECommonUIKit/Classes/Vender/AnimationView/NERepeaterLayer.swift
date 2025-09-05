// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NERepeaterLayer

/// A layer that renders a child layer at some offset using a `NERepeater`
final class NERepeaterLayer: NEBaseAnimationLayer {
  // MARK: Lifecycle

  init(repeater: NERepeater, childLayer: CALayer, index: Int) {
    repeaterTransform = NERepeaterTransform(repeater: repeater, index: index)
    super.init()
    addSublayer(childLayer)
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

    repeaterTransform = typedLayer.repeaterTransform
    super.init(layer: typedLayer)
  }

  // MARK: Internal

  override func setupAnimations(context: NELayerAnimationContext) throws {
    try super.setupAnimations(context: context)
    try addTransformAnimations(for: repeaterTransform, context: context)
  }

  // MARK: Private

  private let repeaterTransform: NERepeaterTransform
}

// MARK: - NERepeaterTransform

/// A transform model created from a `NERepeater`
private struct NERepeaterTransform {
  // MARK: Lifecycle

  init(repeater: NERepeater, index: Int) {
    anchorPoint = repeater.anchorPoint
    scale = repeater.scale

    rotationX = repeater.rotationX.map { rotation in
      NELottieVector1D(rotation.value * Double(index))
    }

    rotationY = repeater.rotationY.map { rotation in
      NELottieVector1D(rotation.value * Double(index))
    }

    rotationZ = repeater.rotationZ.map { rotation in
      NELottieVector1D(rotation.value * Double(index))
    }

    position = repeater.position.map { position in
      NELottieVector3D(
        x: position.x * Double(index),
        y: position.y * Double(index),
        z: position.z * Double(index)
      )
    }
  }

  // MARK: Internal

  let anchorPoint: NEKeyframeGroup<NELottieVector3D>
  let position: NEKeyframeGroup<NELottieVector3D>
  let rotationX: NEKeyframeGroup<NELottieVector1D>
  let rotationY: NEKeyframeGroup<NELottieVector1D>
  let rotationZ: NEKeyframeGroup<NELottieVector1D>

  let scale: NEKeyframeGroup<NELottieVector3D>
}

// MARK: NETransformModel

extension NERepeaterTransform: NETransformModel {
  var _position: NEKeyframeGroup<NELottieVector3D>? { position }
  var _positionX: NEKeyframeGroup<NELottieVector1D>? { nil }
  var _positionY: NEKeyframeGroup<NELottieVector1D>? { nil }
  var _skew: NEKeyframeGroup<NELottieVector1D>? { nil }
  var _skewAxis: NEKeyframeGroup<NELottieVector1D>? { nil }
}
