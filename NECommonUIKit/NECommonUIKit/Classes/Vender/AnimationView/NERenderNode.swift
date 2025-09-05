// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NERenderNode

/// A protocol that defines a node that holds render instructions
protocol NERenderNode {
  var renderer: NERenderable & NENodeOutput { get }
}

// MARK: - NERenderable

/// A protocol that defines anything with render instructions
protocol NERenderable {
  /// The last frame in which this node was updated.
  var hasUpdate: Bool { get }

  func hasRenderUpdates(_ forFrame: CGFloat) -> Bool

  /// Determines if the renderer requires a custom context for drawing.
  /// If yes the shape layer will perform a custom drawing pass.
  /// If no the shape layer will be a standard CAShapeLayer
  var shouldRenderInContext: Bool { get }

  /// Passes in the CAShapeLayer to update
  func updateShapeLayer(layer: CAShapeLayer)

  /// Asks the renderer what the renderable bounds is for the given box.
  func renderBoundsFor(_ boundingBox: CGRect) -> CGRect

  /// Opportunity for renderers to inject sublayers
  func setupSublayers(layer: CAShapeLayer)

  /// Renders the shape in a custom context
  func render(_ inContext: CGContext)
}

extension NERenderNode where Self: NEAnimatorNode {
  var outputNode: NENodeOutput {
    renderer
  }
}

extension NERenderable {
  func renderBoundsFor(_ boundingBox: CGRect) -> CGRect {
    /// Optional
    boundingBox
  }
}
