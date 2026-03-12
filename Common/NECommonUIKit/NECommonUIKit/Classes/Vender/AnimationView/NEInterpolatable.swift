// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics

// MARK: - NEInterpolatable

/// A type that can be interpolated between two values
public protocol NEInterpolatable: NEAnyInterpolatable {
  /// Interpolates the `self` to the given number by `amount`.
  ///  - Parameter to: The number to interpolate to.
  ///  - Parameter amount: The amount to interpolate,
  ///    relative to 0.0 (self) and 1.0 (to).
  ///    `amount` can be greater than one and less than zero,
  ///    and interpolation should not be clamped.
  ///
  ///  ```
  ///  let number = 5
  ///  let interpolated = number.interpolateTo(10, amount: 0.5)
  ///  print(interpolated) // 7.5
  ///  ```
  ///
  ///  ```
  ///  let number = 5
  ///  let interpolated = number.interpolateTo(10, amount: 1.5)
  ///  print(interpolated) // 12.5
  ///  ```
  func interpolate(to: Self, amount: CGFloat) -> Self
}

// MARK: - NESpatialInterpolatable

/// A type that can be interpolated between two values,
/// additionally using optional `spatialOutTangent` and `spatialInTangent` values.
///  - If your implementation doesn't use the `spatialOutTangent` and `spatialInTangent`
///    parameters, prefer implementing the simpler `NEInterpolatable` protocol.
public protocol NESpatialInterpolatable: NEAnyInterpolatable {
  /// Interpolates the `self` to the given number by `amount`.
  ///  - Parameter to: The number to interpolate to.
  ///  - Parameter amount: The amount to interpolate,
  ///    relative to 0.0 (self) and 1.0 (to).
  ///    `amount` can be greater than one and less than zero,
  ///    and interpolation should not be clamped.
  func interpolate(to: Self,
                   amount: CGFloat,
                   spatialOutTangent: CGPoint?,
                   spatialInTangent: CGPoint?)
    -> Self
}

// MARK: - NEAnyInterpolatable

/// The base protocol that is implemented by both `NEInterpolatable` and `NESpatialInterpolatable`
/// Types should not directly implement this protocol.
public protocol NEAnyInterpolatable {
  /// Interpolates by calling either `NEInterpolatable.interpolate`
  /// or `NESpatialInterpolatable.interpolate`.
  /// Should not be implemented or called by consumers.
  func _interpolate(to: Self,
                    amount: CGFloat,
                    spatialOutTangent: CGPoint?,
                    spatialInTangent: CGPoint?)
    -> Self
}

public extension NEInterpolatable {
  func _interpolate(to: Self,
                    amount: CGFloat,
                    spatialOutTangent _: CGPoint?,
                    spatialInTangent _: CGPoint?)
    -> Self {
    interpolate(to: to, amount: amount)
  }
}

public extension NESpatialInterpolatable {
  /// Helper that interpolates this `NESpatialInterpolatable`
  /// with `nil` spatial in/out tangents
  func interpolate(to: Self, amount: CGFloat) -> Self {
    interpolate(
      to: to,
      amount: amount,
      spatialOutTangent: nil,
      spatialInTangent: nil
    )
  }

  func _interpolate(to: Self,
                    amount: CGFloat,
                    spatialOutTangent: CGPoint?,
                    spatialInTangent: CGPoint?)
    -> Self {
    interpolate(
      to: to,
      amount: amount,
      spatialOutTangent: spatialOutTangent,
      spatialInTangent: spatialInTangent
    )
  }
}

// MARK: - Double + NEInterpolatable

extension Double: NEInterpolatable {}

// MARK: - CGFloat + NEInterpolatable

extension CGFloat: NEInterpolatable {}

// MARK: - Float + NEInterpolatable

extension Float: NEInterpolatable {}

public extension NEInterpolatable where Self: BinaryFloatingPoint {
  func interpolate(to: Self, amount: CGFloat) -> Self {
    self + ((to - self) * Self(amount))
  }
}

// MARK: - CGRect + NEInterpolatable

extension CGRect: NEInterpolatable {
  public func interpolate(to: CGRect, amount: CGFloat) -> CGRect {
    CGRect(
      x: origin.x.interpolate(to: to.origin.x, amount: amount),
      y: origin.y.interpolate(to: to.origin.y, amount: amount),
      width: width.interpolate(to: to.width, amount: amount),
      height: height.interpolate(to: to.height, amount: amount)
    )
  }
}

// MARK: - CGSize + NEInterpolatable

