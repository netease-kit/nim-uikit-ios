// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

final class NERectangle: NEShapeItem {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NERectangle.NECodingKeys.self)
    direction = try container.decodeIfPresent(NEPathDirection.self, forKey: .direction) ?? .clockwise
    position = try container.decode(NEKeyframeGroup<NELottieVector3D>.self, forKey: .position)
    size = try container.decode(NEKeyframeGroup<NELottieVector3D>.self, forKey: .size)
    cornerRadius = try container.decode(NEKeyframeGroup<NELottieVector1D>.self, forKey: .cornerRadius)
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
    let cornerRadiusDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.cornerRadius)
    cornerRadius = try NEKeyframeGroup<NELottieVector1D>(dictionary: cornerRadiusDictionary)
    try super.init(dictionary: dictionary)
  }

  // MARK: Internal

  /// The direction of the rect.
  let direction: NEPathDirection

  /// The position
  let position: NEKeyframeGroup<NELottieVector3D>

  /// The size
  let size: NEKeyframeGroup<NELottieVector3D>

  /// The Corner radius of the rectangle
  let cornerRadius: NEKeyframeGroup<NELottieVector1D>

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: NECodingKeys.self)
    try container.encode(direction, forKey: .direction)
    try container.encode(position, forKey: .position)
    try container.encode(size, forKey: .size)
    try container.encode(cornerRadius, forKey: .cornerRadius)
  }

  // MARK: Private

  private enum NECodingKeys: String, CodingKey {
    case direction = "d"
    case position = "p"
    case size = "s"
    case cornerRadius = "r"
  }
}
