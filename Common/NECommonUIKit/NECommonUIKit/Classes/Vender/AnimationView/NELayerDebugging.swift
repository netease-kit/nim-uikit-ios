// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NELayerDebugStyle

struct NELayerDebugStyle {
  let anchorColor: CGColor
  let boundsColor: CGColor
  let anchorWidth: CGFloat
  let boundsWidth: CGFloat
}

// MARK: - NELayerDebugging

protocol NELayerDebugging {
  var debugStyle: NELayerDebugStyle { get }
}

// MARK: - NECustomLayerDebugging

protocol NECustomLayerDebugging {
  func layerForDebugging() -> CALayer
}

// MARK: - NEDebugLayer

class NEDebugLayer: CALayer {
  init(style: NELayerDebugStyle) {
    super.init()
    zPosition = 1000
    bounds = CGRect(x: 0, y: 0, width: style.anchorWidth, height: style.anchorWidth)
    backgroundColor = style.anchorColor
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

public extension CALayer {
  @nonobjc
  func logLayerTree(withIndent: Int = 0) {
    var string = ""
    for _ in 0 ... withIndent {
      string = string + "  "
    }
    string = string + "|_" + String(describing: self)
    NELottieLogger.shared.info(string)
    if let sublayers {
      for sublayer in sublayers {
        sublayer.logLayerTree(withIndent: withIndent + 1)
      }
    }
  }
}

// MARK: - NECompositionLayer + NECustomLayerDebugging

extension NECompositionLayer: NECustomLayerDebugging {
  func layerForDebugging() -> CALayer {
    contentsLayer
  }
}

extension CALayer {
  @nonobjc
  func setDebuggingState(visible: Bool) {
    var sublayers = sublayers
    if let cust = self as? NECustomLayerDebugging {
      sublayers = cust.layerForDebugging().sublayers
    }

    if let sublayers {
      for i in 0 ..< sublayers.count {
        if let debugLayer = sublayers[i] as? NEDebugLayer {
          debugLayer.removeFromSuperlayer()
          break
        }
      }
    }

    if let sublayers {
      for sublayer in sublayers {
        sublayer.setDebuggingState(visible: visible)
      }
    }

    if visible {
      let style: NELayerDebugStyle
      if let layerDebugging = self as? NELayerDebugging {
        style = layerDebugging.debugStyle
      } else {
        style = NELayerDebugStyle.defaultStyle()
      }
      let debugLayer = NEDebugLayer(style: style)
      var container = self
      if let cust = self as? NECustomLayerDebugging {
        container = cust.layerForDebugging()
      }
      container.addSublayer(debugLayer)
      debugLayer.position = .zero
      borderWidth = style.boundsWidth
      borderColor = style.boundsColor
    } else {
      borderWidth = 0
      borderColor = nil
    }
  }
}

// MARK: - NEMainThreadAnimationLayer + NELayerDebugging

extension NEMainThreadAnimationLayer: NELayerDebugging {
  var debugStyle: NELayerDebugStyle {
    NELayerDebugStyle.topLayerStyle()
  }
}

// MARK: - NENullCompositionLayer + NELayerDebugging

extension NENullCompositionLayer: NELayerDebugging {
  var debugStyle: NELayerDebugStyle {
    NELayerDebugStyle.nullLayerStyle()
  }
}

// MARK: - NEShapeCompositionLayer + NELayerDebugging

extension NEShapeCompositionLayer: NELayerDebugging {
  var debugStyle: NELayerDebugStyle {
    NELayerDebugStyle.shapeLayerStyle()
  }
}

// MARK: - NEShapeRenderLayer + NELayerDebugging

extension NEShapeRenderLayer: NELayerDebugging {
  var debugStyle: NELayerDebugStyle {
    NELayerDebugStyle.shapeRenderLayerStyle()
  }
}

extension NELayerDebugStyle {
  static func defaultStyle() -> NELayerDebugStyle {
    let anchorColor = CGColor.neRgb(1, 0, 0)
    let boundsColor = CGColor.neRgb(1, 1, 0)
    return NELayerDebugStyle(
      anchorColor: anchorColor,
      boundsColor: boundsColor,
      anchorWidth: 10,
      boundsWidth: 2
    )
  }

  static func topLayerStyle() -> NELayerDebugStyle {
    let anchorColor = CGColor.neRgba(1, 0.5, 0, 0)
    let boundsColor = CGColor.neRgb(0, 1, 0)

    return NELayerDebugStyle(
      anchorColor: anchorColor,
      boundsColor: boundsColor,
      anchorWidth: 10,
      boundsWidth: 2
    )
  }

  static func nullLayerStyle() -> NELayerDebugStyle {
    let anchorColor = CGColor.neRgba(0, 0, 1, 0)
    let boundsColor = CGColor.neRgb(0, 1, 0)

    return NELayerDebugStyle(
      anchorColor: anchorColor,
      boundsColor: boundsColor,
      anchorWidth: 10,
      boundsWidth: 2
    )
  }

  static func shapeLayerStyle() -> NELayerDebugStyle {
    let anchorColor = CGColor.neRgba(0, 1, 0, 0)
    let boundsColor = CGColor.neRgb(0, 1, 0)

    return NELayerDebugStyle(
      anchorColor: anchorColor,
      boundsColor: boundsColor,
      anchorWidth: 10,
      boundsWidth: 2
    )
  }

  static func shapeRenderLayerStyle() -> NELayerDebugStyle {
    let anchorColor = CGColor.neRgba(0, 1, 1, 0)
    let boundsColor = CGColor.neRgb(0, 1, 0)

    return NELayerDebugStyle(
      anchorColor: anchorColor,
      boundsColor: boundsColor,
      anchorWidth: 10,
      boundsWidth: 2
    )
  }
}

extension [NELayerModel] {
  var parents: [Int] {
    var array = [Int]()
    for layer in self {
      if let parent = layer.parent {
        array.append(parent)
      } else {
        array.append(-1)
      }
    }
    return array
  }
}
