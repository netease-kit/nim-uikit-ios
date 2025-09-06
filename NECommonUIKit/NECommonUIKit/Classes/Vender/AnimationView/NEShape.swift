// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// An item that defines an custom shape
final class NEShape: NEShapeItem {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NEShape.NECodingKeys.self)
    path = try container.decode(NEKeyframeGroup<NEBezierPath>.self, forKey: .path)
    direction = try container.decodeIfPresent(NEPathDirection.self, forKey: .direction)
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    let pathDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.path)
    path = try NEKeyframeGroup<NEBezierPath>(dictionary: pathDictionary)
    if
      let directionRawValue = dictionary[NECodingKeys.direction.rawValue] as? Int,
      let direction = NEPathDirection(rawValue: directionRawValue) {
      self.direction = direction
    } else {
      direction = nil
    }
    try super.init(dictionary: dictionary)
  }

  // MARK: Internal

  /// The Path
  let path: NEKeyframeGroup<NEBezierPath>

  let direction: NEPathDirection?

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: NECodingKeys.self)
    try container.encode(path, forKey: .path)
    try container.encodeIfPresent(direction, forKey: .direction)
  }

  // MARK: Private

  private enum NECodingKeys: String, CodingKey {
    case path = "ks"
    case direction = "d"
  }
}
