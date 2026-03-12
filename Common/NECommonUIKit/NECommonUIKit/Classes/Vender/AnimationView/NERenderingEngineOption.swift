// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NERenderingEngineOption

public enum NERenderingEngineOption: Hashable {
  /// Uses the Core Animation engine for supported animations, and falls back to using
  /// the Main Thread engine for animations that use features not supported by the
  /// Core Animation engine.
  case automatic

  /// Uses the specified rendering engine
  case specific(NERenderingEngine)

  // MARK: Public

  /// The Main Thread rendering engine, which supports all Lottie features
  /// but runs on the main thread, which comes with some CPU overhead and
  /// can cause the animation to play at a low framerate when the CPU is busy.
  public static var mainThread: NERenderingEngineOption { .specific(.mainThread) }

  /// The Core Animation rendering engine, that animates using Core Animation
  /// and has better performance characteristics than the Main Thread engine,
  /// but doesn't support all Lottie features.
  ///  - In general, prefer using `NERenderingEngineOption.automatic` over
  ///    `NERenderingEngineOption.coreAnimation`. The Core Animation rendering
  ///    engine doesn't support all features supported by the Main Thread
  ///    rendering engine. When using `NERenderingEngineOption.automatic`,
  ///    Lottie will automatically fall back to the Main Thread engine
  ///    when necessary.
  public static var coreAnimation: NERenderingEngineOption { .specific(.coreAnimation) }
}

// MARK: - NERenderingEngine

/// The rendering engine implementation to use when displaying an animation
public enum NERenderingEngine: Hashable {
  /// The Main Thread rendering engine, which supports all Lottie features
  /// but runs on the main thread, which comes with some CPU overhead and
  /// can cause the animation to play at a low framerate when the CPU is busy.
  case mainThread

  /// The Core Animation rendering engine, that animates using Core Animation
  /// and has better performance characteristics than the Main Thread engine,
  /// but doesn't support all Lottie features.
  case coreAnimation
}

// MARK: - NERenderingEngineOption + RawRepresentable, CustomStringConvertible

extension NERenderingEngineOption: RawRepresentable, CustomStringConvertible {
  // MARK: Lifecycle

  public init?(rawValue: String) {
    if rawValue == "Automatic" {
      self = .automatic
    } else if let engine = NERenderingEngine(rawValue: rawValue) {
      self = .specific(engine)
    } else {
      return nil
    }
  }

  // MARK: Public

  public var rawValue: String {
    switch self {
    case .automatic:
      return "Automatic"
    case let .specific(engine):
      return engine.rawValue
    }
  }

  public var description: String {
    rawValue
  }
}

// MARK: - NERenderingEngine + RawRepresentable, CustomStringConvertible

extension NERenderingEngine: RawRepresentable, CustomStringConvertible {
  // MARK: Lifecycle

  public init?(rawValue: String) {
    switch rawValue {
    case "Main Thread":
      self = .mainThread
    case "Core Animation":
      self = .coreAnimation
    default:
      return nil
    }
  }

  // MARK: Public

  public var rawValue: String {
    switch self {
    case .mainThread:
      return "Main Thread"
    case .coreAnimation:
      return "Core Animation"
    }
  }

  public var description: String {
    rawValue
  }
}
