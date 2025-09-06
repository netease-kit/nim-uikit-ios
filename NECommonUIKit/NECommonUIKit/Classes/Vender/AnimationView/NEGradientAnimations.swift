// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NEGradientShapeItem

/// A `NEShapeItem` that represents a gradient
protocol NEGradientShapeItem: NEOpacityAnimationModel {
  var startPoint: NEKeyframeGroup<NELottieVector3D> { get }
  var endPoint: NEKeyframeGroup<NELottieVector3D> { get }
  var gradientType: NEGradientType { get }
  var numberOfColors: Int { get }
  var colors: NEKeyframeGroup<[Double]> { get }
}

// MARK: - NEGradientFill + NEGradientShapeItem

extension NEGradientFill: NEGradientShapeItem {}

// MARK: - NEGradientStroke + NEGradientShapeItem

extension NEGradientStroke: NEGradientShapeItem {}

// MARK: - NENEGradientRenderLayer + NEGradientShapeItem

extension NENEGradientRenderLayer {
  // MARK: Internal

  /// Adds gradient-related animations to this layer, from the given `NEGradientFill`
  ///  - The RGB components and alpha components can have different color stops / locations,
  ///    so have to be rendered in separate `CAGradientLayer`s.
  func addGradientAnimations(for gradient: NEGradientShapeItem,
                             type: NEGradientContentType,
                             context: NELayerAnimationContext)
    throws {
    // We have to set `colors` and `locations` to non-nil values
    // for the animations below to actually take effect
    locations = []

    // The initial value for `colors` must be an array with the exact same number of colors
    // as the gradient that will be applied in the `CAAnimation`
    switch type {
    case .rgb:
      colors = .init(
        repeating: CGColor.neRgb(0, 0, 0),
        count: gradient.numberOfColors
      )

    case .alpha:
      colors = .init(
        repeating: CGColor.neRgb(0, 0, 0),
        count: gradient.colorConfiguration(from: gradient.colors.keyframes[0].value, type: .alpha).count
      )
    }

    try neAddAnimation(
      for: .colors,
      keyframes: gradient.colors,
      value: { colorComponents in
        gradient.colorConfiguration(from: colorComponents, type: type).map { $0.color }
      },
      context: context
    )

    try neAddAnimation(
      for: .locations,
      keyframes: gradient.colors,
      value: { colorComponents in
        gradient.colorConfiguration(from: colorComponents, type: type).map { $0.location }
      },
      context: context
    )

    try addOpacityAnimation(for: gradient, context: context)

    switch gradient.gradientType {
    case .linear:
      try addLinearGradientAnimations(for: gradient, context: context)
    case .radial:
      try addRadialGradientAnimations(for: gradient, context: context)
    case .none:
      break
    }
  }

  // MARK: Private

  private func addLinearGradientAnimations(for gradient: NEGradientShapeItem,
                                           context: NELayerAnimationContext)
    throws {
    type = .axial

    try neAddAnimation(
      for: .startPoint,
      keyframes: gradient.startPoint,
      value: { absoluteStartPoint in
        percentBasedPointInBounds(from: absoluteStartPoint.pointValue)
      },
      context: context
    )

    try neAddAnimation(
      for: .endPoint,
      keyframes: gradient.endPoint,
      value: { absoluteEndPoint in
        percentBasedPointInBounds(from: absoluteEndPoint.pointValue)
      },
      context: context
    )
  }

  private func addRadialGradientAnimations(for gradient: NEGradientShapeItem, context: NELayerAnimationContext) throws {
    type = .radial

    let combinedKeyframes = NEKeyframes.combined(
      gradient.startPoint, gradient.endPoint,
      makeCombinedResult: { absoluteStartPoint, absoluteEndPoint -> NERadialGradientKeyframes in
        // Convert the absolute start / end points to the relative structure used by Core Animation
        let relativeStartPoint = percentBasedPointInBounds(from: absoluteStartPoint.pointValue)
        let radius = absoluteStartPoint.pointValue.distanceTo(absoluteEndPoint.pointValue)
        let relativeEndPoint = percentBasedPointInBounds(
          from: CGPoint(
            x: absoluteStartPoint.x + radius,
            y: absoluteStartPoint.y + radius
          ))

        return NERadialGradientKeyframes(startPoint: relativeStartPoint, endPoint: relativeEndPoint)
      }
    )

    try neAddAnimation(
      for: .startPoint,
      keyframes: combinedKeyframes,
      value: \.startPoint,
      context: context
    )

    try neAddAnimation(
      for: .endPoint,
      keyframes: combinedKeyframes,
      value: \.endPoint,
      context: context
    )
  }
}

