// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// A layer that holds an image.
final class NEImageLayerModel: NELayerModel {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NEImageLayerModel.NECodingKeys.self)
    referenceID = try container.decode(String.self, forKey: .referenceID)
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    referenceID = try dictionary.value(for: NECodingKeys.referenceID)
    try super.init(dictionary: dictionary)
  }

  // MARK: Internal

  /// The reference ID of the image.
  let referenceID: String

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: NECodingKeys.self)
    try container.encode(referenceID, forKey: .referenceID)
  }

  // MARK: Private

  private enum NECodingKeys: String, CodingKey {
    case referenceID = "refId"
  }
}
