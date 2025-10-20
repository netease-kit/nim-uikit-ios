// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEShapeType

enum NEShapeType: String, Codable, Sendable {
  case ellipse = "el"
  case fill = "fl"
  case gradientFill = "gf"
  case group = "gr"
  case gradientStroke = "gs"
  case merge = "mm"
  case rectangle = "rc"
  case repeater = "rp"
  case round = "rd"
  case shape = "sh"
  case star = "sr"
  case stroke = "st"
  case trim = "tm"
  case transform = "tr"
  case unknown

  init(from decoder: Decoder) throws {
    self = try NEShapeType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
  }
}

// MARK: NEClassFamily

extension NEShapeType: NEClassFamily {
  static var discriminator: NEDiscriminator = .type

  func getType() -> AnyObject.Type {
    switch self {
    case .ellipse:
      return NEEllipse.self
    case .fill:
      return NEFill.self
    case .gradientFill:
      return NEGradientFill.self
    case .group:
      return NEGroup.self
    case .gradientStroke:
      return NEGradientStroke.self
    case .merge:
      return NEMerge.self
    case .rectangle:
      return NERectangle.self
    case .repeater:
      return NERepeater.self
    case .round:
      return NERoundedCorners.self
    case .shape:
      return NEShape.self
    case .star:
      return NEStar.self
    case .stroke:
      return NEStroke.self
    case .trim:
      return NETrim.self
    case .transform:
      return NEShapeTransform.self
    default:
      return NEShapeItem.self
    }
  }
}

// MARK: - NEShapeItem

/// An item belonging to a NEShape Layer
class NEShapeItem: Codable, NEDictionaryInitializable {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NEShapeItem.NECodingKeys.self)
    name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Layer"
    type = try container.decode(NEShapeType.self, forKey: .type)
    hidden = try container.decodeIfPresent(Bool.self, forKey: .hidden) ?? false
  }

  required init(dictionary: [String: Any]) throws {
    name = (try? dictionary.value(for: NECodingKeys.name)) ?? "Layer"
    type = try NEShapeType(rawValue: dictionary.value(for: NECodingKeys.type)) ?? .unknown
    hidden = (try? dictionary.value(for: NECodingKeys.hidden)) ?? false
  }

  init(name: String,
       type: NEShapeType,
       hidden: Bool) {
    self.name = name
    self.type = type
    self.hidden = hidden
  }

  // MARK: Internal

  /// The name of the shape
  let name: String

  /// The type of shape
  let type: NEShapeType

  let hidden: Bool

  // MARK: Fileprivate

  fileprivate enum NECodingKeys: String, CodingKey {
    case name = "nm"
    case type = "ty"
    case hidden = "hd"
  }
}

extension [NEShapeItem] {
  static func fromDictionaries(_ dictionaries: [[String: Any]]) throws -> [NEShapeItem] {
    try dictionaries.compactMap { dictionary in
      let shapeType = dictionary[NEShapeItem.NECodingKeys.type.rawValue] as? String
      switch NEShapeType(rawValue: shapeType ?? NEShapeType.unknown.rawValue) {
      case .ellipse:
        return try NEEllipse(dictionary: dictionary)
      case .fill:
        return try NEFill(dictionary: dictionary)
      case .gradientFill:
        return try NEGradientFill(dictionary: dictionary)
      case .group:
        return try NEGroup(dictionary: dictionary)
      case .gradientStroke:
        return try NEGradientStroke(dictionary: dictionary)
      case .merge:
        return try NEMerge(dictionary: dictionary)
      case .rectangle:
        return try NERectangle(dictionary: dictionary)
      case .repeater:
        return try NERepeater(dictionary: dictionary)
      case .round:
        return try NERoundedCorners(dictionary: dictionary)
      case .shape:
        return try NEShape(dictionary: dictionary)
      case .star:
        return try NEStar(dictionary: dictionary)
      case .stroke:
        return try NEStroke(dictionary: dictionary)
      case .trim:
        return try NETrim(dictionary: dictionary)
      case .transform:
        return try NEShapeTransform(dictionary: dictionary)
      case .none:
        return nil
      default:
        return try NEShapeItem(dictionary: dictionary)
      }
    }
  }
}

// MARK: - NEShapeItem + Sendable

/// Since `NEShapeItem` isn't `final`, we have to use `@unchecked Sendable` instead of `Sendable.`
/// All `NEShapeItem` subclasses are immutable `Sendable` values.
// swiftlint:disable:next no_unchecked_sendable
extension NEShapeItem: @unchecked Sendable {}
