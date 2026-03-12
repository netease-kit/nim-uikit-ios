
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NEAnimationLayer

/// A type of `CALayer` that can be used in a Lottie animation
///  - Layers backed by a `LayerModel` subclass should subclass `BaseCompositionLayer`
protocol NEAnimationLayer: CALayer {
  /// Instructs this layer to setup its `CAAnimation`s
  /// using the given `NELayerAnimationContext`
  func setupAnimations(context: NELayerAnimationContext) throws
}

// MARK: - NELayerAnimationContext

// Context describing the timing parameters of the current animation
struct NELayerAnimationContext {
  /// The animation being played
  let animation: NELottieAnimation

  /// The timing configuration that should be applied to `CAAnimation`s
  let timingConfiguration: NECoreAnimationLayer.NECAMediaTimingConfiguration

  /// The absolute frame number that this animation begins at
  let startFrame: NEAnimationFrameTime

  /// The absolute frame number that this animation ends at
  let endFrame: NEAnimationFrameTime

  /// The set of custom Value Providers applied to this animation
  let valueProviderStore: NEValueProviderStore

  /// Information about whether or not an animation is compatible with the Core Animation engine
  let compatibilityTracker: NECompatibilityTracker

  /// The logger that should be used for assertions and warnings
  let logger: NELottieLogger

  /// Mutable state related to log events, stored on the `NECoreAnimationLayer`.
  let loggingState: NELoggingState

  /// The AnimationKeypath represented by the current layer
  var currentKeypath: NEAnimationKeypath

  /// The `AnimationKeypathTextProvider`
  var textProvider: NEAnimationKeypathTextProvider

  /// Records the given animation keypath so it can be logged or collected into a list
  ///  - Used for `NECoreAnimationLayer.logHierarchyKeypaths()` and `allHierarchyKeypaths()`
  var recordHierarchyKeypath: ((String) -> Void)?

  /// A closure that remaps the given frame in the child layer's local time to a frame
  /// in the animation's overall global time.
  ///  - This time remapping is simple and only used `preCompLayer.timeStretch` and `preCompLayer.startTime`,
  ///    so is a trivial function and is invertible. This allows us to invert the time remapping from
  ///    "global time to local time" to instead be "local time to global time".
  private(set) var simpleTimeRemapping: ((_ localTime: NEAnimationFrameTime) -> NEAnimationFrameTime) = { $0 }

  /// A complex time remapping closure that remaps the given frame in the animation's overall global time
  /// into the child layer's local time.
  ///  - This time remapping is arbitrarily complex because it includes the full `preCompLayer.timeRemapping`.
  ///  - Since it isn't possible to invert the time remapping function, this can only be applied by converting
  ///    from global time to local time. This requires using `NEKeyframes.manuallyInterpolatedWithTimeRemapping`.
  private(set) var complexTimeRemapping: ((_ globalTime: NEAnimationFrameTime) -> NEAnimationFrameTime) = { $0 }

  /// Whether or not this layer is required to use the `complexTimeRemapping` via
  /// the more expensive `NEKeyframes.manuallyInterpolatedWithTimeRemapping` codepath.
  var mustUseComplexTimeRemapping = false

  /// The duration of the animation
  var animationDuration: NEAnimationFrameTime {
    // Normal animation playback (like when looping) skips the last frame.
    // However when the animation is paused, we need to be able to render the final frame.
    // To allow this we have to extend the length of the animation by one frame.
    let animationEndFrame: NEAnimationFrameTime
    if timingConfiguration.speed == 0 {
      animationEndFrame = animation.endFrame + 1
    } else {
      animationEndFrame = animation.endFrame
    }

    return Double(animationEndFrame - animation.startFrame) / animation.framerate
  }

  /// Adds the given component string to the `NEAnimationKeypath` stored
  /// that describes the current path being configured by this context value
  func addingKeypathComponent(_ component: String) -> NELayerAnimationContext {
    var context = self
    context.currentKeypath.keys.append(component)
    return context
  }

  /// The `AnimationProgressTime` for the given `AnimationFrameTime` within this layer,
  /// accounting for the `simpleTimeRemapping` applied to this layer.
  func progressTime(for frame: NEAnimationFrameTime) throws -> NEAnimationProgressTime {
    try compatibilityAssert(
      !mustUseComplexTimeRemapping,
      "NELayerAnimationContext.time(forFrame:) does not support complex time remapping"
    )

    let animationFrameCount = animationDuration * animation.framerate
    return (simpleTimeRemapping(frame) - animation.startFrame) / animationFrameCount
  }

  /// The real-time `TimeInterval` for the given `AnimationFrameTime` within this layer,
  /// accounting for the `simpleTimeRemapping` applied to this layer.
  func time(forFrame frame: NEAnimationFrameTime) throws -> TimeInterval {
    try compatibilityAssert(
      !mustUseComplexTimeRemapping,
      "NELayerAnimationContext.time(forFrame:) does not support complex time remapping"
    )

    return animation.time(forFrame: simpleTimeRemapping(frame))
  }

  /// Chains an additional time remapping closure onto the `simpleTimeRemapping` closure
  func withSimpleTimeRemapping(
    _ additionalSimpleTimeRemapping: @escaping (_ localTime: NEAnimationFrameTime) -> NEAnimationFrameTime)
    -> NELayerAnimationContext {
    var copy = self
    copy.simpleTimeRemapping = { [existingSimpleTimeRemapping = simpleTimeRemapping] time in
      existingSimpleTimeRemapping(additionalSimpleTimeRemapping(time))
    }
    return copy
  }

  /// Chains an additional time remapping closure onto the `complexTimeRemapping` closure.
  ///  - If `required` is `true`, all subsequent child layers will be required to use the expensive
  ///    `complexTimeRemapping` / `NEKeyframes.manuallyInterpolatedWithTimeRemapping` codepath.
  ///  - `required: true` is necessary when this time remapping is not available via `simpleTimeRemapping`.
  func withComplexTimeRemapping(required: Bool,
                                _ additionalComplexTimeRemapping: @escaping (_ globalTime: NEAnimationFrameTime) -> NEAnimationFrameTime)
    -> NELayerAnimationContext {
    var copy = self
    copy.mustUseComplexTimeRemapping = copy.mustUseComplexTimeRemapping || required
    copy.complexTimeRemapping = { [existingComplexTimeRemapping = complexTimeRemapping] time in
      additionalComplexTimeRemapping(existingComplexTimeRemapping(time))
    }
    return copy
  }

  /// Returns a copy of this context with time remapping removed
  func withoutTimeRemapping() -> NELayerAnimationContext {
    var copy = self
    copy.simpleTimeRemapping = { $0 }
    copy.complexTimeRemapping = { $0 }
    copy.mustUseComplexTimeRemapping = false
    return copy
  }
}

// MARK: - NELoggingState

/// Mutable state related to log events, stored on the `NECoreAnimationLayer`.
final class NELoggingState {
  // MARK: Lifecycle

  init() {}

  // MARK: Internal

  /// Whether or not the warning about unsupported After Effects expressions
  /// has been logged yet for this layer.
  var hasLoggedAfterEffectsExpressionsWarning = false
}
