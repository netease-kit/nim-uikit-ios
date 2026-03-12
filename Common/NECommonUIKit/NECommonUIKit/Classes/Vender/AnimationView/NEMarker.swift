// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// A time marker
final class NEMarker: Codable, Sendable, NEDictionaryInitializable {
  // MARK: Lifecycle

  init(dictionary: [String: Any]) throws {
    name = try dictionary.value(for: NECodingKeys.name)
    frameTime = try dictionary.value(for: NECodingKeys.frameTime)
    durationFrameTime = try dictionary.value(for: NECodingKeys.durationFrameTime)
  }

  // MARK: Internal

  enum NECodingKeys: String, CodingKey {
    case name = "cm"
    case frameTime = "tm"
    case durationFrameTime = "dr"
  }

  /// The NEMarker Name
  let name: String

  /// The Frame time of the marker
  let frameTime: NEAnimationFrameTime

  /// The duration of the marker, in frames.
  let durationFrameTime: NEAnimationFrameTime
}
