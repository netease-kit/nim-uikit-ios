// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEFillRule

enum NEFillRule: Int, Codable {
  case none
  case nonZeroWinding
  case evenOdd
}

// MARK: - NEFill

final class NEFill: NEShapeItem {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NEFill.NECodingKeys.self)
    opacity = try container.decode(NEKeyframeGroup<NELottieVector1D>.self, forKey: .opacity)
    color = try container.decode(NEKeyframeGroup<NELottieColor>.self, forKey: .color)
    fillRule = try container.decodeIfPresent(NEFillRule.self, forKey: .fillRule) ?? .nonZeroWinding
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    let opacityDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.opacity)
    opacity = try NEKeyframeGroup<NELottieVector1D>(dictionary: opacityDictionary)
    let colorDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.color)
    color = try NEKeyframeGroup<NELottieColor>(dictionary: colorDictionary)
    if
      let fillRuleRawValue = dictionary[NECodingKeys.fillRule.rawValue] as? Int,
      let fillRule = NEFillRule(rawValue: fillRuleRawValue) {
      self.fillRule = fillRule
    } else {
      fillRule = .nonZeroWinding
    }
    try super.init(dictionary: dictionary)
  }

  // MARK: Internal

  /// The opacity of the fill
  let opacity: NEKeyframeGroup<NELottieVector1D>

  /// The color keyframes for the fill
  let color: NEKeyframeGroup<NELottieColor>

  /// The fill rule to use when filling a path
  let fillRule: NEFillRule

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: NECodingKeys.self)
    try container.encode(opacity, forKey: .opacity)
    try container.encode(color, forKey: .color)
    try container.encode(fillRule, forKey: .fillRule)
  }

  // MARK: Private

  private enum NECodingKeys: String, CodingKey {
    case opacity = "o"
    case color = "c"
    case fillRule = "r"
  }
}
