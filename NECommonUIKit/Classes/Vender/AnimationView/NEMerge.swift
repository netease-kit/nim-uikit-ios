// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEMergeMode

enum NEMergeMode: Int, Codable, Sendable {
  case none
  case merge
  case add
  case subtract
  case intersect
  case exclude
}

// MARK: - NEMerge

final class NEMerge: NEShapeItem {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NEMerge.NECodingKeys.self)
    mode = try container.decode(NEMergeMode.self, forKey: .mode)
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    let modeRawType: Int = try dictionary.value(for: NECodingKeys.mode)
    guard let mode = NEMergeMode(rawValue: modeRawType) else {
      throw NEInitializableError.invalidInput()
    }
    self.mode = mode
    try super.init(dictionary: dictionary)
  }

  // MARK: Internal

  /// The mode of the merge path
  let mode: NEMergeMode

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: NECodingKeys.self)
    try container.encode(mode, forKey: .mode)
  }

  // MARK: Private

  private enum NECodingKeys: String, CodingKey {
    case mode = "mm"
  }
}
