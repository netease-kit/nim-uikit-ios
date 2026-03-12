// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics
import Foundation
import QuartzCore

// MARK: - NELottieVector1D + Codable

/// Single value container. Needed because lottie sometimes wraps a Double in an array.
extension NELottieVector1D: Codable {
  // MARK: Lifecycle

  public init(from decoder: Decoder) throws {
    /// Try to decode an array of doubles
    do {
      var container = try decoder.unkeyedContainer()
      value = try container.decode(Double.self)
    } catch {
      value = try decoder.singleValueContainer().decode(Double.self)
    }
  }

  // MARK: Public

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(value)
  }

  // MARK: Internal

  var cgFloatValue: CGFloat {
    CGFloat(value)
  }
}

// MARK: - NELottieVector1D + NEAnyInitializable

extension NELottieVector1D: NEAnyInitializable {
  init(value: Any) throws {
    if
      let array = value as? [Double],
      let double = array.first {
      self.value = double
    } else if let double = value as? Double {
      self.value = double
    } else {
      throw NEInitializableError.invalidInput()
    }
  }
}

extension Double {
  var vectorValue: NELottieVector1D {
    NELottieVector1D(self)
  }
}

// MARK: - NELottieVector2D

/// Needed for decoding json {x: y:} to a CGPoint
public struct NELottieVector2D: Codable, Hashable, Sendable {
  // MARK: Lifecycle

  init(x: Double, y: Double) {
    self.x = x
    self.y = y
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NELottieVector2D.NECodingKeys.self)

    do {
      let xValue: [Double] = try container.decode([Double].self, forKey: .x)
      x = xValue[0]
    } catch {
      x = try container.decode(Double.self, forKey: .x)
    }

    do {
      let yValue: [Double] = try container.decode([Double].self, forKey: .y)
      y = yValue[0]
    } catch {
      y = try container.decode(Double.self, forKey: .y)
    }
  }

  // MARK: Public

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: NELottieVector2D.NECodingKeys.self)
    try container.encode(x, forKey: .x)
    try container.encode(y, forKey: .y)
  }

  // MARK: Internal

  var x: Double
  var y: Double

  var pointValue: CGPoint {
    CGPoint(x: x, y: y)
  }

  // MARK: Private

  private enum NECodingKeys: String, CodingKey {
    case x
    case y
  }
}

// MARK: NEAnyInitializable

extension NELottieVector2D: NEAnyInitializable {
  init(value: Any) throws {
    guard let dictionary = value as? [String: Any] else {
      throw NEInitializableError.invalidInput()
    }

    if
      let array = dictionary[NECodingKeys.x.rawValue] as? [Double],
      let double = array.first {
      x = double
    } else if let double = dictionary[NECodingKeys.x.rawValue] as? Double {
      x = double
    } else {
      throw NEInitializableError.invalidInput()
    }
    if
      let array = dictionary[NECodingKeys.y.rawValue] as? [Double],
      let double = array.first {
      y = double
    } else if let double = dictionary[NECodingKeys.y.rawValue] as? Double {
      y = double
    } else {
      throw NEInitializableError.invalidInput()
    }
  }
}

extension CGPoint {
  var vector2dValue: NELottieVector2D {
    NELottieVector2D(x: Double(x), y: Double(y))
  }
}

// MARK: - NELottieVector3D + Codable

/// A three dimensional vector.
/// These vectors are encoded and decoded from [Double]

extension NELottieVector3D: Codable {
  // MARK: Lifecycle

  init(x: CGFloat, y: CGFloat, z: CGFloat) {
    self.x = Double(x)
    self.y = Double(y)
    self.z = Double(z)
  }

  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()

    if !container.isAtEnd {
      x = try container.decode(Double.self)
    } else {
      x = 0
    }

    if !container.isAtEnd {
      y = try container.decode(Double.self)
    } else {
      y = 0
    }

    if !container.isAtEnd {
      z = try container.decode(Double.self)
    } else {
      z = 0
    }
  }

  // MARK: Public

  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(x)
    try container.encode(y)
    try container.encode(z)
  }
}

// MARK: - NELottieVector3D + NEAnyInitializable

