// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// A layer that holds a solid color.
final class NESolidLayerModel: NELayerModel {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NESolidLayerModel.NECodingKeys.self)
    colorHex = try container.decode(String.self, forKey: .colorHex)
    width = try container.decode(Double.self, forKey: .width)
    height = try container.decode(Double.self, forKey: .height)
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    colorHex = try dictionary.value(for: NECodingKeys.colorHex)
    width = try dictionary.value(for: NECodingKeys.width)
    height = try dictionary.value(for: NECodingKeys.height)
    try super.init(dictionary: dictionary)
  }

  // MARK: Internal

  /// The color of the solid in Hex // Change to value provider.
  let colorHex: String

  /// The Width of the color layer
  let width: Double

  /// The height of the color layer
  let height: Double

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: NECodingKeys.self)
    try container.encode(colorHex, forKey: .colorHex)
    try container.encode(width, forKey: .width)
    try container.encode(height, forKey: .height)
  }

  // MARK: Private

  private enum NECodingKeys: String, CodingKey {
    case colorHex = "sc"
    case width = "sw"
    case height = "sh"
  }
}