extension CGSize: NEInterpolatable {
  public func interpolate(to: CGSize, amount: CGFloat) -> CGSize {
    CGSize(
      width: width.interpolate(to: to.width, amount: amount),
      height: height.interpolate(to: to.height, amount: amount)
    )
  }
}

// MARK: - CGPoint + NESpatialInterpolatable

extension CGPoint: NESpatialInterpolatable {
  public func interpolate(to: CGPoint,
                          amount: CGFloat,
                          spatialOutTangent: CGPoint?,
                          spatialInTangent: CGPoint?)
    -> CGPoint {
    guard
      let outTan = spatialOutTangent,
      let inTan = spatialInTangent
    else {
      return CGPoint(
        x: x.interpolate(to: to.x, amount: amount),
        y: y.interpolate(to: to.y, amount: amount)
      )
    }

    let cp1 = self + outTan
    let cp2 = to + inTan
    return interpolate(to, outTangent: cp1, inTangent: cp2, amount: amount)
  }
}

// MARK: - NELottieColor + NEInterpolatable

extension NELottieColor: NEInterpolatable {
  public func interpolate(to: NELottieColor, amount: CGFloat) -> NELottieColor {
    NELottieColor(
      r: r.interpolate(to: to.r, amount: amount),
      g: g.interpolate(to: to.g, amount: amount),
      b: b.interpolate(to: to.b, amount: amount),
      a: a.interpolate(to: to.a, amount: amount)
    )
  }
}

// MARK: - NELottieVector1D + NEInterpolatable

extension NELottieVector1D: NEInterpolatable {
  public func interpolate(to: NELottieVector1D, amount: CGFloat) -> NELottieVector1D {
    value.interpolate(to: to.value, amount: amount).vectorValue
  }
}

// MARK: - NELottieVector2D + NESpatialInterpolatable

extension NELottieVector2D: NESpatialInterpolatable {
  public func interpolate(to: NELottieVector2D,
                          amount: CGFloat,
                          spatialOutTangent: CGPoint?,
                          spatialInTangent: CGPoint?)
    -> NELottieVector2D {
    pointValue.interpolate(
      to: to.pointValue,
      amount: amount,
      spatialOutTangent: spatialOutTangent,
      spatialInTangent: spatialInTangent
    )
    .vector2dValue
  }
}

// MARK: - NELottieVector3D + NESpatialInterpolatable

extension NELottieVector3D: NESpatialInterpolatable {
  public func interpolate(to: NELottieVector3D,
                          amount: CGFloat,
                          spatialOutTangent: CGPoint?,
                          spatialInTangent: CGPoint?)
    -> NELottieVector3D {
    if spatialInTangent != nil || spatialOutTangent != nil {
      // TODO: Support third dimension spatial interpolation
      let point = pointValue.interpolate(
        to: to.pointValue,
        amount: amount,
        spatialOutTangent: spatialOutTangent,
        spatialInTangent: spatialInTangent
      )

      return NELottieVector3D(
        x: point.x,
        y: point.y,
        z: CGFloat(z.interpolate(to: to.z, amount: amount))
      )
    }

    return NELottieVector3D(
      x: x.interpolate(to: to.x, amount: amount),
      y: y.interpolate(to: to.y, amount: amount),
      z: z.interpolate(to: to.z, amount: amount)
    )
  }
}

// MARK: - Array + NEInterpolatable, NEAnyInterpolatable

extension Array: NEInterpolatable, NEAnyInterpolatable where Element: NEInterpolatable {
  public func interpolate(to: [Element], amount: CGFloat) -> [Element] {
    NELottieLogger.shared.assert(
      count == to.count,
      "When interpolating Arrays, both array sound have the same element count."
    )

    return zip(self, to).map { lhs, rhs in
      lhs.interpolate(to: rhs, amount: amount)
    }
  }
}

// MARK: - Optional + NEInterpolatable, NEAnyInterpolatable

extension Optional: NEInterpolatable, NEAnyInterpolatable where Wrapped: NEInterpolatable {
  public func interpolate(to: Wrapped?, amount: CGFloat) -> Wrapped? {
    guard let self, let to else { return nil }
    return self.interpolate(to: to, amount: amount)
  }
}

// MARK: - Hold

/// An `NEInterpolatable` container that animates using "hold" keyframes.
/// The keyframes do not animate, and instead always display the value from the most recent keyframe.
/// This is necessary when passing non-interpolatable values to a method that requires an `NEInterpolatable` conformance.
struct Hold<T>: NEInterpolatable {
  let value: T

  func interpolate(to: Hold<T>, amount: CGFloat) -> Hold<T> {
    if amount < 1 {
      return self
    } else {
      return to
    }
  }
}
