
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NECompatibilityIssue

/// A compatibility issue that was encountered while setting up an animation with the Core Animation engine
struct NECompatibilityIssue: CustomStringConvertible {
  let message: String
  let context: String

  var description: String {
    "[\(context)] \(message)"
  }
}

// MARK: - NECompatibilityTracker

/// A type that tracks whether or not an animation is compatible with the Core Animation engine
final class NECompatibilityTracker {
  // MARK: Lifecycle

  init(mode: NEMode, logger: NELottieLogger) {
    self.mode = mode
    self.logger = logger
  }

  // MARK: Internal

  /// How compatibility issues should be handled
  enum NEMode {
    /// When a compatibility issue is encountered, an error will be thrown immediately,
    /// aborting the animation setup process as soon as possible.
    case abort

    /// When a compatibility issue is encountered, it is stored in `NECompatibilityTracker.issues`
    case track
  }

  enum Error: Swift.Error {
    case encounteredCompatibilityIssue(NECompatibilityIssue)
  }

  /// Records a compatibility issue that will be reported according to `CompatibilityTracker.Mode`
  func logIssue(message: String, context: String) throws {
    logger.assert(!context.isEmpty, "Compatibility issue context is unexpectedly empty")

    let issue = NECompatibilityIssue(
      // Compatibility messages are usually written in source files using multi-line strings,
      // but converting them to be a single line makes it easier to read the ultimate log output.
      message: message.replacingOccurrences(of: "\n", with: " "),
      context: context
    )

    switch mode {
    case .abort:
      throw NECompatibilityTracker.Error.encounteredCompatibilityIssue(issue)
    case .track:
      issues.append(issue)
    }
  }

  /// Asserts that a condition is true, otherwise logs a compatibility issue that will be reported
  /// according to `CompatibilityTracker.Mode`
  func assert(_ condition: Bool,
              _ message: @autoclosure () -> String,
              context: @autoclosure () -> String)
    throws {
    if !condition {
      try logIssue(message: message(), context: context())
    }
  }

  /// Reports the compatibility issues that were recorded when setting up the animation,
  /// and clears the set of tracked issues.
  func reportCompatibilityIssues(_ handler: ([NECompatibilityIssue]) -> Void) {
    handler(issues)
    issues = []
  }

  // MARK: Private

  private let mode: NEMode
  private let logger: NELottieLogger

  /// Compatibility issues encountered while setting up the animation
  private var issues = [NECompatibilityIssue]()
}

// MARK: - NECompatibilityTrackerProviding

protocol NECompatibilityTrackerProviding {
  var compatibilityTracker: NECompatibilityTracker { get }
  var compatibilityIssueContext: String { get }
}

extension NECompatibilityTrackerProviding {
  /// Records a compatibility issue that will be reported according to `NECompatibilityTracker.NEMode`
  func logCompatibilityIssue(_ message: String) throws {
    try compatibilityTracker.logIssue(message: message, context: compatibilityIssueContext)
  }

  /// Asserts that a condition is true, otherwise logs a compatibility issue that will be reported
  /// according to `NECompatibilityTracker.NEMode`
  func compatibilityAssert(_ condition: Bool,
                           _ message: @autoclosure () -> String)
    throws {
    try compatibilityTracker.assert(condition, message(), context: compatibilityIssueContext)
  }
}

// MARK: - NELayerContext + NECompatibilityTrackerProviding

extension NELayerContext: NECompatibilityTrackerProviding {
  var compatibilityIssueContext: String {
    layerName
  }
}

// MARK: - LayerAnimationContext + NECompatibilityTrackerProviding

extension NELayerAnimationContext: NECompatibilityTrackerProviding {
  var compatibilityIssueContext: String {
    currentKeypath.fullPath
  }
}
