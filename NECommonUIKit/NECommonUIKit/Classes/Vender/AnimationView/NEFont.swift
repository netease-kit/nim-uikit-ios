// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEFont

final class NEFont: Codable, Sendable, NEDictionaryInitializable {
  // MARK: Lifecycle

  init(dictionary: [String: Any]) throws {
    name = try dictionary.value(for: NECodingKeys.name)
    familyName = try dictionary.value(for: NECodingKeys.familyName)
    style = try dictionary.value(for: NECodingKeys.style)
    ascent = try dictionary.value(for: NECodingKeys.ascent)
  }

  // MARK: Internal

  let name: String
  let familyName: String
  let style: String
  let ascent: Double

  // MARK: Private

  private enum NECodingKeys: String, CodingKey {
    case name = "fName"
    case familyName = "fFamily"
    case style = "fStyle"
    case ascent
  }
}

// MARK: - NEFontList

/// A list of fonts
final class NEFontList: Codable, Sendable, NEDictionaryInitializable {
  // MARK: Lifecycle

  init(dictionary: [String: Any]) throws {
    let fontDictionaries: [[String: Any]] = try dictionary.value(for: NECodingKeys.fonts)
    fonts = try fontDictionaries.map { try NEFont(dictionary: $0) }
  }

  // MARK: Internal

  enum NECodingKeys: String, CodingKey {
    case fonts = "list"
  }

  let fonts: [NEFont]
}
