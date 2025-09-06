// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NELayerType + NEClassFamily

/// Used for mapping a heterogeneous list to classes for parsing.
extension NELayerType: NEClassFamily {
  static var discriminator: NEDiscriminator = .type

  func getType() -> AnyObject.Type {
    switch self {
    case .precomp:
      return NEPreCompLayerModel.self
    case .solid:
      return NESolidLayerModel.self
    case .image:
      return NEImageLayerModel.self
    case .null:
      return NELayerModel.self
    case .shape:
      return NEShapeLayerModel.self
    case .text:
      return NETextLayerModel.self
    case .unknown:
      return NELayerModel.self
    }
  }
}

// MARK: - NELayerType

public enum NELayerType: Int, Codable {
  case precomp
  case solid
  case image
  case null
  case shape
  case text
  case unknown

  public init(from decoder: Decoder) throws {
    self = try NELayerType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .null
  }
}

// MARK: - NEMatteType

public enum NEMatteType: Int, Codable {
  case none
  case add
  case invert
  case unknown
}

// MARK: - BlendMode

public enum NEBlendMode: Int, Codable {
  case normal
  case multiply
  case screen
  case overlay
  case darken
  case lighten
  case colorDodge
  case colorBurn
  case hardLight
  case softLight
  case difference
  case exclusion
  case hue
  case saturation
  case color
  case luminosity
}

// MARK: - NELayerModel

