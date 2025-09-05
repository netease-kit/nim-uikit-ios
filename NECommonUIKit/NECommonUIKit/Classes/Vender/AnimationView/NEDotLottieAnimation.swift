
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

// MARK: - NEDotLottieAnimation

struct NEDotLottieAnimation: Codable {
  /// Id of Animation
  var id: String

  /// Loop enabled
  var loop: Bool? = false

  /// Animation Playback Speed
  var speed: Double? = 1

  /// 1 or -1
  var direction: Int? = 1

  /// mode - "bounce" | "normal"
  var mode: NEDotLottieAnimationMode? = .normal

  /// Loop mode for animation
  var loopMode: NELottieLoopMode {
    switch mode {
    case .bounce:
      return .autoReverse
    case .normal, nil:
      return (loop ?? false) ? .loop : .playOnce
    }
  }

  /// Animation speed
  var animationSpeed: Double {
    (speed ?? 1) * Double(direction ?? 1)
  }

  /// Loads `NELottieAnimation` from `animationUrl`
  /// - Returns: Deserialized `NELottieAnimation`. Optional.
  func animation(url: URL) throws -> NELottieAnimation {
    let animationUrl = url.appendingPathComponent("\(id).json")
    let data = try Data(contentsOf: animationUrl)
    return try NELottieAnimation.from(data: data)
  }
}

// MARK: - NEDotLottieAnimationMode

enum NEDotLottieAnimationMode: String, Codable {
  case normal
  case bounce
}
