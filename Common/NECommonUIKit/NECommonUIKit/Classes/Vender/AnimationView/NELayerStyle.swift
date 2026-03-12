// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NELayerStyleType

enum NELayerStyleType: Int, Codable, Sendable {
  case dropShadow = 1
  case unknown = 9999

  init(from decoder: Decoder) throws {
    self = try NELayerStyleType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
  }
}

// MARK: NEClassFamily

extension NELayerStyleType: NEClassFamily {
  static var discriminator: NEDiscriminator = .type

  func getType() -> AnyObject.Type {
    switch self {
    case .dropShadow:
      return NEDropShadowStyle.self
    case .unknown:
      // Unsupported
      return NELayerStyle.self
    }
  }
}

// MARK: - NELayerStyle

class NELayerStyle: Codable, NEDictionaryInitializable {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NELayerStyle.NECodingKeys.self)
    name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Style"
    type = try container.decode(NELayerStyleType.self, forKey: .type)
  }

  required init(dictionary: [String: Any]) throws {
    name = (try? dictionary.value(for: NECodingKeys.name)) ?? "Layer"
    type = try NELayerStyleType(rawValue: dictionary.value(for: NECodingKeys.type)) ?? .unknown
  }

  // MARK: Internal

  /// The name of the style
  let name: String

  /// The type of style
  let type: NELayerStyleType

  // MARK: Fileprivate

  fileprivate enum NECodingKeys: String, CodingKey {
    case name = "nm"
    case type = "ty"
  }
}

extension [NELayerStyle] {
  static func fromDictionaries(_ dictionaries: [[String: Any]]) throws -> [NELayerStyle] {
    try dictionaries.compactMap { dictionary in
      let shapeType = dictionary[NELayerStyle.NECodingKeys.type.rawValue] as? Int
      switch NELayerStyleType(rawValue: shapeType ?? NELayerStyleType.unknown.rawValue) {
      case .dropShadow:
        return try NEDropShadowStyle(dictionary: dictionary)
      case .unknown, nil:
        // Unsupported
        return try NELayerStyle(dictionary: dictionary)
      }
    }
  }
}

// MARK: - NELayerStyle + Sendable

/// Since `NELayerStyle` isn't `final`, we have to use `@unchecked Sendable` instead of `Sendable.`
/// All `NELayerStyle` subclasses are immutable `Sendable` values.
// swiftlint:disable:next no_unchecked_sendable
extension NELayerStyle: @unchecked Sendable {}
