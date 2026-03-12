// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

// MARK: - NELottiePlaybackMode

/// Configuration for how a Lottie animation should be played
public enum NELottiePlaybackMode: Hashable {
  /// The animation is paused at the given state (e.g. paused at a specific frame)
  case paused(at: PausedState)

  /// The animation is playing using the given playback mode (e.g. looping from the start to the end)
  case playing(_ mode: PlaybackMode)

  @available(*, deprecated, renamed: "NELottiePlaybackMode.paused(at:)", message: "Will be removed in a future major release.")
  case progress(_ progress: NEAnimationProgressTime)

  @available(*, deprecated, renamed: "NELottiePlaybackMode.paused(at:)", message: "Will be removed in a future major release.")
  case frame(_ frame: NEAnimationFrameTime)

  @available(*, deprecated, renamed: "NELottiePlaybackMode.paused(at:)", message: "Will be removed in a future major release.")
  case time(_ time: TimeInterval)

  @available(*, deprecated, renamed: "NELottiePlaybackMode.paused(at:)", message: "Will be removed in a future major release.")
  case pause

  @available(*, deprecated, renamed: "NELottiePlaybackMode.playing(_:)", message: "Will be removed in a future major release.")
  case fromProgress(_ fromProgress: NEAnimationProgressTime?, toProgress: NEAnimationProgressTime, loopMode: NELottieLoopMode)

  @available(*, deprecated, renamed: "NELottiePlaybackMode.playing(_:)", message: "Will be removed in a future major release.")
  case fromFrame(_ fromFrame: NEAnimationFrameTime?, toFrame: NEAnimationFrameTime, loopMode: NELottieLoopMode)

  @available(*, deprecated, renamed: "NELottiePlaybackMode.playing(_:)", message: "Will be removed in a future major release.")
  case fromMarker(
    _ fromMarker: String?,
    toMarker: String,
    playEndMarkerFrame: Bool = true,
    loopMode: NELottieLoopMode
  )

  @available(*, deprecated, renamed: "NELottiePlaybackMode.playing(_:)", message: "Will be removed in a future major release.")
  case marker(_ marker: String, loopMode: NELottieLoopMode)

  @available(*, deprecated, renamed: "NELottiePlaybackMode.playing(_:)", message: "Will be removed in a future major release.")
  case markers(_ markers: [String])

  // MARK: Public

  public enum PausedState: Hashable {
    /// Any existing animation will be paused at the current frame.
    case currentFrame

    /// The animation is paused at the given progress value,
    /// a value between 0.0 (0% progress) and 1.0 (100% progress).
    case progress(_ progress: NEAnimationProgressTime)

    /// The animation is paused at the given frame of the animation.
    case frame(_ frame: NEAnimationFrameTime)

    /// The animation is paused at the given time value from the start of the animation.
    case time(_ time: TimeInterval)

    /// Pauses the animation at a given marker and position
    case marker(_ name: String, position: NELottieMarkerPosition = .start)
  }

  public enum PlaybackMode: Hashable {
    /// Plays the animation from a progress (0-1) to a progress (0-1).
    /// - Parameter fromProgress: The start progress of the animation. If `nil` the animation will start at the current progress.
    /// - Parameter toProgress: The end progress of the animation.
    /// - Parameter loopMode: The loop behavior of the animation.
    case fromProgress(
      _ fromProgress: NEAnimationProgressTime?,
      toProgress: NEAnimationProgressTime,
      loopMode: NELottieLoopMode
    )

    /// The animation plays from the given `fromFrame` to the given `toFrame`.
    /// - Parameter fromFrame: The start frame of the animation. If `nil` the animation will start at the current frame.
    /// - Parameter toFrame: The end frame of the animation.
    /// - Parameter loopMode: The loop behavior of the animation.
    case fromFrame(
      _ fromFrame: NEAnimationFrameTime?,
      toFrame: NEAnimationFrameTime,
      loopMode: NELottieLoopMode
    )

    /// Plays the animation from a named marker to another marker.
    ///
    /// Markers are point in time that are encoded into the Animation data and assigned a name.
    ///
    /// NOTE: If markers are not found the play command will exit.
    ///
    /// - Parameter fromMarker: The start marker for the animation playback. If `nil` the
    /// animation will start at the current progress.
    /// - Parameter toMarker: The end marker for the animation playback.
    /// - Parameter playEndMarkerFrame: A flag to determine whether or not to play the frame of the end marker. If the
    /// end marker represents the end of the section to play, it should be to true. If the provided end marker
    /// represents the beginning of the next section, it should be false.
    /// - Parameter loopMode: The loop behavior of the animation.
    case fromMarker(
      _ fromMarker: String?,
      toMarker: String,
      playEndMarkerFrame: Bool = true,
      loopMode: NELottieLoopMode
    )

    /// Plays the animation from a named marker to the end of the marker's duration.
    ///
    /// A marker is a point in time with an associated duration that is encoded into the
    /// animation data and assigned a name.
    ///
    /// NOTE: If marker is not found the play command will exit.
    ///
    /// - Parameter marker: The start marker for the animation playback.
    /// - Parameter loopMode: The loop behavior of the animation.
    case marker(
      _ marker: String,
      loopMode: NELottieLoopMode
    )

    /// Plays the given markers sequentially in order.
    ///
    /// A marker is a point in time with an associated duration that is encoded into the
    /// animation data and assigned a name. Multiple markers can be played sequentially
    /// to create programmable animations.
    ///
    /// If a marker is not found, it will be skipped.
    ///
    /// If a marker doesn't have a duration value, it will play with a duration of 0
    /// (effectively being skipped).
    ///
    /// If another animation is played (by calling any `play` method) while this
    /// marker sequence is playing, the marker sequence will be cancelled.
    ///
    /// - Parameter markers: The list of markers to play sequentially.
    case markers(_ markers: [String])
  }
}

