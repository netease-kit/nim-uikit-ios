// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEKeyframeGroup

/// Used for coding/decoding a group of NEKeyframes by type.
///
/// NEKeyframe data is wrapped in a dictionary { "k" : NEKeyframeData }.
/// The keyframe data can either be an array of keyframes or, if no animation is present, the raw value.
/// This helper object is needed to properly decode the json.
final class NEKeyframeGroup<T> {
  // MARK: Lifecycle

  init(keyframes: ContiguousArray<NEKeyframe<T>>,
       unsupportedAfterEffectsExpression: String? = nil) {
    self.keyframes = keyframes
    self.unsupportedAfterEffectsExpression = unsupportedAfterEffectsExpression
  }

  init(_ value: T,
       unsupportedAfterEffectsExpression: String? = nil) {
    keyframes = [NEKeyframe(value)]
    self.unsupportedAfterEffectsExpression = unsupportedAfterEffectsExpression
  }

  // MARK: Internal

  enum KeyframeWrapperKey: String, CodingKey {
    case keyframeData = "k"
    case unsupportedAfterEffectsExpression = "x"
  }

  let keyframes: ContiguousArray<NEKeyframe<T>>

  /// lottie-ios doesn't support After Effects expressions, but we parse them so we can log diagnostics.
  /// More info: https://helpx.adobe.com/after-effects/using/expression-basics.html
  let unsupportedAfterEffectsExpression: String?
}

// MARK: Decodable

extension NEKeyframeGroup: Decodable where T: Decodable {
  convenience init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: KeyframeWrapperKey.self)
    let unsupportedAfterEffectsExpression = try? container.decode(String.self, forKey: .unsupportedAfterEffectsExpression)

    if let keyframeData: T = try? container.decode(T.self, forKey: .keyframeData) {
      /// Try to decode raw value; No keyframe data.
      self.init(
        keyframes: [NEKeyframe<T>(keyframeData)],
        unsupportedAfterEffectsExpression: unsupportedAfterEffectsExpression
      )
    } else {
      // Decode and array of keyframes.
      //
      // Body Movin and Lottie deal with keyframes in different ways.
      //
      // A keyframe object in Body movin defines a span of time with a START
      // and an END, from the current keyframe time to the next keyframe time.
      //
      // A keyframe object in Lottie defines a singular point in time/space.
      // This point has an in-tangent and an out-tangent.
      //
      // To properly decode this we must iterate through keyframes while holding
      // reference to the previous keyframe.

      var keyframesContainer = try container.nestedUnkeyedContainer(forKey: .keyframeData)
      var keyframes = ContiguousArray<NEKeyframe<T>>()
      var previousKeyframeData: NEKeyframeData<T>?
      while !keyframesContainer.isAtEnd {
        // Ensure that Time and Value are present.

        let keyframeData = try keyframesContainer.decode(NEKeyframeData<T>.self)

        guard
          let value: T = keyframeData.startValue ?? previousKeyframeData?.endValue,
          let time = keyframeData.time
        else {
          /// Missing keyframe data. JSON must be corrupt.
          throw DecodingError.dataCorruptedError(
            forKey: KeyframeWrapperKey.keyframeData,
            in: container,
            debugDescription: "Missing keyframe data."
          )
        }

        keyframes.append(NEKeyframe<T>(
          value: value,
          time: NEAnimationFrameTime(time),
          isHold: keyframeData.isHold,
          inTangent: previousKeyframeData?.inTangent,
          outTangent: keyframeData.outTangent,
          spatialInTangent: previousKeyframeData?.spatialInTangent,
          spatialOutTangent: keyframeData.spatialOutTangent
        ))
        previousKeyframeData = keyframeData
      }
      self.init(
        keyframes: keyframes,
        unsupportedAfterEffectsExpression: unsupportedAfterEffectsExpression
      )
    }
  }
}

// MARK: Encodable

extension NEKeyframeGroup: Encodable where T: Encodable {
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: KeyframeWrapperKey.self)

    if keyframes.count == 1 {
      let keyframe = keyframes[0]
      try container.encode(keyframe.value, forKey: .keyframeData)
    } else {
      var keyframeContainer = container.nestedUnkeyedContainer(forKey: .keyframeData)

      for i in 1 ..< keyframes.endIndex {
        let keyframe = keyframes[i - 1]
        let nextKeyframe = keyframes[i]
        let keyframeData = NEKeyframeData<T>(
          startValue: keyframe.value,
          endValue: nextKeyframe.value,
          time: keyframe.time,
          hold: keyframe.isHold ? 1 : nil,
          inTangent: nextKeyframe.inTangent,
          outTangent: keyframe.outTangent,
          spatialInTangent: nil,
          spatialOutTangent: nil
        )
        try keyframeContainer.encode(keyframeData)
      }
    }
  }
}

