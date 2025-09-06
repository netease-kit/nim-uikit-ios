// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// An item that define a a group of shape items
final class NEGroup: NEShapeItem {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NEGroup.NECodingKeys.self)
    items = try container.decode([NEShapeItem].self, ofFamily: NEShapeType.self, forKey: .items)
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    let itemDictionaries: [[String: Any]] = try dictionary.value(for: NECodingKeys.items)
    items = try [NEShapeItem].fromDictionaries(itemDictionaries)
    try super.init(dictionary: dictionary)
  }

  init(items: [NEShapeItem], name: String) {
    self.items = items
    super.init(name: name, type: .group, hidden: false)
  }

  // MARK: Internal

  /// A list of shape items.
  let items: [NEShapeItem]

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: NECodingKeys.self)
    try container.encode(items, forKey: .items)
  }

  // MARK: Private

  private enum NECodingKeys: String, CodingKey {
    case items = "it"
  }
}
