// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

extension NELineJoin {
  var cgLineJoin: CGLineJoin {
    switch self {
    case .bevel:
      return .bevel
    case .none:
      return .miter
    case .miter:
      return .miter
    case .round:
      return .round
    }
  }

  var caLineJoin: CAShapeLayerLineJoin {
    switch self {
    case .none:
      return CAShapeLayerLineJoin.miter
    case .miter:
      return CAShapeLayerLineJoin.miter
    case .round:
      return CAShapeLayerLineJoin.round
    case .bevel:
      return CAShapeLayerLineJoin.bevel
    }
  }
}

extension NELineCap {
  var cgLineCap: CGLineCap {
    switch self {
    case .none:
      return .butt
    case .butt:
      return .butt
    case .round:
      return .round
    case .square:
      return .square
    }
  }

  var caLineCap: CAShapeLayerLineCap {
    switch self {
    case .none:
      return CAShapeLayerLineCap.butt
    case .butt:
      return CAShapeLayerLineCap.butt
    case .round:
      return CAShapeLayerLineCap.round
    case .square:
      return CAShapeLayerLineCap.square
    }
  }
}

// MARK: - NEStrokeRenderer

/// A rendered that renders a stroke on a path.
final class NEStrokeRenderer: NEPassThroughOutputNode, NERenderable {
  var shouldRenderInContext = false

  var color: CGColor? {
    didSet {
      hasUpdate = true
    }
  }

  var opacity: CGFloat = 0 {
    didSet {
      hasUpdate = true
    }
  }

  var width: CGFloat = 0 {
    didSet {
      hasUpdate = true
    }
  }

  var miterLimit: CGFloat = 0 {
    didSet {
      hasUpdate = true
    }
  }

  var lineCap: NELineCap = .none {
    didSet {
      hasUpdate = true
    }
  }

  var lineJoin: NELineJoin = .none {
    didSet {
      hasUpdate = true
    }
  }

  var dashPhase: CGFloat? {
    didSet {
      hasUpdate = true
    }
  }

  var dashLengths: [CGFloat]? {
    didSet {
      hasUpdate = true
    }
  }

  func setupSublayers(layer _: CAShapeLayer) {
    // empty
  }

  func renderBoundsFor(_ boundingBox: CGRect) -> CGRect {
    boundingBox.insetBy(dx: -width, dy: -width)
  }

  func setupForStroke(_ inContext: CGContext) {
    inContext.setLineWidth(width)
    inContext.setMiterLimit(miterLimit)
    inContext.setLineCap(lineCap.cgLineCap)
    inContext.setLineJoin(lineJoin.cgLineJoin)
    if let dashPhase, let lengths = dashLengths {
      inContext.setLineDash(phase: dashPhase, lengths: lengths)
    } else {
      inContext.setLineDash(phase: 0, lengths: [])
    }
  }

  func render(_ inContext: CGContext) {
    guard inContext.path != nil, inContext.path!.isEmpty == false else {
      return
    }
    guard let color else { return }
    hasUpdate = false
    setupForStroke(inContext)
    inContext.setAlpha(opacity)
    inContext.setStrokeColor(color)
    inContext.strokePath()
  }

  func updateShapeLayer(layer: CAShapeLayer) {
    layer.strokeColor = color
    layer.opacity = Float(opacity)
    layer.lineWidth = width
    layer.lineJoin = lineJoin.caLineJoin
    layer.lineCap = lineCap.caLineCap
    layer.lineDashPhase = dashPhase ?? 0
    layer.fillColor = nil
    if let dashPattern = dashLengths {
      layer.lineDashPattern = dashPattern.map { NSNumber(value: Double($0)) }
    }
  }
}
