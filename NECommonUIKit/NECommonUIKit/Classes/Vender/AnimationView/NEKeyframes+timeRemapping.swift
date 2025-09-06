// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

extension NEKeyframes {
  /// Manually interpolates the given keyframes, and applies `context.complexTimeRemapping`.
  ///  - Since `complexTimeRemapping` is a mapping from "global time" to "local time",
  ///    we have to manually interpolate the keyframes at every frame in the animation.
  static func manuallyInterpolatedWithTimeRemapping<T: NEAnyInterpolatable>(_ keyframes: NEKeyframeGroup<T>,
                                                                            context: NELayerAnimationContext)
    -> NEKeyframeGroup<T> {
    let minimumTime = context.animation.startFrame
    let maximumTime = context.animation.endFrame
    let animationLocalTimeRange = stride(from: minimumTime, to: maximumTime, by: 1.0)

    let interpolator = keyframes.interpolator

    // Since potentially many global times can refer to the same local time,
    // we can cache and reused these local-time values.
    var localTimeCache = [NEAnimationFrameTime: T]()

    let interpolatedRemappedKeyframes = animationLocalTimeRange.compactMap { globalTime -> NEKeyframe<T>? in
      let remappedLocalTime = context.complexTimeRemapping(globalTime)

      let valueAtRemappedTime: T
      if let cachedValue = localTimeCache[remappedLocalTime] {
        valueAtRemappedTime = cachedValue
      } else if let interpolatedValue = interpolator.value(frame: remappedLocalTime) as? T {
        valueAtRemappedTime = interpolatedValue
        localTimeCache[remappedLocalTime] = interpolatedValue
      } else {
        NELottieLogger.shared.assertionFailure("""
        Failed to cast untyped keyframe values to expected type. This is an internal error.
        """)
        return nil
      }

      return NEKeyframe(
        value: valueAtRemappedTime,
        time: NEAnimationFrameTime(globalTime)
      )
    }

    return NEKeyframeGroup(keyframes: ContiguousArray(interpolatedRemappedKeyframes))
  }
}
