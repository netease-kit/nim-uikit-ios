// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// The CALayer type responsible for only rendering the `transform` of a `NELayerModel`
final class NETransformLayer: NEBaseCompositionLayer {
  /// `NETransformLayer`s don't render any visible content,
  /// they just `transform` their sublayers
  override var renderLayerContents: Bool { false }
}
