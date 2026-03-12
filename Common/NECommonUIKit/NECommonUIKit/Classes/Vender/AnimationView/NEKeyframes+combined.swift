// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEKeyframes

enum NEKeyframes {
  // MARK: Internal

  /// Combines the given keyframe groups of `NEKeyframe<T>`s into a single keyframe group of of `NEKeyframe<[T]>`s
  ///  - If all of the `NEKeyframeGroup`s have the exact same animation timing, the keyframes are merged
  ///  - Otherwise, the keyframes are manually interpolated at each frame in the animation
  static func combined<T>(_ allGroups: [NEKeyframeGroup<T>],
                          requiresManualInterpolation: Bool = false)
    -> NEKeyframeGroup<[T]>
    where T: NEAnyInterpolatable {
    NEKeyframes.combined(
      allGroups,
      requiresManualInterpolation: requiresManualInterpolation,
      makeCombinedResult: { untypedValues in
        untypedValues.compactMap { $0 as? T }
      }
    )
  }

  /// Combines the given keyframe groups of `NEKeyframe<T>`s into a single keyframe group of of `NEKeyframe<[T]>`s
  ///  - If all of the `NEKeyframeGroup`s have the exact same animation timing, the keyframes are merged
  ///  - Otherwise, the keyframes are manually interpolated at each frame in the animation
  static func combined<T1, T2, CombinedResult>(_ k1: NEKeyframeGroup<T1>,
                                               _ k2: NEKeyframeGroup<T2>,
                                               requiresManualInterpolation: Bool = false,
                                               makeCombinedResult: (T1, T2) throws -> CombinedResult)
    rethrows
    -> NEKeyframeGroup<CombinedResult>
    where T1: NEAnyInterpolatable, T2: NEAnyInterpolatable {
    try NEKeyframes.combined(
      [k1, k2],
      requiresManualInterpolation: requiresManualInterpolation,
      makeCombinedResult: { untypedValues in
        guard
          let t1 = untypedValues[0] as? T1,
          let t2 = untypedValues[1] as? T2
        else { return nil }

        return try makeCombinedResult(t1, t2)
      }
    )
  }

  /// Combines the given keyframe groups of `NEKeyframe<T>`s into a single keyframe group of of `NEKeyframe<[T]>`s
  ///  - If all of the `NEKeyframeGroup`s have the exact same animation timing, the keyframes are merged
  ///  - Otherwise, the keyframes are manually interpolated at each frame in the animation
  static func combined<T1, T2, T3, CombinedResult>(_ k1: NEKeyframeGroup<T1>,
                                                   _ k2: NEKeyframeGroup<T2>,
                                                   _ k3: NEKeyframeGroup<T3>,
                                                   requiresManualInterpolation: Bool = false,
                                                   makeCombinedResult: (T1, T2, T3) -> CombinedResult)
    -> NEKeyframeGroup<CombinedResult>
    where T1: NEAnyInterpolatable, T2: NEAnyInterpolatable, T3: NEAnyInterpolatable {
    NEKeyframes.combined(
      [k1, k2, k3],
      requiresManualInterpolation: requiresManualInterpolation,
      makeCombinedResult: { untypedValues in
        guard
          let t1 = untypedValues[0] as? T1,
          let t2 = untypedValues[1] as? T2,
          let t3 = untypedValues[2] as? T3
        else { return nil }

        return makeCombinedResult(t1, t2, t3)
      }
    )
  }

