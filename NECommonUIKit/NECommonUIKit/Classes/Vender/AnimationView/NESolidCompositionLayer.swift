// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

final class NESolidCompositionLayer: NECompositionLayer {
  // MARK: Lifecycle

  init(solid: NESolidLayerModel) {
    let components = solid.colorHex.hexColorComponents()
    colorProperty =
      NENodeProperty(provider: NESingleValueProvider(NELottieColor(
        r: Double(components.red),
        g: Double(components.green),
        b: Double(components.blue),
        a: 1
      )))

    super.init(layer: solid, size: .zero)
    solidShape.path = CGPath(rect: CGRect(x: 0, y: 0, width: solid.width, height: solid.height), transform: nil)
    contentsLayer.addSublayer(solidShape)
  }

  override init(layer: Any) {
    /// Used for creating shadow model layers. Read More here: https://developer.apple.com/documentation/quartzcore/calayer/1410842-init
    guard let layer = layer as? NESolidCompositionLayer else {
      fatalError("init(layer:) Wrong Layer Class")
    }
    colorProperty = layer.colorProperty
    super.init(layer: layer)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Internal

  let colorProperty: NENodeProperty<NELottieColor>?
  let solidShape = CAShapeLayer()

  override var keypathProperties: [String: NEAnyNodeProperty] {
    guard let colorProperty else { return super.keypathProperties }
    return [NEPropertyName.color.rawValue: colorProperty]
  }

  override func displayContentsWithFrame(frame: CGFloat, forceUpdates _: Bool) {
    guard let colorProperty else { return }
    colorProperty.update(frame: frame)
    solidShape.fillColor = colorProperty.value.cgColorValue
  }
}
