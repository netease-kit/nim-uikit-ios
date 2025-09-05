// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// A model that holds a vector character
final class NEGlyph: Codable, Sendable, NEDictionaryInitializable {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NEGlyph.NECodingKeys.self)
    character = try container.decode(String.self, forKey: .character)
    fontSize = try container.decode(Double.self, forKey: .fontSize)
    fontFamily = try container.decode(String.self, forKey: .fontFamily)
    fontStyle = try container.decode(String.self, forKey: .fontStyle)
    width = try container.decode(Double.self, forKey: .width)
    if
      container.contains(.shapeWrapper),
      let shapeContainer = try? container.nestedContainer(keyedBy: NEShapeKey.self, forKey: .shapeWrapper),
      shapeContainer.contains(.shapes) {
      shapes = try shapeContainer.decode([NEShapeItem].self, ofFamily: NEShapeType.self, forKey: .shapes)
    } else {
      shapes = []
    }
  }

  init(dictionary: [String: Any]) throws {
    character = try dictionary.value(for: NECodingKeys.character)
    fontSize = try dictionary.value(for: NECodingKeys.fontSize)
    fontFamily = try dictionary.value(for: NECodingKeys.fontFamily)
    fontStyle = try dictionary.value(for: NECodingKeys.fontStyle)
    width = try dictionary.value(for: NECodingKeys.width)
    if
      let shapes = dictionary[NECodingKeys.shapeWrapper.rawValue] as? [String: Any],
      let shapeDictionaries = shapes[NEShapeKey.shapes.rawValue] as? [[String: Any]] {
      self.shapes = try [NEShapeItem].fromDictionaries(shapeDictionaries)
    } else {
      shapes = [NEShapeItem]()
    }
  }

  // MARK: Internal

  /// The character
  let character: String

  /// The font size of the character
  let fontSize: Double

  /// The font family of the character
  let fontFamily: String

  /// The Style of the character
  let fontStyle: String

  /// The Width of the character
  let width: Double

  /// The NEShape Data of the Character
  let shapes: [NEShapeItem]

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: NECodingKeys.self)

    try container.encode(character, forKey: .character)
    try container.encode(fontSize, forKey: .fontSize)
    try container.encode(fontFamily, forKey: .fontFamily)
    try container.encode(fontStyle, forKey: .fontStyle)
    try container.encode(width, forKey: .width)

    var shapeContainer = container.nestedContainer(keyedBy: NEShapeKey.self, forKey: .shapeWrapper)
    try shapeContainer.encode(shapes, forKey: .shapes)
  }

  // MARK: Private

  private enum NECodingKeys: String, CodingKey {
    case character = "ch"
    case fontSize = "size"
    case fontFamily = "fFamily"
    case fontStyle = "style"
    case width = "w"
    case shapeWrapper = "data"
  }

  private enum NEShapeKey: String, CodingKey {
    case shapes
  }
}