  /// Combines the given keyframe groups of `NEKeyframe<T>`s into a single keyframe group of of `NEKeyframe<[T]>`s
  ///  - If all of the `NEKeyframeGroup`s have the exact same animation timing, the keyframes are merged
  ///  - Otherwise, the keyframes are manually interpolated at each frame in the animation
  static func combined<T1, T2, T3, T4, T5, T6, T7, CombinedResult>(_ k1: NEKeyframeGroup<T1>,
                                                                   _ k2: NEKeyframeGroup<T2>,
                                                                   _ k3: NEKeyframeGroup<T3>,
                                                                   _ k4: NEKeyframeGroup<T4>,
                                                                   _ k5: NEKeyframeGroup<T5>,
                                                                   _ k6: NEKeyframeGroup<T6>,
                                                                   _ k7: NEKeyframeGroup<T7>,
                                                                   requiresManualInterpolation: Bool = false,
                                                                   makeCombinedResult: (T1, T2, T3, T4, T5, T6, T7) -> CombinedResult)
    -> NEKeyframeGroup<CombinedResult>
    where T1: NEAnyInterpolatable, T2: NEAnyInterpolatable, T3: NEAnyInterpolatable, T4: NEAnyInterpolatable,
    T5: NEAnyInterpolatable, T6: NEAnyInterpolatable, T7: NEAnyInterpolatable {
    NEKeyframes.combined(
      [k1, k2, k3, k4, k5, k6, k7],
      requiresManualInterpolation: requiresManualInterpolation,
      makeCombinedResult: { untypedValues in
        guard
          let t1 = untypedValues[0] as? T1,
          let t2 = untypedValues[1] as? T2,
          let t3 = untypedValues[2] as? T3,
          let t4 = untypedValues[3] as? T4,
          let t5 = untypedValues[4] as? T5,
          let t6 = untypedValues[5] as? T6,
          let t7 = untypedValues[6] as? T7
        else { return nil }

        return makeCombinedResult(t1, t2, t3, t4, t5, t6, t7)
      }
    )
  }

  /// Combines the given keyframe groups of `NEKeyframe<T>`s into a single keyframe group of of `NEKeyframe<[T]>`s
  ///  - If all of the `NEKeyframeGroup`s have the exact same animation timing, the keyframes are merged
  ///  - Otherwise, the keyframes are manually interpolated at each frame in the animation
  static func combined<T1, T2, T3, T4, T5, T6, T7, T8, CombinedResult>(_ k1: NEKeyframeGroup<T1>,
                                                                       _ k2: NEKeyframeGroup<T2>,
                                                                       _ k3: NEKeyframeGroup<T3>,
                                                                       _ k4: NEKeyframeGroup<T4>,
                                                                       _ k5: NEKeyframeGroup<T5>,
                                                                       _ k6: NEKeyframeGroup<T6>,
                                                                       _ k7: NEKeyframeGroup<T7>,
                                                                       _ k8: NEKeyframeGroup<T8>,
                                                                       requiresManualInterpolation: Bool = false,
                                                                       makeCombinedResult: (T1, T2, T3, T4, T5, T6, T7, T8) -> CombinedResult)
    -> NEKeyframeGroup<CombinedResult>
    where T1: NEAnyInterpolatable, T2: NEAnyInterpolatable, T3: NEAnyInterpolatable, T4: NEAnyInterpolatable,
    T5: NEAnyInterpolatable, T6: NEAnyInterpolatable, T7: NEAnyInterpolatable, T8: NEAnyInterpolatable {
    NEKeyframes.combined(
      [k1, k2, k3, k4, k5, k6, k7, k8],
      requiresManualInterpolation: requiresManualInterpolation,
      makeCombinedResult: { untypedValues in
        guard
          let t1 = untypedValues[0] as? T1,
          let t2 = untypedValues[1] as? T2,
          let t3 = untypedValues[2] as? T3,
          let t4 = untypedValues[3] as? T4,
          let t5 = untypedValues[4] as? T5,
          let t6 = untypedValues[5] as? T6,
          let t7 = untypedValues[6] as? T7,
          let t8 = untypedValues[7] as? T8
        else { return nil }

        return makeCombinedResult(t1, t2, t3, t4, t5, t6, t7, t8)
      }
    )
  }

