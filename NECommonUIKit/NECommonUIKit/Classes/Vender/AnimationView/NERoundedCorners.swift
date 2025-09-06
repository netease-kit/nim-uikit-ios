// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NERoundedCorners

final class NERoundedCorners: NEShapeItem {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NERoundedCorners.NECodingKeys.self)
    radius = try
      container.decode(
        NEKeyframeGroup<NELottieVector1D>.self,
        forKey: .radius
      )
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    let radiusDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.radius)
    radius = try NEKeyframeGroup<NELottieVector1D>(dictionary: radiusDictionary)
    try super.init(dictionary: dictionary)
  }

  // MARK: Internal

  /// The radius of rounded corners
  let radius: NEKeyframeGroup<NELottieVector1D>

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: NECodingKeys.self)
    try container.encode(radius, forKey: .radius)
  }

  // MARK: Private

  private enum NECodingKeys: String, CodingKey {
    case radius = "r"
  }
}
