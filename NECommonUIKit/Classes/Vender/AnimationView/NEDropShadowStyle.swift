// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

final class NEDropShadowStyle: NELayerStyle {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NEDropShadowStyle.NECodingKeys.self)
    opacity = try container.decode(NEKeyframeGroup<NELottieVector1D>.self, forKey: .opacity)
    color = try container.decode(NEKeyframeGroup<NELottieColor>.self, forKey: .color)
    angle = try container.decode(NEKeyframeGroup<NELottieVector1D>.self, forKey: .angle)
    size = try container.decode(NEKeyframeGroup<NELottieVector1D>.self, forKey: .size)
    distance = try container.decode(NEKeyframeGroup<NELottieVector1D>.self, forKey: .distance)
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    let opacityDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.opacity)
    opacity = try NEKeyframeGroup<NELottieVector1D>(dictionary: opacityDictionary)
    let colorDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.color)
    color = try NEKeyframeGroup<NELottieColor>(dictionary: colorDictionary)
    let angleDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.angle)
    angle = try NEKeyframeGroup<NELottieVector1D>(dictionary: angleDictionary)
    let sizeDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.size)
    size = try NEKeyframeGroup<NELottieVector1D>(dictionary: sizeDictionary)
    let distanceDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.distance)
    distance = try NEKeyframeGroup<NELottieVector1D>(dictionary: distanceDictionary)
    try super.init(dictionary: dictionary)
  }

  // MARK: Internal

  /// The opacity of the drop shadow
  let opacity: NEKeyframeGroup<NELottieVector1D>

  /// The color of the drop shadow
  let color: NEKeyframeGroup<NELottieColor>

  /// The angle of the drop shadow, in degrees,
  /// with `0` representing a shadow straight-down from the layer
  /// (`offsetY=distance, offsetX=0`).
  let angle: NEKeyframeGroup<NELottieVector1D>

  /// The size of the drop shadow
  let size: NEKeyframeGroup<NELottieVector1D>

  /// The distance of the drop shadow
  let distance: NEKeyframeGroup<NELottieVector1D>

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: NECodingKeys.self)
    try container.encode(opacity, forKey: .opacity)
    try container.encode(color, forKey: .color)
    try container.encode(angle, forKey: .angle)
    try container.encode(size, forKey: .size)
    try container.encode(distance, forKey: .distance)
  }

  // MARK: Private

  private enum NECodingKeys: String, CodingKey {
    case color = "c"
    case opacity = "o"
    case angle = "a"
    case size = "s"
    case distance = "d"
  }
}