  /// Combines the given keyframe groups of `NEKeyframe<T>`s into a single keyframe group of of `NEKeyframe<[T]>`s
  ///  - If all of the `NEKeyframeGroup`s have the exact same animation timing, the keyframes are merged
  ///  - Otherwise, the keyframes are manually interpolated at each frame in the animation
  static func combined<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, CombinedResult>(_ k1: NEKeyframeGroup<T1>,
                                                                                _ k2: NEKeyframeGroup<T2>,
                                                                                _ k3: NEKeyframeGroup<T3>,
                                                                                _ k4: NEKeyframeGroup<T4>,
                                                                                _ k5: NEKeyframeGroup<T5>,
                                                                                _ k6: NEKeyframeGroup<T6>,
                                                                                _ k7: NEKeyframeGroup<T7>,
                                                                                _ k8: NEKeyframeGroup<T8>,
                                                                                _ k9: NEKeyframeGroup<T9>,
                                                                                _ k10: NEKeyframeGroup<T10>,
                                                                                requiresManualInterpolation: Bool = false,
                                                                                makeCombinedResult: (T1, T2, T3, T4, T5, T6, T7, T8, T9, T10) -> CombinedResult)
    -> NEKeyframeGroup<CombinedResult>
    where T1: NEAnyInterpolatable, T2: NEAnyInterpolatable, T3: NEAnyInterpolatable, T4: NEAnyInterpolatable,
    T5: NEAnyInterpolatable, T6: NEAnyInterpolatable, T7: NEAnyInterpolatable, T8: NEAnyInterpolatable,
    T9: NEAnyInterpolatable, T10: NEAnyInterpolatable {
    NEKeyframes.combined(
      [k1, k2, k3, k4, k5, k6, k7, k8, k9, k10],
      requiresManualInterpolation: requiresManualInterpolation,
      makeCombinedResult: { untypedValues in
        guard
          let t1 = untypedValues[0] as? T1,
          let t2 = untypedValues[1] as? T2,
          let t3 = untypedValues[2] as? T3,
          let t4 = untypedValues[3] as? T4,
          let t5 = untypedValues[4] as? T5,
          let t6 = untypedValues[5] as? T6,
          let t7 = untypedValues[6] as? T7,
          let t8 = untypedValues[7] as? T8,
          let t9 = untypedValues[8] as? T9,
          let t10 = untypedValues[9] as? T10
        else { return nil }

        return makeCombinedResult(t1, t2, t3, t4, t5, t6, t7, t8, t9, t10)
      }
    )
  }

  // MARK: Private

  /// Combines the given `[NEKeyframeGroup]` of `NEKeyframe<T>`s into a single `NEKeyframeGroup` of `NEKeyframe<CombinedResult>`s
  ///  - If all of the `NEKeyframeGroup`s have the exact same animation timing, the keyframes are merged
  ///  - Otherwise, the keyframes are manually interpolated at each frame in the animation
  ///
  /// `makeCombinedResult` is a closure that takes an array of keyframe values (with the exact same length as `NEAnyKeyframeGroup`),
  /// casts them to the expected type, and combined them into the final resulting keyframe.
  ///
  /// `requiresManualInterpolation` determines whether the keyframes must be computed using `NEKeyframes.manuallyInterpolated`,
  /// which interpolates the value at each frame, or if the keyframes can simply be combined.
  private static func combined<CombinedResult>(_ allGroups: [NEAnyKeyframeGroup],
                                               requiresManualInterpolation: Bool,
                                               makeCombinedResult: ([Any]) throws -> CombinedResult?)
    rethrows
    -> NEKeyframeGroup<CombinedResult> {
    let untypedGroups = allGroups.map { $0.untyped }

    // Animations with no timing information (e.g. with just a single keyframe)
    // can be trivially combined with any other set of keyframes, so we don't need
    // to check those.
    let animatingKeyframes = untypedGroups.filter { $0.keyframes.count > 1 }

    guard
      !requiresManualInterpolation,
      !allGroups.isEmpty,
      animatingKeyframes.allSatisfy({ $0.hasSameTimingParameters(as: animatingKeyframes[0]) })
    else {
      // If the keyframes don't all share the same timing information,
      // we have to interpolate the value at each individual frame
      return try NEKeyframes.manuallyInterpolated(allGroups, makeCombinedResult: makeCombinedResult)
    }

    var combinedKeyframes = ContiguousArray<NEKeyframe<CombinedResult>>()
    let baseKeyframes = (animatingKeyframes.first ?? untypedGroups[0]).keyframes

    for index in baseKeyframes.indices {
      let baseKeyframe = baseKeyframes[index]
      let untypedValues = untypedGroups.map { $0.valueForCombinedKeyframes(at: index) }

      if let combinedValue = try makeCombinedResult(untypedValues) {
        combinedKeyframes.append(baseKeyframe.withValue(combinedValue))
      } else {
        NELottieLogger.shared.assertionFailure("""
        Failed to cast untyped keyframe values to expected type. This is an internal error.
        """)
      }
    }

    return NEKeyframeGroup(keyframes: combinedKeyframes)
  }

