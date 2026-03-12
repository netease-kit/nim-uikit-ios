// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

final class NEVector1DEffectValue: NEEffectValue {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NECodingKeys.self)
    value = try? container.decode(NEKeyframeGroup<NELottieVector1D>.self, forKey: .value)
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    let valueDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.value)
    value = try NEKeyframeGroup<NELottieVector1D>(dictionary: valueDictionary)
    try super.init(dictionary: dictionary)
  }

  // MARK: Internal

  /// The value of the slider
  let value: NEKeyframeGroup<NELottieVector1D>?

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: NECodingKeys.self)
    try container.encode(value, forKey: .value)
  }

  // MARK: Private

  private enum NECodingKeys: String, CodingKey {
    case value = "v"
  }
}
