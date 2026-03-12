
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEAsset

public class NEAsset: Codable, NEDictionaryInitializable {
  // MARK: Lifecycle

  public required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NEAsset.NECodingKeys.self)
    if let id = try? container.decode(String.self, forKey: .id) {
      self.id = id
    } else {
      id = try String(container.decode(Int.self, forKey: .id))
    }
  }

  required init(dictionary: [String: Any]) throws {
    if let id = dictionary[NECodingKeys.id.rawValue] as? String {
      self.id = id
    } else if let id = dictionary[NECodingKeys.id.rawValue] as? Int {
      self.id = String(id)
    } else {
      throw NEInitializableError.invalidInput()
    }
  }

  // MARK: Public

  /// The ID of the asset
  public let id: String

  // MARK: Private

  private enum NECodingKeys: String, CodingKey {
    case id
  }
}

// MARK: Sendable

/// Since `NEAsset` isn't `final`, we have to use `@unchecked Sendable` instead of `Sendable.`
/// All `NEAsset` subclasses are immutable `Sendable` values.
// swiftlint:disable:next no_unchecked_sendable
extension NEAsset: @unchecked Sendable {}
