// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// A layer that holds another animation composition.
final class NEPreCompLayerModel: NELayerModel {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NEPreCompLayerModel.NECodingKeys.self)
    referenceID = try container.decode(String.self, forKey: .referenceID)
    timeRemapping = try container.decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .timeRemapping)
    width = try container.decode(Double.self, forKey: .width)
    height = try container.decode(Double.self, forKey: .height)
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    referenceID = try dictionary.value(for: NECodingKeys.referenceID)
    if let timeRemappingDictionary = dictionary[NECodingKeys.timeRemapping.rawValue] as? [String: Any] {
      timeRemapping = try NEKeyframeGroup<NELottieVector1D>(dictionary: timeRemappingDictionary)
    } else {
      timeRemapping = nil
    }
    width = try dictionary.value(for: NECodingKeys.width)
    height = try dictionary.value(for: NECodingKeys.height)
    try super.init(dictionary: dictionary)
  }

  // MARK: Internal

  /// The reference ID of the precomp.
  let referenceID: String

  /// A value that remaps time over time.
  let timeRemapping: NEKeyframeGroup<NELottieVector1D>?

  /// Precomp Width
  let width: Double

  /// Precomp Height
  let height: Double

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: NECodingKeys.self)
    try container.encode(referenceID, forKey: .referenceID)
    try container.encode(timeRemapping, forKey: .timeRemapping)
    try container.encode(width, forKey: .width)
    try container.encode(height, forKey: .height)
  }

  // MARK: Private

  private enum NECodingKeys: String, CodingKey {
    case referenceID = "refId"
    case timeRemapping = "tm"
    case width = "w"
    case height = "h"
  }
}
