// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NEPreCompLayer

/// The `CALayer` type responsible for rendering `NEPreCompLayerModel`s
final class NEPreCompLayer: NEBaseCompositionLayer {
  // MARK: Lifecycle

  init(preCompLayer: NEPreCompLayerModel) {
    self.preCompLayer = preCompLayer
    super.init(layerModel: preCompLayer)
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

    preCompLayer = typedLayer.preCompLayer
    super.init(layer: typedLayer)
  }

  // MARK: Internal

  let preCompLayer: NEPreCompLayerModel

  /// Post-init setup for `NEPreCompLayer`s.
  /// Should always be called after `NEPreCompLayer.init(preCompLayer:)`.
  ///
  /// This is a workaround for a hard-to-reproduce crash that was
  /// triggered when `NEPreCompLayer.init` was called reentantly. We didn't
  /// have any consistent repro steps for this crash (it happened 100% of
  /// the time for some testers, and 0% of the time for other testers),
  /// but moving this code out of `NEPreCompLayer.init` does seem to fix it.
  ///
  /// The stack trace looked like:
  ///  - `_os_unfair_lock_recursive_abort`
  ///  - `-[CALayerAccessibility__UIKit__QuartzCore dealloc]`
  ///  - `NEPreCompLayer.__allocating_init(preCompLayer:context:)` <- reentrant init call
  ///  - ...
  ///  - `CALayer.setupLayerHierarchy(for:context:)`
  ///  - `NEPreCompLayer.init(preCompLayer:context:)`
  ///
  func setup(context: NELayerContext) throws {
    try neSetupLayerHierarchy(
      for: context.animation.assetLibrary?.precompAssets[preCompLayer.referenceID]?.layers ?? [],
      context: context
    )
  }

  override func setupAnimations(context: NELayerAnimationContext) throws {
    var context = context
    context = context.addingKeypathComponent(preCompLayer.name)
    try setupLayerAnimations(context: context)

    let timeRemappingInterpolator = preCompLayer.timeRemapping.flatMap { NEKeyframeInterpolator(keyframes: $0.keyframes) }

    let contextForChildren = context
      // `timeStretch` and `startTime` are a simple linear function so can be inverted from a
      // "global time to local time" function into the simpler "local time to global time".
      .withSimpleTimeRemapping { [preCompLayer] layerLocalFrame in
        (layerLocalFrame * NEAnimationFrameTime(preCompLayer.timeStretch)) + NEAnimationFrameTime(preCompLayer.startTime)
      }
      // `timeRemappingInterpolator` is arbitrarily complex and cannot be inverted,
      // so can only be applied via `complexTimeRemapping` from global time to local time.
      .withComplexTimeRemapping(required: preCompLayer.timeRemapping != nil) { [preCompLayer] globalTime in
        if let timeRemappingInterpolator {
          let remappedLocalTime = timeRemappingInterpolator.value(frame: globalTime) as! NELottieVector1D
          return remappedLocalTime.cgFloatValue * context.animation.framerate
        } else {
          return (globalTime - preCompLayer.startTime) / preCompLayer.timeStretch
        }
      }

    try setupChildAnimations(context: contextForChildren)
  }
}

// MARK: NECustomLayoutLayer

extension NEPreCompLayer: NECustomLayoutLayer {
  func layout(superlayerBounds: CGRect) {
    anchorPoint = .zero

    // Pre-comp layers use a size specified in the layer model,
    // and clip the composition to that bounds
    bounds = CGRect(
      x: superlayerBounds.origin.x,
      y: superlayerBounds.origin.y,
      width: CGFloat(preCompLayer.width),
      height: CGFloat(preCompLayer.height)
    )

    contentsLayer.masksToBounds = true
  }
}
