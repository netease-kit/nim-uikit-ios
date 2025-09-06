// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEStarType

enum NEStarType: Int, Codable, Sendable {
  case none
  case star
  case polygon
}

// MARK: - NEStar

final class NEStar: NEShapeItem {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NEStar.NECodingKeys.self)
    direction = try container.decodeIfPresent(NEPathDirection.self, forKey: .direction) ?? .clockwise
    position = try container.decode(NEKeyframeGroup<NELottieVector3D>.self, forKey: .position)
    outerRadius = try container.decode(NEKeyframeGroup<NELottieVector1D>.self, forKey: .outerRadius)
    outerRoundness = try container.decode(NEKeyframeGroup<NELottieVector1D>.self, forKey: .outerRoundness)
    innerRadius = try container.decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .innerRadius)
    innerRoundness = try container.decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .innerRoundness)
    rotation = try container.decode(NEKeyframeGroup<NELottieVector1D>.self, forKey: .rotation)
    points = try container.decode(NEKeyframeGroup<NELottieVector1D>.self, forKey: .points)
    starType = try container.decode(NEStarType.self, forKey: .starType)
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    if
      let directionRawValue = dictionary[NECodingKeys.direction.rawValue] as? Int,
      let direction = NEPathDirection(rawValue: directionRawValue) {
      self.direction = direction
    } else {
      direction = .clockwise
    }
    let positionDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.position)
    position = try NEKeyframeGroup<NELottieVector3D>(dictionary: positionDictionary)
    let outerRadiusDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.outerRadius)
    outerRadius = try NEKeyframeGroup<NELottieVector1D>(dictionary: outerRadiusDictionary)
    let outerRoundnessDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.outerRoundness)
    outerRoundness = try NEKeyframeGroup<NELottieVector1D>(dictionary: outerRoundnessDictionary)
    if let innerRadiusDictionary = dictionary[NECodingKeys.innerRadius.rawValue] as? [String: Any] {
      innerRadius = try NEKeyframeGroup<NELottieVector1D>(dictionary: innerRadiusDictionary)
    } else {
      innerRadius = nil
    }
    if let innerRoundnessDictionary = dictionary[NECodingKeys.innerRoundness.rawValue] as? [String: Any] {
      innerRoundness = try NEKeyframeGroup<NELottieVector1D>(dictionary: innerRoundnessDictionary)
    } else {
      innerRoundness = nil
    }
    let rotationDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.rotation)
    rotation = try NEKeyframeGroup<NELottieVector1D>(dictionary: rotationDictionary)
    let pointsDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.points)
    points = try NEKeyframeGroup<NELottieVector1D>(dictionary: pointsDictionary)
    let starTypeRawValue: Int = try dictionary.value(for: NECodingKeys.starType)
    guard let starType = NEStarType(rawValue: starTypeRawValue) else {
      throw NEInitializableError.invalidInput()
    }
    self.starType = starType
    try super.init(dictionary: dictionary)
  }

  // MARK: Internal

  /// The direction of the star.
  let direction: NEPathDirection

  /// The position of the star
  let position: NEKeyframeGroup<NELottieVector3D>

  /// The outer radius of the star
  let outerRadius: NEKeyframeGroup<NELottieVector1D>

  /// The outer roundness of the star
  let outerRoundness: NEKeyframeGroup<NELottieVector1D>

  /// The outer radius of the star
  let innerRadius: NEKeyframeGroup<NELottieVector1D>?

  /// The outer roundness of the star
  let innerRoundness: NEKeyframeGroup<NELottieVector1D>?

  /// The rotation of the star
  let rotation: NEKeyframeGroup<NELottieVector1D>

  /// The number of points on the star
  let points: NEKeyframeGroup<NELottieVector1D>

  /// The type of star
  let starType: NEStarType

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: NECodingKeys.self)
    try container.encode(direction, forKey: .direction)
    try container.encode(position, forKey: .position)
    try container.encode(outerRadius, forKey: .outerRadius)
    try container.encode(outerRoundness, forKey: .outerRoundness)
    try container.encode(innerRadius, forKey: .innerRadius)
    try container.encode(innerRoundness, forKey: .innerRoundness)
    try container.encode(rotation, forKey: .rotation)
    try container.encode(points, forKey: .points)
    try container.encode(starType, forKey: .starType)
  }

  // MARK: Private

  private enum NECodingKeys: String, CodingKey {
    case direction = "d"
    case position = "p"
    case outerRadius = "or"
    case outerRoundness = "os"
    case innerRadius = "ir"
    case innerRoundness = "is"
    case rotation = "r"
    case points = "pt"
    case starType = "sy"
  }
}
