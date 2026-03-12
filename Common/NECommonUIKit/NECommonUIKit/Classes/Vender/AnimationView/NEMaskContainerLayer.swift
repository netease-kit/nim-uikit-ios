// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

extension NEMaskMode {
  var usableMode: NEMaskMode {
    switch self {
    case .add:
      return .add
    case .subtract:
      return .subtract
    case .intersect:
      return .intersect
    case .lighten:
      return .add
    case .darken:
      return .darken
    case .difference:
      return .intersect
    case .none:
      return .none
    }
  }
}

// MARK: - NEMaskContainerLayer

final class NEMaskContainerLayer: CALayer {
  // MARK: Lifecycle

  init(masks: [NEMask]) {
    super.init()
    anchorPoint = .zero
    var containerLayer = CALayer()
    var firstObject = true
    for mask in masks {
      let maskLayer = NEMaskLayer(mask: mask)
      maskLayers.append(maskLayer)
      if mask.mode.usableMode == .none {
        continue
      } else if mask.mode.usableMode == .add || firstObject {
        firstObject = false
        containerLayer.addSublayer(maskLayer)
      } else {
        containerLayer.mask = maskLayer
        let newContainer = CALayer()
        newContainer.addSublayer(containerLayer)
        containerLayer = newContainer
      }
    }
    addSublayer(containerLayer)
  }

  override init(layer: Any) {
    /// Used for creating shadow model layers. Read More here: https://developer.apple.com/documentation/quartzcore/calayer/1410842-init
    guard let layer = layer as? NEMaskContainerLayer else {
      fatalError("init(layer:) Wrong Layer Class")
    }
    super.init(layer: layer)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Internal

  func updateWithFrame(frame: CGFloat, forceUpdates: Bool) {
    for maskLayer in maskLayers {
      maskLayer.updateWithFrame(frame: frame, forceUpdates: forceUpdates)
    }
  }

  // MARK: Fileprivate

  fileprivate var maskLayers: [NEMaskLayer] = []
}

extension CGRect {
  static var veryLargeRect: CGRect {
    CGRect(
      x: -10_000_000,
      y: -10_000_000,
      width: 20_000_000,
      height: 20_000_000
    )
  }
}

// MARK: - NEMaskLayer

private class NEMaskLayer: CALayer {
  // MARK: Lifecycle

  init(mask: NEMask) {
    properties = NEMaskNodeProperties(mask: mask)
    super.init()
    addSublayer(maskLayer)
    anchorPoint = .zero
    maskLayer.fillColor = mask.mode == .add
      ? .neRgb(1, 0, 0)
      : .neRgb(0, 1, 0)
    maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
    actions = [
      "opacity": NSNull(),
    ]
  }

  override init(layer: Any) {
    properties = nil
    super.init(layer: layer)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Internal

  let properties: NEMaskNodeProperties?

  let maskLayer = CAShapeLayer()

  func updateWithFrame(frame: CGFloat, forceUpdates: Bool) {
    guard let properties else { return }
    if properties.opacity.needsUpdate(frame: frame) || forceUpdates {
      properties.opacity.update(frame: frame)
      opacity = Float(properties.opacity.value.cgFloatValue)
    }

    if properties.shape.needsUpdate(frame: frame) || forceUpdates {
      properties.shape.update(frame: frame)
      properties.expansion.update(frame: frame)

      let shapePath = properties.shape.value.cgPath()
      var path = shapePath
      if
        properties.mode.usableMode == .subtract && !properties.inverted ||
        (properties.mode.usableMode == .add && properties.inverted) {
        /// Add a bounds rect to invert the mask
        let newPath = CGMutablePath()
        newPath.addRect(CGRect.veryLargeRect)
        newPath.addPath(shapePath)
        path = newPath
      }
      maskLayer.path = path
    }
  }
}

// MARK: - NEMaskNodeProperties

private class NEMaskNodeProperties: NENodePropertyMap {
  // MARK: Lifecycle

  init(mask: NEMask) {
    mode = mask.mode
    inverted = mask.inverted
    opacity = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: mask.opacity.keyframes))
    shape = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: mask.shape.keyframes))
    expansion = NENodeProperty(provider: NEKeyframeInterpolator(keyframes: mask.expansion.keyframes))
    propertyMap = [
      NEPropertyName.opacity.rawValue: opacity,
      "NEShape": shape,
      "Expansion": expansion,
    ]
    properties = Array(propertyMap.values)
  }

  // MARK: Internal

  var propertyMap: [String: NEAnyNodeProperty]

  var properties: [NEAnyNodeProperty]

  let mode: NEMaskMode
  let inverted: Bool

  let opacity: NENodeProperty<NELottieVector1D>
  let shape: NENodeProperty<NEBezierPath>
  let expansion: NENodeProperty<NELottieVector1D>
}