extension NELottieVector3D: NEAnyInitializable {
  init(value: Any) throws {
    guard var array = value as? [Double] else {
      throw NEInitializableError.invalidInput()
    }
    x = array.count > 0 ? array.removeFirst() : 0
    y = array.count > 0 ? array.removeFirst() : 0
    z = array.count > 0 ? array.removeFirst() : 0
  }
}

public extension NELottieVector3D {
  var pointValue: CGPoint {
    CGPoint(x: x, y: y)
  }

  var sizeValue: CGSize {
    CGSize(width: x, height: y)
  }
}

extension CGPoint {
  var vector3dValue: NELottieVector3D {
    NELottieVector3D(x: x, y: y, z: 0)
  }
}

extension CGSize {
  var vector3dValue: NELottieVector3D {
    NELottieVector3D(x: width, y: height, z: 1)
  }
}

extension CATransform3D {
  enum Axis {
    case x, y, z
  }

  static func makeSkew(skew: CGFloat, skewAxis: CGFloat) -> CATransform3D {
    let mCos = cos(skewAxis.toRadians())
    let mSin = sin(skewAxis.toRadians())
    let aTan = tan(skew.toRadians())

    let transform1 = CATransform3D(
      m11: mCos,
      m12: mSin,
      m13: 0,
      m14: 0,
      m21: -mSin,
      m22: mCos,
      m23: 0,
      m24: 0,
      m31: 0,
      m32: 0,
      m33: 1,
      m34: 0,
      m41: 0,
      m42: 0,
      m43: 0,
      m44: 1
    )

    let transform2 = CATransform3D(
      m11: 1,
      m12: 0,
      m13: 0,
      m14: 0,
      m21: aTan,
      m22: 1,
      m23: 0,
      m24: 0,
      m31: 0,
      m32: 0,
      m33: 1,
      m34: 0,
      m41: 0,
      m42: 0,
      m43: 0,
      m44: 1
    )

    let transform3 = CATransform3D(
      m11: mCos,
      m12: -mSin,
      m13: 0,
      m14: 0,
      m21: mSin,
      m22: mCos,
      m23: 0,
      m24: 0,
      m31: 0,
      m32: 0,
      m33: 1,
      m34: 0,
      m41: 0,
      m42: 0,
      m43: 0,
      m44: 1
    )
    return CATransform3DConcat(transform3, CATransform3DConcat(transform2, transform1))
  }

  static func makeTransform(anchor: CGPoint,
                            position: CGPoint,
                            scale: CGSize,
                            rotationX: CGFloat,
                            rotationY: CGFloat,
                            rotationZ: CGFloat,
                            skew: CGFloat?,
                            skewAxis: CGFloat?)
    -> CATransform3D {
    if let skew, let skewAxis {
      return CATransform3DMakeTranslation(position.x, position.y, 0)
        .rotated(rotationX, axis: .x)
        .rotated(rotationY, axis: .y)
        .rotated(rotationZ, axis: .z)
        .skewed(skew: -skew, skewAxis: skewAxis)
        .scaled(scale * 0.01)
        .translated(anchor * -1)
    }
    return CATransform3DMakeTranslation(position.x, position.y, 0)
      .rotated(rotationX, axis: .x)
      .rotated(rotationY, axis: .y)
      .rotated(rotationZ, axis: .z)
      .scaled(scale * 0.01)
      .translated(anchor * -1)
  }

  func rotated(_ degrees: CGFloat, axis: Axis) -> CATransform3D {
    CATransform3DRotate(
      self,
      degrees.toRadians(),
      axis == .x ? 1 : 0,
      axis == .y ? 1 : 0,
      axis == .z ? 1 : 0
    )
  }

  func translated(_ translation: CGPoint) -> CATransform3D {
    CATransform3DTranslate(self, translation.x, translation.y, 0)
  }

  func scaled(_ scale: CGSize) -> CATransform3D {
    CATransform3DScale(self, scale.width, scale.height, 1)
  }

  func skewed(skew: CGFloat, skewAxis: CGFloat) -> CATransform3D {
    CATransform3DConcat(CATransform3D.makeSkew(skew: skew, skewAxis: skewAxis), self)
  }
}
