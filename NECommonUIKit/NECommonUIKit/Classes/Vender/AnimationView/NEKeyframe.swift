// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreFoundation

// MARK: - NEKeyframe

/// A keyframe with a single value, and timing information
/// about when the value should be displayed and how it
/// should be interpolated.
public final class NEKeyframe<T> {
  // MARK: Lifecycle

  /// Initialize a value-only keyframe with no time data.
  public init(_ value: T,
              spatialInTangent: NELottieVector3D? = nil,
              spatialOutTangent: NELottieVector3D? = nil) {
    self.value = value
    time = 0
    isHold = true
    inTangent = nil
    outTangent = nil
    self.spatialInTangent = spatialInTangent
    self.spatialOutTangent = spatialOutTangent
  }

  /// Initialize a keyframe
  public init(value: T,
              time: NEAnimationFrameTime,
              isHold: Bool = false,
              inTangent: NELottieVector2D? = nil,
              outTangent: NELottieVector2D? = nil,
              spatialInTangent: NELottieVector3D? = nil,
              spatialOutTangent: NELottieVector3D? = nil) {
    self.value = value
    self.time = time
    self.isHold = isHold
    self.outTangent = outTangent
    self.inTangent = inTangent
    self.spatialInTangent = spatialInTangent
    self.spatialOutTangent = spatialOutTangent
  }

  // MARK: Public

  /// The value of the keyframe
  public let value: T
  /// The time in frames of the keyframe.
  public let time: NEAnimationFrameTime
  /// A hold keyframe freezes interpolation until the next keyframe that is not a hold.
  public let isHold: Bool
  /// The in tangent for the time interpolation curve.
  public let inTangent: NELottieVector2D?
  /// The out tangent for the time interpolation curve.
  public let outTangent: NELottieVector2D?

  /// The spatial in tangent of the vector.
  public let spatialInTangent: NELottieVector3D?
  /// The spatial out tangent of the vector.
  public let spatialOutTangent: NELottieVector3D?
}

// MARK: Equatable

extension NEKeyframe: Equatable where T: Equatable {
  public static func == (lhs: NEKeyframe<T>, rhs: NEKeyframe<T>) -> Bool {
    lhs.value == rhs.value
      && lhs.time == rhs.time
      && lhs.isHold == rhs.isHold
      && lhs.inTangent == rhs.inTangent
      && lhs.outTangent == rhs.outTangent
      && lhs.spatialInTangent == rhs.spatialOutTangent
      && lhs.spatialOutTangent == rhs.spatialOutTangent
  }
}

// MARK: Hashable

extension NEKeyframe: Hashable where T: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
    hasher.combine(time)
    hasher.combine(isHold)
    hasher.combine(inTangent)
    hasher.combine(outTangent)
    hasher.combine(spatialInTangent)
    hasher.combine(spatialOutTangent)
  }
}

// MARK: Sendable

extension NEKeyframe: Sendable where T: Sendable {}
