// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEMaskMode

enum NEMaskMode: String, Codable {
  case add = "a"
  case subtract = "s"
  case intersect = "i"
  case lighten = "l"
  case darken = "d"
  case difference = "f"
  case none = "n"
}

// MARK: - NEMask

final class NEMask: Codable, NEDictionaryInitializable {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NEMask.CodingKeys.self)
    mode = try container.decodeIfPresent(NEMaskMode.self, forKey: .mode) ?? .add
    opacity = try container
      .decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .opacity) ?? NEKeyframeGroup(NELottieVector1D(100))
    shape = try container.decode(NEKeyframeGroup<NEBezierPath>.self, forKey: .shape)
    inverted = try container.decodeIfPresent(Bool.self, forKey: .inverted) ?? false
    expansion = try container
      .decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .expansion) ?? NEKeyframeGroup(NELottieVector1D(0))
  }

  init(dictionary: [String: Any]) throws {
    if
      let modeRawType = dictionary[NECodingKeys.mode.rawValue] as? String,
      let mode = NEMaskMode(rawValue: modeRawType) {
      self.mode = mode
    } else {
      mode = .add
    }
    if let opacityDictionary = dictionary[NECodingKeys.opacity.rawValue] as? [String: Any] {
      opacity = try NEKeyframeGroup<NELottieVector1D>(dictionary: opacityDictionary)
    } else {
      opacity = NEKeyframeGroup(NELottieVector1D(100))
    }
    let shapeDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.shape)
    shape = try NEKeyframeGroup<NEBezierPath>(dictionary: shapeDictionary)
    inverted = (try? dictionary.value(for: NECodingKeys.inverted)) ?? false
    if let expansionDictionary = dictionary[NECodingKeys.expansion.rawValue] as? [String: Any] {
      expansion = try NEKeyframeGroup<NELottieVector1D>(dictionary: expansionDictionary)
    } else {
      expansion = NEKeyframeGroup(NELottieVector1D(0))
    }
  }

  // MARK: Internal

  enum NECodingKeys: String, CodingKey {
    case mode
    case opacity = "o"
    case inverted = "inv"
    case shape = "pt"
    case expansion = "x"
  }

  let mode: NEMaskMode

  let opacity: NEKeyframeGroup<NELottieVector1D>

  let shape: NEKeyframeGroup<NEBezierPath>

  let inverted: Bool

  let expansion: NEKeyframeGroup<NELottieVector1D>
}
