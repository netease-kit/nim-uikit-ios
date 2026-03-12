
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

/// A base `CALayer` that manages the frame and animations
/// of its `sublayers` and `mask`
class NEBaseAnimationLayer: CALayer, NEAnimationLayer {
  // MARK: Internal

  override func layoutSublayers() {
    super.layoutSublayers()

    for sublayer in managedSublayers {
      sublayer.neFillBoundsOfSuperlayer()
    }
  }

  func setupAnimations(context: NELayerAnimationContext) throws {
    for childAnimationLayer in managedSublayers {
      try (childAnimationLayer as? NEAnimationLayer)?.setupAnimations(context: context)
    }
  }

  // MARK: Private

  /// All of the sublayers managed by this container
  private var managedSublayers: [CALayer] {
    (sublayers ?? []) + [mask].compactMap { $0 }
  }
}
