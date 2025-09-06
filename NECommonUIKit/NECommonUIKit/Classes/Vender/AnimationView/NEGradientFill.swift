// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEGradientType

enum NEGradientType: Int, Codable, Sendable {
  case none
  case linear
  case radial
}

// MARK: - NEGradientFill

final class NEGradientFill: NEShapeItem {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NEGradientFill.NECodingKeys.self)
    opacity = try container.decode(NEKeyframeGroup<NELottieVector1D>.self, forKey: .opacity)
    startPoint = try container.decode(NEKeyframeGroup<NELottieVector3D>.self, forKey: .startPoint)
    endPoint = try container.decode(NEKeyframeGroup<NELottieVector3D>.self, forKey: .endPoint)
    gradientType = try container.decode(NEGradientType.self, forKey: .gradientType)
    highlightLength = try container.decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .highlightLength)
    highlightAngle = try container.decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .highlightAngle)
    fillRule = try container.decodeIfPresent(NEFillRule.self, forKey: .fillRule) ?? .nonZeroWinding
    let colorsContainer = try container.nestedContainer(keyedBy: GradientDataKeys.self, forKey: .colors)
    colors = try colorsContainer.decode(NEKeyframeGroup<[Double]>.self, forKey: .colors)
    numberOfColors = try colorsContainer.decode(Int.self, forKey: .numberOfColors)
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    let opacityDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.opacity)
    opacity = try NEKeyframeGroup<NELottieVector1D>(dictionary: opacityDictionary)
    let startPointDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.startPoint)
    startPoint = try NEKeyframeGroup<NELottieVector3D>(dictionary: startPointDictionary)
    let endPointDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.endPoint)
    endPoint = try NEKeyframeGroup<NELottieVector3D>(dictionary: endPointDictionary)
    let gradientRawType: Int = try dictionary.value(for: NECodingKeys.gradientType)
    guard let gradient = NEGradientType(rawValue: gradientRawType) else {
      throw NEInitializableError.invalidInput()
    }
    gradientType = gradient
    if let highlightLengthDictionary = dictionary[NECodingKeys.highlightLength.rawValue] as? [String: Any] {
      highlightLength = try? NEKeyframeGroup<NELottieVector1D>(dictionary: highlightLengthDictionary)
    } else {
      highlightLength = nil
    }
    if let highlightAngleDictionary = dictionary[NECodingKeys.highlightAngle.rawValue] as? [String: Any] {
      highlightAngle = try? NEKeyframeGroup<NELottieVector1D>(dictionary: highlightAngleDictionary)
    } else {
      highlightAngle = nil
    }
    let colorsDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.colors)
    let nestedColorsDictionary: [String: Any] = try colorsDictionary.value(for: GradientDataKeys.colors)
    colors = try NEKeyframeGroup<[Double]>(dictionary: nestedColorsDictionary)
    numberOfColors = try colorsDictionary.value(for: GradientDataKeys.numberOfColors)
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

  /// The start of the gradient
  let startPoint: NEKeyframeGroup<NELottieVector3D>

  /// The end of the gradient
  let endPoint: NEKeyframeGroup<NELottieVector3D>

  /// The type of gradient
  let gradientType: NEGradientType

  /// Gradient Highlight Length. Only if type is Radial
  let highlightLength: NEKeyframeGroup<NELottieVector1D>?

  /// Highlight Angle. Only if type is Radial
  let highlightAngle: NEKeyframeGroup<NELottieVector1D>?

  /// The number of color points in the gradient
  let numberOfColors: Int

  /// The Colors of the gradient.
  let colors: NEKeyframeGroup<[Double]>

  /// The fill rule to use when filling a path
  let fillRule: NEFillRule

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: NECodingKeys.self)
    try container.encode(opacity, forKey: .opacity)
    try container.encode(startPoint, forKey: .startPoint)
    try container.encode(endPoint, forKey: .endPoint)
    try container.encode(gradientType, forKey: .gradientType)
    try container.encodeIfPresent(highlightLength, forKey: .highlightLength)
    try container.encodeIfPresent(highlightAngle, forKey: .highlightAngle)
    try container.encodeIfPresent(fillRule, forKey: .fillRule)
    var colorsContainer = container.nestedContainer(keyedBy: GradientDataKeys.self, forKey: .colors)
    try colorsContainer.encode(numberOfColors, forKey: .numberOfColors)
    try colorsContainer.encode(colors, forKey: .colors)
  }

  // MARK: Private

  private enum NECodingKeys: String, CodingKey {
    case opacity = "o"
    case startPoint = "s"
    case endPoint = "e"
    case gradientType = "t"
    case highlightLength = "h"
    case highlightAngle = "a"
    case colors = "g"
    case fillRule = "r"
  }

  private enum GradientDataKeys: String, CodingKey {
    case numberOfColors = "p"
    case colors = "k"
  }
}
