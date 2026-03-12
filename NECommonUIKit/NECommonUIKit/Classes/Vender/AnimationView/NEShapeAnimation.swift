// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

extension CAShapeLayer {
  /// Adds a `path` animation for the given `NEShapeItem`
  @nonobjc
  func addAnimations(for shape: NEShapeItem,
                     context: NELayerAnimationContext,
                     pathMultiplier: PathMultiplier,
                     roundedCorners: NERoundedCorners?)
    throws {
    switch shape {
    case let customShape as NEShape:
      try addAnimations(
        for: customShape.path,
        context: context,
        pathMultiplier: pathMultiplier,
        roundedCorners: roundedCorners
      )

    case let combinedShape as NECombinedShapeItem:
      try addAnimations(for: combinedShape, context: context, pathMultiplier: pathMultiplier)
      try context.compatibilityAssert(roundedCorners == nil, """
      Rounded corners support is not currently implemented for combined shape items
      """)

    case let ellipse as NEEllipse:
      try addAnimations(for: ellipse, context: context, pathMultiplier: pathMultiplier)

    case let rectangle as NERectangle:
      try addAnimations(
        for: rectangle,
        context: context,
        pathMultiplier: pathMultiplier,
        roundedCorners: roundedCorners
      )

    case let star as NEStar:
      try addAnimations(for: star, context: context, pathMultiplier: pathMultiplier)
      try context.compatibilityAssert(roundedCorners == nil, """
      Rounded corners support is currently not implemented for polygon items
      """)

    default:
      // None of the other `NEShapeItem` subclasses draw a `path`
      try context.logCompatibilityIssue("Unexpected shape type \(type(of: shape))")
      return
    }
  }

  /// Adds a `fillColor` animation for the given `NEFill` object
  @nonobjc
  func addAnimations(for fill: NEFill, context: NELayerAnimationContext) throws {
    fillRule = fill.fillRule.caFillRule

    try neAddAnimation(
      for: .fillColor,
      keyframes: fill.color,
      value: \.cgColorValue,
      context: context
    )

    try addOpacityAnimation(for: fill, context: context)
  }

  /// Adds animations for `strokeStart` and `strokeEnd` from the given `NETrim` object
  @nonobjc
  func addAnimations(for trim: NETrim, context: NELayerAnimationContext) throws -> PathMultiplier {
    let (strokeStartKeyframes, strokeEndKeyframes, pathMultiplier) = try trim.caShapeLayerKeyframes()

    try neAddAnimation(
      for: .strokeStart,
      keyframes: strokeStartKeyframes,
      value: { strokeStart in
        // Lottie animation files express stoke trims as a numerical percentage value
        // (e.g. 25%, 50%, 100%) so we divide by 100 to get the decimal values
        // expected by Core Animation (e.g. 0.25, 0.5, 1.0).
        CGFloat(strokeStart.cgFloatValue) / CGFloat(pathMultiplier) / 100
      }, context: context
    )

    try neAddAnimation(
      for: .strokeEnd,
      keyframes: strokeEndKeyframes,
      value: { strokeEnd in
        // Lottie animation files express stoke trims as a numerical percentage value
        // (e.g. 25%, 50%, 100%) so we divide by 100 to get the decimal values
        // expected by Core Animation (e.g. 0.25, 0.5, 1.0).
        CGFloat(strokeEnd.cgFloatValue) / CGFloat(pathMultiplier) / 100
      }, context: context
    )

    return pathMultiplier
  }
}

/// The number of times that a `CGPath` needs to be duplicated in order to support the animation's `NETrim` keyframes
typealias PathMultiplier = Int

extension NETrim {
  // MARK: Fileprivate

