// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NEStrokeShapeItem

/// A `NEShapeItem` that represents a stroke
protocol NEStrokeShapeItem: NEShapeItem, NEOpacityAnimationModel {
  var strokeColor: NEKeyframeGroup<NELottieColor>? { get }
  var width: NEKeyframeGroup<NELottieVector1D> { get }
  var lineCap: NELineCap { get }
  var lineJoin: NELineJoin { get }
  var miterLimit: Double { get }
  var dashPattern: [NEDashElement]? { get }
  func copy(width: NEKeyframeGroup<NELottieVector1D>) -> NEStrokeShapeItem
}

// MARK: - NEStroke + NEStrokeShapeItem

extension NEStroke: NEStrokeShapeItem {
  var strokeColor: NEKeyframeGroup<NELottieColor>? { color }

  func copy(width: NEKeyframeGroup<NELottieVector1D>) -> NEStrokeShapeItem {
    // Type-erase the copy from `NEStroke` to `NEStrokeShapeItem`
    let copy: NEStroke = copy(width: width)
    return copy
  }
}

// MARK: - NEGradientStroke + NEStrokeShapeItem

extension NEGradientStroke: NEStrokeShapeItem {
  var strokeColor: NEKeyframeGroup<NELottieColor>? { nil }

  func copy(width: NEKeyframeGroup<NELottieVector1D>) -> NEStrokeShapeItem {
    // Type-erase the copy from `NEGradientStroke` to `NEStrokeShapeItem`
    let copy: NEGradientStroke = copy(width: width)
    return copy
  }
}

// MARK: - CAShapeLayer + NEStrokeShapeItem

extension CAShapeLayer {
  /// Adds animations for properties related to the given `NEStroke` object (`strokeColor`, `lineWidth`, etc)
  @nonobjc
  func addStrokeAnimations(for stroke: NEStrokeShapeItem, context: NELayerAnimationContext) throws {
    lineJoin = stroke.lineJoin.caLineJoin
    lineCap = stroke.lineCap.caLineCap
    miterLimit = CGFloat(stroke.miterLimit)

    if let strokeColor = stroke.strokeColor {
      try neAddAnimation(
        for: .strokeColor,
        keyframes: strokeColor,
        value: \.cgColorValue,
        context: context
      )
    }

    try neAddAnimation(
      for: .lineWidth,
      keyframes: stroke.width,
      value: \.cgFloatValue,
      context: context
    )

    try addOpacityAnimation(for: stroke, context: context)

    if let (dashPattern, dashPhase) = stroke.dashPattern?.shapeLayerConfiguration {
      let lineDashPattern = try dashPattern.map {
        try NEKeyframeGroup(keyframes: $0)
          .exactlyOneKeyframe(context: context, description: "stroke dashPattern").cgFloatValue
      }

      if lineDashPattern.isSupportedLayerDashPattern {
        self.lineDashPattern = lineDashPattern as [NSNumber]
      }

      try neAddAnimation(
        for: .lineDashPhase,
        keyframes: NEKeyframeGroup(keyframes: dashPhase),
        value: \.cgFloatValue,
        context: context
      )
    }
  }
}