  private static func manuallyInterpolated<CombinedResult>(_ allGroups: [NEAnyKeyframeGroup],
                                                           makeCombinedResult: ([Any]) throws -> CombinedResult?)
    rethrows
    -> NEKeyframeGroup<CombinedResult> {
    let untypedGroups = allGroups.map { $0.untyped }
    let untypedInterpolators = allGroups.map { $0.interpolator }

    let times = untypedGroups.flatMap { $0.keyframes.map { $0.time } }

    let minimumTime = times.min() ?? 0
    let maximumTime = times.max() ?? 0

    // We disable Core Animation interpolation when using manually interpolated keyframes,
    // so we don't animate between these values. To prevent the animation from being choppy
    // even at low playback speed, we have to interpolate at a very high fidelity.
    let animationLocalTimeRange = stride(from: minimumTime, to: maximumTime, by: 0.1)

    let interpolatedKeyframes = try animationLocalTimeRange.compactMap { localTime -> NEKeyframe<CombinedResult>? in
      let interpolatedValues = untypedInterpolators.map { interpolator in
        interpolator.value(frame: NEAnimationFrameTime(localTime))
      }

      guard let combinedResult = try makeCombinedResult(interpolatedValues) else {
        NELottieLogger.shared.assertionFailure("""
        Failed to cast untyped keyframe values to expected type. This is an internal error.
        """)
        return nil
      }

      return NEKeyframe(
        value: combinedResult,
        time: NEAnimationFrameTime(localTime),
        // Since we already manually interpolated the keyframes, have Core Animation display
        // each value as a static keyframe rather than trying to interpolate between them.
        isHold: true
      )
    }

    return NEKeyframeGroup(keyframes: ContiguousArray(interpolatedKeyframes))
  }
}

extension NEKeyframeGroup {
  /// Whether or not all of the keyframes in this `NEKeyframeGroup` have the same
  /// timing parameters as the corresponding keyframe in the other given `NEKeyframeGroup`
  func hasSameTimingParameters<U>(as other: NEKeyframeGroup<U>) -> Bool {
    guard keyframes.count == other.keyframes.count else {
      return false
    }

    return zip(keyframes, other.keyframes).allSatisfy {
      $0.hasSameTimingParameters(as: $1)
    }
  }
}

private extension NEKeyframe {
  /// Whether or not this keyframe has the same timing parameters as the given keyframe,
  /// excluding `spatialInTangent` and `spatialOutTangent`.
  func hasSameTimingParameters<U>(as other: NEKeyframe<U>) -> Bool {
    time == other.time
      && isHold == other.isHold
      && inTangent == other.inTangent
      && outTangent == other.outTangent
    // We intentionally don't compare spatial in/out tangents,
    // since those values are only used in very specific cases
    // (animating the x/y position of a layer), which aren't ever
    // combined in this way.
  }
}

private extension NEKeyframeGroup {
  /// The value to use for a combined set of keyframes, for the given index
  func valueForCombinedKeyframes(at index: Int) -> T {
    if keyframes.count == 1 {
      return keyframes[0].value
    } else {
      return keyframes[index].value
    }
  }
}