  /// The `strokeStart` and `strokeEnd` keyframes to apply to a `CAShapeLayer`,
  /// plus a `pathMultiplier` that should be applied to the layer's `path` so that
  /// trim values larger than 100% can be displayed properly.
  fileprivate func caShapeLayerKeyframes()
    throws
    -> (strokeStart: NEKeyframeGroup<NELottieVector1D>, strokeEnd: NEKeyframeGroup<NELottieVector1D>, pathMultiplier: PathMultiplier) {
    let strokeStart: NEKeyframeGroup<NELottieVector1D>
    let strokeEnd: NEKeyframeGroup<NELottieVector1D>

    // CAShapeLayer requires strokeStart to be less than strokeEnd. This
    // isn't required by the Lottie schema, so some animations may have
    // strokeStart and strokeEnd flipped.
    if startValueIsAlwaysLessOrEqualToThanEndValue() {
      // If the start value is always _less than_ or equal to the end value
      // then we can use the given values without any modifications
      strokeStart = start
      strokeEnd = end
    } else if startValueIsAlwaysGreaterThanOrEqualToEndValue() {
      // If the start value is always _greater than_ or equal to the end value,
      // then we can just swap the start / end keyframes. This lets us avoid
      // manually interpolating the keyframes values at each frame, which
      // would be more expensive.
      strokeStart = end
      strokeEnd = start
    } else {
      // Otherwise if the start / end values ever swap places we have to
      // fix the order on a per-keyframe basis, which may require manually
      // interpolating the keyframe values at each frame.
      (strokeStart, strokeEnd) = interpolatedAtEachFrame()
    }

    // If there are no offsets, then the stroke values can be used as-is
    guard
      !offset.keyframes.isEmpty,
      offset.keyframes.contains(where: { $0.value.cgFloatValue != 0 })
    else {
      return (strokeStart, strokeEnd, 1)
    }

    // Apply the offset to the start / end values at each frame
    let offsetStrokeKeyframes = NEKeyframes.combined(
      strokeStart,
      strokeEnd,
      offset,
      makeCombinedResult: { start, end, offset -> (start: NELottieVector1D, end: NELottieVector1D) in
        // Compute the adjusted value by converting the offset value to a stroke value
        let offsetStart = start.cgFloatValue + (offset.cgFloatValue / 360 * 100)
        let offsetEnd = end.cgFloatValue + (offset.cgFloatValue / 360 * 100)
        return (start: NELottieVector1D(offsetStart), end: NELottieVector1D(offsetEnd))
      }
    )

    var adjustedStrokeStart = offsetStrokeKeyframes.map { $0.start }
    var adjustedStrokeEnd = offsetStrokeKeyframes.map { $0.end }

    // If maximum stroke value is larger than 100%, then we have to create copies of the path
    // so the total path length includes the maximum stroke
    let startStrokes = adjustedStrokeStart.keyframes.map { $0.value.cgFloatValue }
    let endStrokes = adjustedStrokeEnd.keyframes.map { $0.value.cgFloatValue }
    let minimumStrokeMultiplier = Double(floor((startStrokes.min() ?? 0) / 100.0))
    let maximumStrokeMultiplier = Double(ceil((endStrokes.max() ?? 100) / 100.0))

    if minimumStrokeMultiplier < 0 {
      // Core Animation doesn't support negative stroke offsets, so we have to
      // shift all of the offset values up by the minimum
      adjustedStrokeStart = adjustedStrokeStart.map { NELottieVector1D($0.value + (abs(minimumStrokeMultiplier) * 100.0)) }
      adjustedStrokeEnd = adjustedStrokeEnd.map { NELottieVector1D($0.value + (abs(minimumStrokeMultiplier) * 100.0)) }
    }

    return (
      strokeStart: adjustedStrokeStart,
      strokeEnd: adjustedStrokeEnd,
      pathMultiplier: Int(abs(maximumStrokeMultiplier) + abs(minimumStrokeMultiplier))
    )
  }

  // MARK: Private

  /// Checks whether or not the value for `trim.start` is less than
  /// or equal to the value for every `trim.end` at every frame.
  private func startValueIsAlwaysLessOrEqualToThanEndValue() -> Bool {
    startAndEndValuesAllSatisfy { startValue, endValue in
      startValue <= endValue
    }
  }

  /// Checks whether or not the value for `trim.start` is greater than
  /// or equal to the value for every `trim.end` at every frame.
  private func startValueIsAlwaysGreaterThanOrEqualToEndValue() -> Bool {
    startAndEndValuesAllSatisfy { startValue, endValue in
      startValue >= endValue
    }
  }

  private func startAndEndValuesAllSatisfy(_ condition: (_ start: CGFloat, _ end: CGFloat) -> Bool) -> Bool {
    let keyframeTimes = Set(start.keyframes.map { $0.time } + end.keyframes.map { $0.time })

    let startInterpolator = NEKeyframeInterpolator(keyframes: start.keyframes)
    let endInterpolator = NEKeyframeInterpolator(keyframes: end.keyframes)

    for keyframeTime in keyframeTimes {
      guard
        let startAtTime = startInterpolator.value(frame: keyframeTime) as? NELottieVector1D,
        let endAtTime = endInterpolator.value(frame: keyframeTime) as? NELottieVector1D
      else { continue }

      if !condition(startAtTime.cgFloatValue, endAtTime.cgFloatValue) {
        return false
      }
    }

    return true
  }

  /// Interpolates the start and end keyframes, at each frame if necessary,
  /// so that the value of `strokeStart` is always less than `strokeEnd`.
  private func interpolatedAtEachFrame()
    -> (strokeStart: NEKeyframeGroup<NELottieVector1D>, strokeEnd: NEKeyframeGroup<NELottieVector1D>) {
    let combinedKeyframes = NEKeyframes.combined(
      start,
      end,
      makeCombinedResult: { startValue, endValue -> (start: NELottieVector1D, end: NELottieVector1D) in
        if startValue.cgFloatValue < endValue.cgFloatValue {
          return (start: startValue, end: endValue)
        } else {
          return (start: endValue, end: startValue)
        }
      }
    )

    return (
      strokeStart: combinedKeyframes.map { $0.start },
      strokeEnd: combinedKeyframes.map { $0.end }
    )
  }
}
