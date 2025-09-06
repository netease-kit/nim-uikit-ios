// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

final class NEPrecompAsset: NEAsset {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NEPrecompAsset.NECodingKeys.self)
    layers = try container.decode([NELayerModel].self, ofFamily: NELayerType.self, forKey: .layers)
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    let layerDictionaries: [[String: Any]] = try dictionary.value(for: NECodingKeys.layers)
    layers = try [NELayerModel].fromDictionaries(layerDictionaries)
    try super.init(dictionary: dictionary)
  }

  // MARK: Internal

  enum NECodingKeys: String, CodingKey {
    case layers
  }

  /// Layers of the precomp
  let layers: [NELayerModel]

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: NECodingKeys.self)
    try container.encode(layers, forKey: .layers)
  }
}
