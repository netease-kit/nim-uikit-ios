// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// A layer that holds text.
final class NETextLayerModel: NELayerModel {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NETextLayerModel.NECodingKeys.self)
    let textContainer = try container.nestedContainer(keyedBy: TextCodingKeys.self, forKey: .textGroup)
    text = try textContainer.decode(NEKeyframeGroup<NETextDocument>.self, forKey: .text)
    animators = try textContainer.decode([NETextAnimator].self, forKey: .animators)
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    let containerDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.textGroup)
    let textDictionary: [String: Any] = try containerDictionary.value(for: TextCodingKeys.text)
    text = try NEKeyframeGroup<NETextDocument>(dictionary: textDictionary)
    let animatorDictionaries: [[String: Any]] = try containerDictionary.value(for: TextCodingKeys.animators)
    animators = try animatorDictionaries.map { try NETextAnimator(dictionary: $0) }
    try super.init(dictionary: dictionary)
  }

  // MARK: Internal

  /// The text for the layer
  let text: NEKeyframeGroup<NETextDocument>

  /// Text animators
  let animators: [NETextAnimator]

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: NECodingKeys.self)
    var textContainer = container.nestedContainer(keyedBy: TextCodingKeys.self, forKey: .textGroup)
    try textContainer.encode(text, forKey: .text)
    try textContainer.encode(animators, forKey: .animators)
  }

  // MARK: Private

  private enum NECodingKeys: String, CodingKey {
    case textGroup = "t"
  }

  private enum TextCodingKeys: String, CodingKey {
    case text = "d"
    case animators = "a"
  }
}
