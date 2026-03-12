// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEEffectValueType

/// https://lottiefiles.github.io/lottie-docs/schema/#/$defs/effect-values
enum NEEffectValueType: Int, Codable, Sendable {
  case slider = 0
  case angle = 1
  case color = 2
  case unknown = 9999

  init(from decoder: Decoder) throws {
    self = try NEEffectValueType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
  }
}

// MARK: NEClassFamily

extension NEEffectValueType: NEClassFamily {
  static var discriminator: NEDiscriminator = .type

  func getType() -> AnyObject.Type {
    switch self {
    case .slider:
      return NEVector1DEffectValue.self
    case .angle:
      return NEVector1DEffectValue.self
    case .color:
      return NEColorEffectValue.self
    case .unknown:
      // Unsupported
      return NELayerEffect.self
    }
  }
}

// MARK: - NEEffectValue

class NEEffectValue: Codable, NEDictionaryInitializable {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NEEffectValue.NECodingKeys.self)
    type = try container.decode(NEEffectValueType.self, forKey: .type)
    name = try container.decode(String.self, forKey: .name)
  }

  required init(dictionary: [String: Any]) throws {
    type = (try? dictionary.value(for: NECodingKeys.type)).flatMap(NEEffectValueType.init(rawValue:)) ?? .unknown
    name = (try? dictionary.value(for: NECodingKeys.name)) ?? "Effect"
  }

  // MARK: Internal

  /// The type of effect value
  let type: NEEffectValueType

  /// The name of the effect value
  let name: String

  // MARK: Fileprivate

  fileprivate enum NECodingKeys: String, CodingKey {
    case type = "ty"
    case name = "nm"
  }
}

extension [NEEffectValue] {
  static func fromDictionaries(_ dictionaries: [[String: Any]]) throws -> [NEEffectValue] {
    try dictionaries.compactMap { dictionary in
      let shapeType = dictionary[NEEffectValue.NECodingKeys.type.rawValue] as? Int
      switch NEEffectValueType(rawValue: shapeType ?? NEEffectValueType.unknown.rawValue) {
      case .slider:
        return try NEVector1DEffectValue(dictionary: dictionary)
      case .angle:
        return try NEVector1DEffectValue(dictionary: dictionary)
      case .color:
        return try NEColorEffectValue(dictionary: dictionary)
      case .unknown:
        // Unsupported
        return try NEEffectValue(dictionary: dictionary)
      case nil:
        return nil
      }
    }
  }
}

// MARK: - NEEffectValue + Sendable

/// Since `NEEffectValue` isn't `final`, we have to use `@unchecked Sendable` instead of `Sendable.`
/// All `NEEffectValue` subclasses are immutable `Sendable` values.
// swiftlint:disable:next no_unchecked_sendable
extension NEEffectValue: @unchecked Sendable {}
