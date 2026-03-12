// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEKeyframeData

/// A generic class used to parse and remap keyframe json.
///
/// NEKeyframe json has a couple of different variations and formats depending on the
/// type of keyframea and also the Version of the JSON. By parsing the raw data
/// we can reconfigure it into a constant format.
final class NEKeyframeData<T> {
  // MARK: Lifecycle

  init(startValue: T?,
       endValue: T?,
       time: NEAnimationFrameTime?,
       hold: Int?,
       inTangent: NELottieVector2D?,
       outTangent: NELottieVector2D?,
       spatialInTangent: NELottieVector3D?,
       spatialOutTangent: NELottieVector3D?) {
    self.startValue = startValue
    self.endValue = endValue
    self.time = time
    self.hold = hold
    self.inTangent = inTangent
    self.outTangent = outTangent
    self.spatialInTangent = spatialInTangent
    self.spatialOutTangent = spatialOutTangent
  }

  // MARK: Internal

  enum NECodingKeys: String, CodingKey {
    case startValue = "s"
    case endValue = "e"
    case time = "t"
    case hold = "h"
    case inTangent = "i"
    case outTangent = "o"
    case spatialInTangent = "ti"
    case spatialOutTangent = "to"
  }

  /// The start value of the keyframe
  let startValue: T?
  /// The End value of the keyframe. Note: Newer NEVersions animation json do not have this field.
  let endValue: T?
  /// The time in frames of the keyframe.
  let time: NEAnimationFrameTime?
  /// A hold keyframe freezes interpolation until the next keyframe that is not a hold.
  let hold: Int?

  /// The in tangent for the time interpolation curve.
  let inTangent: NELottieVector2D?
  /// The out tangent for the time interpolation curve.
  let outTangent: NELottieVector2D?

  /// The spacial in tangent of the vector.
  let spatialInTangent: NELottieVector3D?
  /// The spacial out tangent of the vector.
  let spatialOutTangent: NELottieVector3D?

  var isHold: Bool {
    if let hold {
      return hold > 0
    }
    return false
  }
}

// MARK: Encodable

extension NEKeyframeData: Encodable where T: Encodable {}

// MARK: Decodable

extension NEKeyframeData: Decodable where T: Decodable {}

// MARK: NEDictionaryInitializable

extension NEKeyframeData: NEDictionaryInitializable where T: NEAnyInitializable {
  convenience init(dictionary: [String: Any]) throws {
    let startValue = try? dictionary[NECodingKeys.startValue.rawValue].flatMap(T.init)
    let endValue = try? dictionary[NECodingKeys.endValue.rawValue].flatMap(T.init)
    let time: NEAnimationFrameTime? = try? dictionary.value(for: NECodingKeys.time)
    let hold: Int? = try? dictionary.value(for: NECodingKeys.hold)
    let inTangent: NELottieVector2D? = try? dictionary.value(for: NECodingKeys.inTangent)
    let outTangent: NELottieVector2D? = try? dictionary.value(for: NECodingKeys.outTangent)
    let spatialInTangent: NELottieVector3D? = try? dictionary.value(for: NECodingKeys.spatialInTangent)
    let spatialOutTangent: NELottieVector3D? = try? dictionary.value(for: NECodingKeys.spatialOutTangent)

    self.init(
      startValue: startValue,
      endValue: endValue,
      time: time,
      hold: hold,
      inTangent: inTangent,
      outTangent: outTangent,
      spatialInTangent: spatialInTangent,
      spatialOutTangent: spatialOutTangent
    )
  }
}
