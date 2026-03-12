// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NELineCap

enum NELineCap: Int, Codable, Sendable {
  case none
  case butt
  case round
  case square
}

// MARK: - NELineJoin

enum NELineJoin: Int, Codable, Sendable {
  case none
  case miter
  case round
  case bevel
}

// MARK: - NEGradientStroke

final class NEGradientStroke: NEShapeItem {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NEGradientStroke.NECodingKeys.self)
    opacity = try container.decode(NEKeyframeGroup<NELottieVector1D>.self, forKey: .opacity)
    startPoint = try container.decode(NEKeyframeGroup<NELottieVector3D>.self, forKey: .startPoint)
    endPoint = try container.decode(NEKeyframeGroup<NELottieVector3D>.self, forKey: .endPoint)
    gradientType = try container.decode(NEGradientType.self, forKey: .gradientType)
    highlightLength = try container.decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .highlightLength)
    highlightAngle = try container.decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .highlightAngle)
    width = try container.decode(NEKeyframeGroup<NELottieVector1D>.self, forKey: .width)
    lineCap = try container.decodeIfPresent(NELineCap.self, forKey: .lineCap) ?? .round
    lineJoin = try container.decodeIfPresent(NELineJoin.self, forKey: .lineJoin) ?? .round
    miterLimit = try container.decodeIfPresent(Double.self, forKey: .miterLimit) ?? 4
    // TODO: Decode Color Objects instead of array.
    let colorsContainer = try container.nestedContainer(keyedBy: GradientDataKeys.self, forKey: .colors)
    colors = try colorsContainer.decode(NEKeyframeGroup<[Double]>.self, forKey: .colors)
    numberOfColors = try colorsContainer.decode(Int.self, forKey: .numberOfColors)
    dashPattern = try container.decodeIfPresent([NEDashElement].self, forKey: .dashPattern)
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
    let colorsDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.colors)
    let nestedColorsDictionary: [String: Any] = try colorsDictionary.value(for: GradientDataKeys.colors)
    colors = try NEKeyframeGroup<[Double]>(dictionary: nestedColorsDictionary)
    numberOfColors = try colorsDictionary.value(for: GradientDataKeys.numberOfColors)
    let dashPatternDictionaries = dictionary[NECodingKeys.dashPattern.rawValue] as? [[String: Any]]
    dashPattern = try? dashPatternDictionaries?.map { try NEDashElement(dictionary: $0) }
    try super.init(dictionary: dictionary)
  }

  init(name: String,
       hidden: Bool,
       opacity: NEKeyframeGroup<NELottieVector1D>,
       startPoint: NEKeyframeGroup<NELottieVector3D>,
       endPoint: NEKeyframeGroup<NELottieVector3D>,
       gradientType: NEGradientType,
       highlightLength: NEKeyframeGroup<NELottieVector1D>?,
       highlightAngle: NEKeyframeGroup<NELottieVector1D>?,
       numberOfColors: Int,
       colors: NEKeyframeGroup<[Double]>,
       width: NEKeyframeGroup<NELottieVector1D>,
       lineCap: NELineCap,
       lineJoin: NELineJoin,
       miterLimit: Double,
       dashPattern: [NEDashElement]?) {
    self.opacity = opacity
    self.startPoint = startPoint
    self.endPoint = endPoint
    self.gradientType = gradientType
    self.highlightLength = highlightLength
    self.highlightAngle = highlightAngle
    self.numberOfColors = numberOfColors
    self.colors = colors
    self.width = width
    self.lineCap = lineCap
    self.lineJoin = lineJoin
    self.miterLimit = miterLimit
    self.dashPattern = dashPattern
    super.init(name: name, type: .gradientStroke, hidden: hidden)
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

  /// Creates a copy of this NEGradientStroke with the given updated width keyframes
  func copy(width newWidth: NEKeyframeGroup<NELottieVector1D>) -> NEGradientStroke {
    NEGradientStroke(
      name: name,
      hidden: hidden,
      opacity: opacity,
      startPoint: startPoint,
      endPoint: endPoint,
      gradientType: gradientType,
      highlightLength: highlightLength,
      highlightAngle: highlightAngle,
      numberOfColors: numberOfColors,
      colors: colors,
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
    try container.encode(startPoint, forKey: .startPoint)
    try container.encode(endPoint, forKey: .endPoint)
    try container.encode(gradientType, forKey: .gradientType)
    try container.encodeIfPresent(highlightLength, forKey: .highlightLength)
    try container.encodeIfPresent(highlightAngle, forKey: .highlightAngle)
    try container.encode(width, forKey: .width)
    try container.encode(lineCap, forKey: .lineCap)
    try container.encode(lineJoin, forKey: .lineJoin)
    try container.encode(miterLimit, forKey: .miterLimit)
    var colorsContainer = container.nestedContainer(keyedBy: GradientDataKeys.self, forKey: .colors)
    try colorsContainer.encode(numberOfColors, forKey: .numberOfColors)
    try colorsContainer.encode(colors, forKey: .colors)
    try container.encodeIfPresent(dashPattern, forKey: .dashPattern)
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
    case width = "w"
    case lineCap = "lc"
    case lineJoin = "lj"
    case miterLimit = "ml"
    case dashPattern = "d"
  }

  private enum GradientDataKeys: String, CodingKey {
    case numberOfColors = "p"
    case colors = "k"
  }
}