public extension NELottiePlaybackMode {
  static var paused: Self {
    .paused(at: .currentFrame)
  }

  @available(*, deprecated, renamed: "NELottiePlaybackMode.playing(_:)", message: "Will be removed in a future major release.")
  static func toProgress(_ toProgress: NEAnimationProgressTime, loopMode: NELottieLoopMode) -> NELottiePlaybackMode {
    .playing(.fromProgress(nil, toProgress: toProgress, loopMode: loopMode))
  }

  @available(*, deprecated, renamed: "NELottiePlaybackMode.playing(_:)", message: "Will be removed in a future major release.")
  static func toFrame(_ toFrame: NEAnimationFrameTime, loopMode: NELottieLoopMode) -> NELottiePlaybackMode {
    .playing(.fromFrame(nil, toFrame: toFrame, loopMode: loopMode))
  }

  @available(*, deprecated, renamed: "NELottiePlaybackMode.playing(_:)", message: "Will be removed in a future major release.")
  static func toMarker(_ toMarker: String,
                       playEndMarkerFrame: Bool = true,
                       loopMode: NELottieLoopMode)
    -> NELottiePlaybackMode {
    .playing(.fromMarker(nil, toMarker: toMarker, playEndMarkerFrame: playEndMarkerFrame, loopMode: loopMode))
  }
}

public extension NELottiePlaybackMode.PlaybackMode {
  /// Plays the animation from the current progress to a progress value (0-1).
  /// - Parameter toProgress: The end progress of the animation.
  /// - Parameter loopMode: The loop behavior of the animation.
  static func toProgress(_ toProgress: NEAnimationProgressTime, loopMode: NELottieLoopMode) -> Self {
    .fromProgress(nil, toProgress: toProgress, loopMode: loopMode)
  }

  // Plays the animation from the current frame to the given frame.
  /// - Parameter toFrame: The end frame of the animation.
  /// - Parameter loopMode: The loop behavior of the animation.
  static func toFrame(_ toFrame: NEAnimationFrameTime, loopMode: NELottieLoopMode) -> Self {
    .fromFrame(nil, toFrame: toFrame, loopMode: loopMode)
  }

  /// Plays the animation from the current frame to some marker.
  ///
  /// Markers are point in time that are encoded into the Animation data and assigned a name.
  ///
  /// NOTE: If the marker isn't found the play command will exit.
  ///
  /// - Parameter toMarker: The end marker for the animation playback.
  /// - Parameter playEndMarkerFrame: A flag to determine whether or not to play the frame of the end marker. If the
  /// end marker represents the end of the section to play, it should be to true. If the provided end marker
  /// represents the beginning of the next section, it should be false.
  /// - Parameter loopMode: The loop behavior of the animation.
  static func toMarker(_ toMarker: String,
                       playEndMarkerFrame: Bool = true,
                       loopMode: NELottieLoopMode)
    -> Self {
    .fromMarker(nil, toMarker: toMarker, playEndMarkerFrame: playEndMarkerFrame, loopMode: loopMode)
  }
}

// MARK: - NELottieMarkerPosition

/// The position within a marker.
public enum NELottieMarkerPosition: Hashable {
  case start
  case end
}

extension NELottiePlaybackMode {
  /// Returns a copy of this `PlaybackMode` with the `NELottieLoopMode` updated to the given value
  func loopMode(_ updatedLoopMode: NELottieLoopMode) -> NELottiePlaybackMode {
    switch self {
    case let .playing(playbackMode):
      return .playing(playbackMode.loopMode(updatedLoopMode))

    case let .fromProgress(fromProgress, toProgress: toProgress, _):
      return .playing(.fromProgress(
        fromProgress,
        toProgress: toProgress,
        loopMode: updatedLoopMode
      ))

    case let .fromFrame(fromFrame, toFrame: toFrame, _):
      return .playing(.fromFrame(
        fromFrame,
        toFrame: toFrame,
        loopMode: updatedLoopMode
      ))

    case let .fromMarker(fromMarker, toMarker, playEndMarkerFrame, _):
      return .playing(.fromMarker(
        fromMarker,
        toMarker: toMarker,
        playEndMarkerFrame: playEndMarkerFrame,
        loopMode: updatedLoopMode
      ))

    case let .marker(marker, _):
      return .playing(.marker(marker, loopMode: updatedLoopMode))

    case .pause, .paused, .progress(_), .time(_), .frame(_), .markers:
      return self
    }
  }
}

extension NELottiePlaybackMode.PlaybackMode {
  /// Returns a copy of this `PlaybackMode` with the `NELottieLoopMode` updated to the given value
  func loopMode(_ updatedLoopMode: NELottieLoopMode) -> NELottiePlaybackMode.PlaybackMode {
    switch self {
    case let .fromProgress(fromProgress, toProgress, _):
      return .fromProgress(fromProgress, toProgress: toProgress, loopMode: updatedLoopMode)
    case let .fromFrame(fromFrame, toFrame, _):
      return .fromFrame(fromFrame, toFrame: toFrame, loopMode: updatedLoopMode)
    case let .fromMarker(fromMarker, toMarker, playEndMarkerFrame, _):
      return .fromMarker(fromMarker, toMarker: toMarker, playEndMarkerFrame: playEndMarkerFrame, loopMode: updatedLoopMode)
    case let .marker(marker, _):
      return .marker(marker, loopMode: updatedLoopMode)
    case .markers:
      return self
    }
  }
}
