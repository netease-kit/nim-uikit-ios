// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NELayerEffectType

/// https://lottiefiles.github.io/lottie-docs/schema/#/$defs/effects
enum NELayerEffectType: Int, Codable, Sendable {
  case dropShadow = 25
  case unknown = 9999

  init(from decoder: Decoder) throws {
    self = try NELayerEffectType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
  }
}

// MARK: NEClassFamily

extension NELayerEffectType: NEClassFamily {
  static var discriminator: NEDiscriminator = .type

  func getType() -> AnyObject.Type {
    switch self {
    case .dropShadow:
      return NEDropShadowEffect.self
    case .unknown:
      // Unsupported
      return NELayerEffect.self
    }
  }
}

// MARK: - NELayerEffect

class NELayerEffect: Codable, NEDictionaryInitializable {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NELayerEffect.NECodingKeys.self)
    name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Effect"
    type = try container.decode(NELayerEffectType.self, forKey: .type)
    effects = try container.decodeIfPresent([NEEffectValue].self, ofFamily: NEEffectValueType.self, forKey: .effects) ?? []
  }

  required init(dictionary: [String: Any]) throws {
    name = (try? dictionary.value(for: NECodingKeys.name)) ?? "Layer"
    type = try NELayerEffectType(rawValue: dictionary.value(for: NECodingKeys.type)) ?? .unknown
    if let valueDictionaries = dictionary[NECodingKeys.effects.rawValue] as? [[String: Any]] {
      effects = try [NEEffectValue].fromDictionaries(valueDictionaries)
    } else {
      effects = []
    }
  }

  // MARK: Internal

  /// The name of the effect
  let name: String

  /// The type of effect
  let type: NELayerEffectType

  /// Values that configure the behavior of the effect
  let effects: [NEEffectValue]

  /// Retrieves the `NEEffectValue` for the given name
  func value<ValueType: NEEffectValue>(named name: String) -> ValueType? {
    effects.first(where: {
      $0.name == name && $0 is ValueType
    }) as? ValueType
  }

  // MARK: Fileprivate

  fileprivate enum NECodingKeys: String, CodingKey {
    case name = "nm"
    case type = "ty"
    case effects = "ef"
  }
}

extension [NELayerEffect] {
  static func fromDictionaries(_ dictionaries: [[String: Any]]) throws -> [NELayerEffect] {
    try dictionaries.compactMap { dictionary in
      let shapeType = dictionary[NELayerEffect.NECodingKeys.type.rawValue] as? Int
      switch NELayerEffectType(rawValue: shapeType ?? NELayerEffectType.unknown.rawValue) {
      case .dropShadow:
        return try NEDropShadowEffect(dictionary: dictionary)
      case .unknown, nil:
        // Unsupported
        return try NELayerEffect(dictionary: dictionary)
      }
    }
  }
}

// MARK: - NELayerEffect + Sendable

/// Since `NELayerEffect` isn't `final`, we have to use `@unchecked Sendable` instead of `Sendable.`
/// All `NELayerEffect` subclasses are immutable `Sendable` values.
// swiftlint:disable:next no_unchecked_sendable
extension NELayerEffect: @unchecked Sendable {}
