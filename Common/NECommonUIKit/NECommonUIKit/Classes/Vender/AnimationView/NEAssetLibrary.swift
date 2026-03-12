
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

final class NEAssetLibrary: Codable, NEAnyInitializable, Sendable {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    var containerForKeys = container

    var decodedAssets = [String: NEAsset]()

    var imageAssets = [String: NEImageAsset]()
    var precompAssets = [String: NEPrecompAsset]()

    while
      !container.isAtEnd,
      let keyContainer = try? containerForKeys.nestedContainer(keyedBy: NEPrecompAsset.NECodingKeys.self) {
      if
        keyContainer.contains(.layers),
        let precompAsset = try? container.decode(NEPrecompAsset.self) {
        decodedAssets[precompAsset.id] = precompAsset
        precompAssets[precompAsset.id] = precompAsset
      } else if let imageAsset = try? container.decode(NEImageAsset.self) {
        decodedAssets[imageAsset.id] = imageAsset
        imageAssets[imageAsset.id] = imageAsset
      }
    }
    assets = decodedAssets
    self.precompAssets = precompAssets
    self.imageAssets = imageAssets
  }

  init(value: Any) throws {
    guard let dictionaries = value as? [[String: Any]] else {
      throw NEInitializableError.invalidInput()
    }
    var decodedAssets = [String: NEAsset]()
    var imageAssets = [String: NEImageAsset]()
    var precompAssets = [String: NEPrecompAsset]()
    for dictionary in dictionaries {
      if dictionary[NEPrecompAsset.NECodingKeys.layers.rawValue] != nil {
        let asset = try NEPrecompAsset(dictionary: dictionary)
        decodedAssets[asset.id] = asset
        precompAssets[asset.id] = asset
      } else if let asset = try? NEImageAsset(dictionary: dictionary) {
        decodedAssets[asset.id] = asset
        imageAssets[asset.id] = asset
      }
    }
    assets = decodedAssets
    self.precompAssets = precompAssets
    self.imageAssets = imageAssets
  }

  // MARK: Internal

  /// The Assets
  let assets: [String: NEAsset]

  let imageAssets: [String: NEImageAsset]
  let precompAssets: [String: NEPrecompAsset]

  func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(contentsOf: Array(assets.values))
  }
}
