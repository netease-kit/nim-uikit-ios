// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEPathDirection

enum NEPathDirection: Int, Codable {
  case clockwise = 1
  case userSetClockwise = 2
  case counterClockwise = 3
}

// MARK: - NEEllipse

final class NEEllipse: NEShapeItem {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NEEllipse.NECodingKeys.self)
    direction = try container.decodeIfPresent(NEPathDirection.self, forKey: .direction) ?? .clockwise
    position = try container.decode(NEKeyframeGroup<NELottieVector3D>.self, forKey: .position)
    size = try container.decode(NEKeyframeGroup<NELottieVector3D>.self, forKey: .size)
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    if
      let directionRawType = dictionary[NECodingKeys.direction.rawValue] as? Int,
      let direction = NEPathDirection(rawValue: directionRawType) {
      self.direction = direction
    } else {
      direction = .clockwise
    }
    let positionDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.position)
    position = try NEKeyframeGroup<NELottieVector3D>(dictionary: positionDictionary)
    let sizeDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.size)
    size = try NEKeyframeGroup<NELottieVector3D>(dictionary: sizeDictionary)
    try super.init(dictionary: dictionary)
  }

  // MARK: Internal

  /// The direction of the ellipse.
  let direction: NEPathDirection

  /// The position of the ellipse
  let position: NEKeyframeGroup<NELottieVector3D>

  /// The size of the ellipse
  let size: NEKeyframeGroup<NELottieVector3D>

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: NECodingKeys.self)
    try container.encode(direction, forKey: .direction)
    try container.encode(position, forKey: .position)
    try container.encode(size, forKey: .size)
  }

  // MARK: Private

  private enum NECodingKeys: String, CodingKey {
    case direction = "d"
    case position = "p"
    case size = "s"
  }
}
