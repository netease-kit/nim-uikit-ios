// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

final class NEStroke: NEShapeItem {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NEStroke.NECodingKeys.self)
    opacity = try container.decode(NEKeyframeGroup<NELottieVector1D>.self, forKey: .opacity)
    color = try container.decode(NEKeyframeGroup<NELottieColor>.self, forKey: .color)
    width = try container.decode(NEKeyframeGroup<NELottieVector1D>.self, forKey: .width)
    lineCap = try container.decodeIfPresent(NELineCap.self, forKey: .lineCap) ?? .round
    lineJoin = try container.decodeIfPresent(NELineJoin.self, forKey: .lineJoin) ?? .round
    miterLimit = try container.decodeIfPresent(Double.self, forKey: .miterLimit) ?? 4
    dashPattern = try container.decodeIfPresent([NEDashElement].self, forKey: .dashPattern)
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    let opacityDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.opacity)
    opacity = try NEKeyframeGroup<NELottieVector1D>(dictionary: opacityDictionary)
    let colorDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.color)
    color = try NEKeyframeGroup<NELottieColor>(dictionary: colorDictionary)
    let widthDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.width)
    width = try NEKeyframeGroup<NELottieVector1D>(dictionary: widthDictionary)
    if
      let lineCapRawValue = dictionary[NECodingKeys.lineCap.rawValue] as? Int,
      let lineCap = NELineCap(rawValue: lineCapRawValue) {
      self.lineCap = lineCap
    } else {
      lineCap = .round
    }
    if
      let lineJoinRawValue = dictionary[NECodingKeys.lineJoin.rawValue] as? Int,
      let lineJoin = NELineJoin(rawValue: lineJoinRawValue) {
      self.lineJoin = lineJoin
    } else {
      lineJoin = .round
    }
    miterLimit = (try? dictionary.value(for: NECodingKeys.miterLimit)) ?? 4
    let dashPatternDictionaries = dictionary[NECodingKeys.dashPattern.rawValue] as? [[String: Any]]
    dashPattern = try? dashPatternDictionaries?.map { try NEDashElement(dictionary: $0) }
    try super.init(dictionary: dictionary)
  }

  init(name: String,
       hidden: Bool,
       opacity: NEKeyframeGroup<NELottieVector1D>,
       color: NEKeyframeGroup<NELottieColor>,
       width: NEKeyframeGroup<NELottieVector1D>,
       lineCap: NELineCap,
       lineJoin: NELineJoin,
       miterLimit: Double,
       dashPattern: [NEDashElement]?) {
    self.opacity = opacity
    self.color = color
    self.width = width
    self.lineCap = lineCap
    self.lineJoin = lineJoin
    self.miterLimit = miterLimit
    self.dashPattern = dashPattern
    super.init(name: name, type: .stroke, hidden: hidden)
  }

  // MARK: Internal

  /// The opacity of the stroke
  let opacity: NEKeyframeGroup<NELottieVector1D>

  /// The Color of the stroke
  let color: NEKeyframeGroup<NELottieColor>

  /// The width of the stroke
  let width: NEKeyframeGroup<NELottieVector1D>

  /// Line Cap
  let lineCap: NELineCap

  /// Line Join
  let lineJoin: NELineJoin

  /// Miter Limit
  let miterLimit: Double

  /// The dash pattern of the stroke
  let dashPattern: [NEDashElement]?

  /// Creates a copy of this NEStroke with the given updated width keyframes
  func copy(width newWidth: NEKeyframeGroup<NELottieVector1D>) -> NEStroke {
    NEStroke(
      name: name,
      hidden: hidden,
      opacity: opacity,
      color: color,
      width: newWidth,
      lineCap: lineCap,
      lineJoin: lineJoin,
      miterLimit: miterLimit,
      dashPattern: dashPattern
    )
  }

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: NECodingKeys.self)
    try container.encode(opacity, forKey: .opacity)
    try container.encode(color, forKey: .color)
    try container.encode(width, forKey: .width)
    try container.encode(lineCap, forKey: .lineCap)
    try container.encode(lineJoin, forKey: .lineJoin)
    try container.encode(miterLimit, forKey: .miterLimit)
    try container.encodeIfPresent(dashPattern, forKey: .dashPattern)
  }

  // MARK: Private

  private enum NECodingKeys: String, CodingKey {
    case opacity = "o"
    case color = "c"
    case width = "w"
    case lineCap = "lc"
    case lineJoin = "lj"
    case miterLimit = "ml"
    case dashPattern = "d"
  }
}
