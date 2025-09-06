// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NETextJustification

enum NETextJustification: Int, Codable {
  case left
  case right
  case center
}

// MARK: - NETextDocument

final class NETextDocument: Codable, NEDictionaryInitializable, NEAnyInitializable {
  // MARK: Lifecycle

  init(dictionary: [String: Any]) throws {
    text = try dictionary.value(for: NECodingKeys.text)
    fontSize = try dictionary.value(for: NECodingKeys.fontSize)
    fontFamily = try dictionary.value(for: NECodingKeys.fontFamily)
    let justificationValue: Int = try dictionary.value(for: NECodingKeys.justification)
    guard let justification = NETextJustification(rawValue: justificationValue) else {
      throw NEInitializableError.invalidInput()
    }
    self.justification = justification
    tracking = try dictionary.value(for: NECodingKeys.tracking)
    lineHeight = try dictionary.value(for: NECodingKeys.lineHeight)
    baseline = try dictionary.value(for: NECodingKeys.baseline)
    if let fillColorRawValue = dictionary[NECodingKeys.fillColorData.rawValue] {
      fillColorData = try? NELottieColor(value: fillColorRawValue)
    } else {
      fillColorData = nil
    }
    if let strokeColorRawValue = dictionary[NECodingKeys.strokeColorData.rawValue] {
      strokeColorData = try? NELottieColor(value: strokeColorRawValue)
    } else {
      strokeColorData = nil
    }
    strokeWidth = try? dictionary.value(for: NECodingKeys.strokeWidth)
    strokeOverFill = try? dictionary.value(for: NECodingKeys.strokeOverFill)
    if let textFramePositionRawValue = dictionary[NECodingKeys.textFramePosition.rawValue] {
      textFramePosition = try? NELottieVector3D(value: textFramePositionRawValue)
    } else {
      textFramePosition = nil
    }
    if let textFrameSizeRawValue = dictionary[NECodingKeys.textFrameSize.rawValue] {
      textFrameSize = try? NELottieVector3D(value: textFrameSizeRawValue)
    } else {
      textFrameSize = nil
    }
  }

  convenience init(value: Any) throws {
    guard let dictionary = value as? [String: Any] else {
      throw NEInitializableError.invalidInput()
    }
    try self.init(dictionary: dictionary)
  }

  // MARK: Internal

  /// The Text
  let text: String

  /// The NEFont size
  let fontSize: Double

  /// The NEFont Family
  let fontFamily: String

  /// Justification
  let justification: NETextJustification

  /// Tracking
  let tracking: Int

  /// Line Height
  let lineHeight: Double

  /// Baseline
  let baseline: Double?

  /// NEFill Color data
  let fillColorData: NELottieColor?

  /// Scroke Color data
  let strokeColorData: NELottieColor?

  /// NEStroke Width
  let strokeWidth: Double?

  /// NEStroke Over NEFill
  let strokeOverFill: Bool?

  let textFramePosition: NELottieVector3D?

  let textFrameSize: NELottieVector3D?

  // MARK: Private

  private enum NECodingKeys: String, CodingKey {
    case text = "t"
    case fontSize = "s"
    case fontFamily = "f"
    case justification = "j"
    case tracking = "tr"
    case lineHeight = "lh"
    case baseline = "ls"
    case fillColorData = "fc"
    case strokeColorData = "sc"
    case strokeWidth = "sw"
    case strokeOverFill = "of"
    case textFramePosition = "ps"
    case textFrameSize = "sz"
  }
}