/// A base top container for shapes, images, and other view objects.
class NELayerModel: Codable, NEDictionaryInitializable {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NELayerModel.NECodingKeys.self)
    name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Layer"
    index = try container.decodeIfPresent(Int.self, forKey: .index) ?? .random(in: Int.min ... Int.max)
    type = try container.decode(NELayerType.self, forKey: .type)
    coordinateSpace = try container.decodeIfPresent(NECoordinateSpace.self, forKey: .coordinateSpace) ?? .type2d
    inFrame = try container.decode(Double.self, forKey: .inFrame)
    outFrame = try container.decode(Double.self, forKey: .outFrame)
    startTime = try container.decode(Double.self, forKey: .startTime)
    transform = try container.decodeIfPresent(NETransform.self, forKey: .transform) ?? .default
    parent = try container.decodeIfPresent(Int.self, forKey: .parent)
    blendMode = try container.decodeIfPresent(NEBlendMode.self, forKey: .blendMode) ?? .normal
    masks = try container.decodeIfPresent([NEMask].self, forKey: .masks)
    timeStretch = try container.decodeIfPresent(Double.self, forKey: .timeStretch) ?? 1
    matte = try container.decodeIfPresent(NEMatteType.self, forKey: .matte)
    hidden = try container.decodeIfPresent(Bool.self, forKey: .hidden) ?? false
    styles = try container.decodeIfPresent([NELayerStyle].self, ofFamily: NELayerStyleType.self, forKey: .styles) ?? []
    effects = try container.decodeIfPresent([NELayerEffect].self, ofFamily: NELayerEffectType.self, forKey: .effects) ?? []
  }

  required init(dictionary: [String: Any]) throws {
    name = (try? dictionary.value(for: NECodingKeys.name)) ?? "Layer"
    index = try dictionary.value(for: NECodingKeys.index) ?? .random(in: Int.min ... Int.max)
    type = try NELayerType(rawValue: dictionary.value(for: NECodingKeys.type)) ?? .null
    if
      let coordinateSpaceRawValue = dictionary[NECodingKeys.coordinateSpace.rawValue] as? Int,
      let coordinateSpace = NECoordinateSpace(rawValue: coordinateSpaceRawValue) {
      self.coordinateSpace = coordinateSpace
    } else {
      coordinateSpace = .type2d
    }
    inFrame = try dictionary.value(for: NECodingKeys.inFrame)
    outFrame = try dictionary.value(for: NECodingKeys.outFrame)
    startTime = try dictionary.value(for: NECodingKeys.startTime)
    parent = try? dictionary.value(for: NECodingKeys.parent)
    if
      let transformDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.transform),
      let transform = try? NETransform(dictionary: transformDictionary) {
      self.transform = transform
    } else {
      transform = .default
    }
    if
      let blendModeRawValue = dictionary[NECodingKeys.blendMode.rawValue] as? Int,
      let blendMode = NEBlendMode(rawValue: blendModeRawValue) {
      self.blendMode = blendMode
    } else {
      blendMode = .normal
    }
    if let maskDictionaries = dictionary[NECodingKeys.masks.rawValue] as? [[String: Any]] {
      masks = try maskDictionaries.map { try NEMask(dictionary: $0) }
    } else {
      masks = nil
    }
    timeStretch = (try? dictionary.value(for: NECodingKeys.timeStretch)) ?? 1
    if let matteRawValue = dictionary[NECodingKeys.matte.rawValue] as? Int {
      matte = NEMatteType(rawValue: matteRawValue)
    } else {
      matte = nil
    }
    hidden = (try? dictionary.value(for: NECodingKeys.hidden)) ?? false
    if let styleDictionaries = dictionary[NECodingKeys.styles.rawValue] as? [[String: Any]] {
      styles = try [NELayerStyle].fromDictionaries(styleDictionaries)
    } else {
      styles = []
    }
    if let effectDictionaries = dictionary[NECodingKeys.effects.rawValue] as? [[String: Any]] {
      effects = try [NELayerEffect].fromDictionaries(effectDictionaries)
    } else {
      effects = []
    }
  }

  // MARK: Internal

  /// The readable name of the layer
  let name: String

  /// The index of the layer
  let index: Int

  /// The type of the layer.
  let type: NELayerType

  /// The coordinate space
  let coordinateSpace: NECoordinateSpace

  /// The in time of the layer in frames.
  let inFrame: Double
  /// The out time of the layer in frames.
  let outFrame: Double

  /// The start time of the layer in frames.
  let startTime: Double

  /// The transform of the layer
  let transform: NETransform

  /// The index of the parent layer, if applicable.
  let parent: Int?

  /// The blending mode for the layer
  let blendMode: NEBlendMode

  /// An array of masks for the layer.
  let masks: [NEMask]?

  /// A number that stretches time by a multiplier
  let timeStretch: Double

  /// The type of matte if any.
  let matte: NEMatteType?

  /// Whether or not this layer is hidden, in which case it will not be rendered.
  let hidden: Bool

  /// A list of styles to apply to this layer
  let styles: [NELayerStyle]

  /// A list of effects to apply to this layer
  let effects: [NELayerEffect]

  // MARK: Fileprivate

  fileprivate enum NECodingKeys: String, CodingKey {
    case name = "nm"
    case index = "ind"
    case type = "ty"
    case coordinateSpace = "ddd"
    case inFrame = "ip"
    case outFrame = "op"
    case startTime = "st"
    case transform = "ks"
    case parent
    case blendMode = "bm"
    case masks = "masksProperties"
    case timeStretch = "sr"
    case matte = "tt"
    case hidden = "hd"
    case styles = "sy"
    case effects = "ef"
  }
}

extension [NELayerModel] {
  static func fromDictionaries(_ dictionaries: [[String: Any]]) throws -> [NELayerModel] {
    try dictionaries.compactMap { dictionary in
      let layerType = dictionary[NELayerModel.NECodingKeys.type.rawValue] as? Int
      switch NELayerType(rawValue: layerType ?? NELayerType.null.rawValue) {
      case .precomp:
        return try NEPreCompLayerModel(dictionary: dictionary)
      case .solid:
        return try NESolidLayerModel(dictionary: dictionary)
      case .image:
        return try NEImageLayerModel(dictionary: dictionary)
      case .null:
        return try NELayerModel(dictionary: dictionary)
      case .shape:
        return try NEShapeLayerModel(dictionary: dictionary)
      case .text:
        return try NETextLayerModel(dictionary: dictionary)
      case .unknown:
        return try NELayerModel(dictionary: dictionary)
      case .none:
        return nil
      }
    }
  }
}

// MARK: - NELayerModel + Sendable

/// Since `NELayerModel` isn't `final`, we have to use `@unchecked Sendable` instead of `Sendable.`
/// All `NELayerModel` subclasses are immutable `Sendable` values.
// swiftlint:disable:next no_unchecked_sendable
extension NELayerModel: @unchecked Sendable {}
