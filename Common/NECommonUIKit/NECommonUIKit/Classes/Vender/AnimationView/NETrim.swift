// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NETrimType

enum NETrimType: Int, Codable {
  case simultaneously = 1
  case individually = 2
}

// MARK: - NETrim

final class NETrim: NEShapeItem {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NETrim.NECodingKeys.self)
    start = try container.decode(NEKeyframeGroup<NELottieVector1D>.self, forKey: .start)
    end = try container.decode(NEKeyframeGroup<NELottieVector1D>.self, forKey: .end)
    offset = try container.decode(NEKeyframeGroup<NELottieVector1D>.self, forKey: .offset)
    trimType = try container.decode(NETrimType.self, forKey: .trimType)
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    let startDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.start)
    start = try NEKeyframeGroup<NELottieVector1D>(dictionary: startDictionary)
    let endDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.end)
    end = try NEKeyframeGroup<NELottieVector1D>(dictionary: endDictionary)
    let offsetDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.offset)
    offset = try NEKeyframeGroup<NELottieVector1D>(dictionary: offsetDictionary)
    let trimTypeRawValue: Int = try dictionary.value(for: NECodingKeys.trimType)
    guard let trimType = NETrimType(rawValue: trimTypeRawValue) else {
      throw NEInitializableError.invalidInput()
    }
    self.trimType = trimType
    try super.init(dictionary: dictionary)
  }

  // MARK: Internal

  /// The start of the trim
  let start: NEKeyframeGroup<NELottieVector1D>

  /// The end of the trim
  let end: NEKeyframeGroup<NELottieVector1D>

  /// The offset of the trim
  let offset: NEKeyframeGroup<NELottieVector1D>

  let trimType: NETrimType

  /// If this trim doesn't affect the path at all then we can consider it empty
  var isEmpty: Bool {
    start.keyframes.count == 1
      && start.keyframes[0].value.value == 0
      && end.keyframes.count == 1
      && end.keyframes[0].value.value == 100
  }

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: NECodingKeys.self)
    try container.encode(start, forKey: .start)
    try container.encode(end, forKey: .end)
    try container.encode(offset, forKey: .offset)
    try container.encode(trimType, forKey: .trimType)
  }

  // MARK: Private

  private enum NECodingKeys: String, CodingKey {
    case start = "s"
    case end = "e"
    case offset = "o"
    case trimType = "m"
  }
}
