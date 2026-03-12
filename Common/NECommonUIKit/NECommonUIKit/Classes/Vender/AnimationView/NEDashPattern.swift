
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEDashElementType

enum NEDashElementType: String, Codable {
  case offset = "o"
  case dash = "d"
  case gap = "g"
}

// MARK: - NEDashElement

final class NEDashElement: Codable, NEDictionaryInitializable {
  // MARK: Lifecycle

  init(dictionary: [String: Any]) throws {
    let typeRawValue: String = try dictionary.value(for: NECodingKeys.type)
    guard let type = NEDashElementType(rawValue: typeRawValue) else {
      throw NEInitializableError.invalidInput()
    }
    self.type = type
    let valueDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.value)
    value = try NEKeyframeGroup<NELottieVector1D>(dictionary: valueDictionary)
  }

  // MARK: Internal

  enum NECodingKeys: String, CodingKey {
    case type = "n"
    case value = "v"
  }

  let type: NEDashElementType
  let value: NEKeyframeGroup<NELottieVector1D>
}