// MARK: - NERadialGradientKeyframes

private struct NERadialGradientKeyframes: NEInterpolatable {
  let startPoint: CGPoint
  let endPoint: CGPoint

  func interpolate(to: NERadialGradientKeyframes, amount: CGFloat) -> NERadialGradientKeyframes {
    NERadialGradientKeyframes(
      startPoint: startPoint.interpolate(to: to.startPoint, amount: amount),
      endPoint: endPoint.interpolate(to: to.endPoint, amount: amount)
    )
  }
}

// MARK: - NEGradientContentType

/// Each type of gradient that can be constructed from a `NEGradientShapeItem`
enum NEGradientContentType {
  case rgb
  case alpha
}

/// `colors` and `locations` configuration for a `CAGradientLayer`
typealias NEGradientColorConfiguration = [(color: CGColor, location: CGFloat)]

extension NEGradientShapeItem {
  // MARK: Internal

  /// Whether or not this `NEGradientShapeItem` includes an alpha component
  /// that has to be rendered as a separate `CAGradientLayer` from the
  /// layer that renders the rgb color components
  var hasAlphaComponent: Bool {
    for colorComponentsKeyframe in colors.keyframes {
      let colorComponents = colorComponentsKeyframe.value
      let alphaConfiguration = colorConfiguration(from: colorComponents, type: .alpha)

      let notFullyOpaque = alphaConfiguration.contains(where: { color, _ in
        color.alpha < 0.999
      })

      if notFullyOpaque {
        return true
      }
    }

    return false
  }

  // MARK: Fileprivate

  /// Converts the compact `[Double]` color components representation
  /// into an array of `CGColor`s and the location of those colors within the gradient.
  ///  - The color components array is a repeating list of `[location, red, green, blue]` values
  ///    for each color in the gradient, followed by an optional repeating list of
  ///    `[location, alpha]` values that control the colors' alpha values.
  ///  - The RGB and alpha values can have different color stops / locations,
  ///    so each has to be rendered in a separate `CAGradientLayer`.
  fileprivate func colorConfiguration(from colorComponents: [Double],
                                      type: NEGradientContentType)
    -> NEGradientColorConfiguration {
    switch type {
    case .rgb:
      precondition(
        colorComponents.count >= numberOfColors * 4,
        "Each color must have RGB components and a location component"
      )

      // Each group of four `Double` values represents a single `CGColor`,
      // and its relative location within the gradient.
      var colors = NEGradientColorConfiguration()

      for colorIndex in 0 ..< numberOfColors {
        let colorStartIndex = colorIndex * 4

        let colorLocation = CGFloat(colorComponents[colorStartIndex])

        let color = CGColor.neRgb(
          CGFloat(colorComponents[colorStartIndex + 1]),
          CGFloat(colorComponents[colorStartIndex + 2]),
          CGFloat(colorComponents[colorStartIndex + 3])
        )

        colors.append((color: color, location: colorLocation))
      }

      return colors

    case .alpha:
      // After the rgb color components, there can be arbitrary number of repeating
      // `[alphaLocation, alphaValue]` pairs that define a separate alpha gradient.
      var alphaValues = NEGradientColorConfiguration()

      for alphaIndex in stride(from: numberOfColors * 4, to: colorComponents.endIndex, by: 2) {
        let alphaLocation = CGFloat(colorComponents[alphaIndex])
        let alphaValue = CGFloat(colorComponents[alphaIndex + 1])
        alphaValues.append((color: .neRgba(0, 0, 0, alphaValue), location: alphaLocation))
      }

      return alphaValues
    }
  }
}