// MARK: NEDictionaryInitializable

extension NEKeyframeGroup: NEDictionaryInitializable where T: NEAnyInitializable {
  convenience init(dictionary: [String: Any]) throws {
    var keyframes = ContiguousArray<NEKeyframe<T>>()
    let unsupportedAfterEffectsExpression = dictionary[KeyframeWrapperKey.unsupportedAfterEffectsExpression.rawValue] as? String
    if
      let rawValue = dictionary[KeyframeWrapperKey.keyframeData.rawValue],
      let value = try? T(value: rawValue) {
      keyframes = [NEKeyframe<T>(value)]
    } else {
      var frameDictionaries: [[String: Any]]
      if let singleFrameDictionary = dictionary[KeyframeWrapperKey.keyframeData.rawValue] as? [String: Any] {
        frameDictionaries = [singleFrameDictionary]
      } else {
        frameDictionaries = try dictionary.value(for: KeyframeWrapperKey.keyframeData)
      }
      var previousKeyframeData: NEKeyframeData<T>?
      for frameDictionary in frameDictionaries {
        let data = try NEKeyframeData<T>(dictionary: frameDictionary)
        guard
          let value: T = data.startValue ?? previousKeyframeData?.endValue,
          let time = data.time
        else {
          throw NEInitializableError.invalidInput()
        }
        keyframes.append(NEKeyframe<T>(
          value: value,
          time: time,
          isHold: data.isHold,
          inTangent: previousKeyframeData?.inTangent,
          outTangent: data.outTangent,
          spatialInTangent: previousKeyframeData?.spatialInTangent,
          spatialOutTangent: data.spatialOutTangent
        ))
        previousKeyframeData = data
      }
    }

    self.init(
      keyframes: keyframes,
      unsupportedAfterEffectsExpression: unsupportedAfterEffectsExpression
    )
  }
}

// MARK: Equatable

extension NEKeyframeGroup: Equatable where T: Equatable {
  static func == (_ lhs: NEKeyframeGroup<T>, _ rhs: NEKeyframeGroup<T>) -> Bool {
    lhs.keyframes == rhs.keyframes
  }
}

// MARK: Hashable

extension NEKeyframeGroup: Hashable where T: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(keyframes)
  }
}

// MARK: Sendable

extension NEKeyframeGroup: Sendable where T: Sendable {}

extension NEKeyframe {
  /// Creates a copy of this `NEKeyframe` with the same timing data, but a different value
  func withValue<Value>(_ newValue: Value) -> NEKeyframe<Value> {
    NEKeyframe<Value>(
      value: newValue,
      time: time,
      isHold: isHold,
      inTangent: inTangent,
      outTangent: outTangent,
      spatialInTangent: spatialInTangent,
      spatialOutTangent: spatialOutTangent
    )
  }
}

extension NEKeyframeGroup {
  /// Maps the values of each individual keyframe in this group
  func map<NewValue>(_ transformation: (T) throws -> NewValue) rethrows -> NEKeyframeGroup<NewValue> {
    try NEKeyframeGroup<NewValue>(
      keyframes: ContiguousArray(keyframes.map { keyframe in
        try keyframe.withValue(transformation(keyframe.value))
      }),
      unsupportedAfterEffectsExpression: unsupportedAfterEffectsExpression
    )
  }
}

// MARK: - NEAnyKeyframeGroup

/// A type-erased wrapper for `NEKeyframeGroup`s
protocol NEAnyKeyframeGroup {
  /// An untyped copy of these keyframes
  var untyped: NEKeyframeGroup<Any> { get }

  /// An untyped `NEKeyframeInterpolator` for these keyframes
  var interpolator: NEAnyValueProvider { get }
}

// MARK: - NEKeyframeGroup + NEAnyKeyframeGroup

extension NEKeyframeGroup: NEAnyKeyframeGroup where T: NEAnyInterpolatable {
  var untyped: NEKeyframeGroup<Any> {
    map { $0 as Any }
  }

  var interpolator: NEAnyValueProvider {
    NEKeyframeInterpolator(keyframes: keyframes)
  }
}
