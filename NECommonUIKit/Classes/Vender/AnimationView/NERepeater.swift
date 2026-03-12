// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

final class NERepeater: NEShapeItem {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NERepeater.NECodingKeys.self)
    copies = try container
      .decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .copies) ?? NEKeyframeGroup(NELottieVector1D(0))
    offset = try container
      .decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .offset) ?? NEKeyframeGroup(NELottieVector1D(0))
    let transformContainer = try container.nestedContainer(keyedBy: TransformKeys.self, forKey: .transform)
    startOpacity = try transformContainer
      .decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .startOpacity) ?? NEKeyframeGroup(NELottieVector1D(100))
    endOpacity = try transformContainer
      .decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .endOpacity) ?? NEKeyframeGroup(NELottieVector1D(100))
    if let rotation = try transformContainer.decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .rotation) {
      rotationZ = rotation
    } else if let rotation = try transformContainer.decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .rotationZ) {
      rotationZ = rotation
    } else {
      rotationZ = NEKeyframeGroup(NELottieVector1D(0))
    }

    rotationX = try transformContainer
      .decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .rotationX) ?? NEKeyframeGroup(NELottieVector1D(0))
    rotationY = try transformContainer
      .decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .rotationY) ?? NEKeyframeGroup(NELottieVector1D(0))

    position = try transformContainer
      .decodeIfPresent(NEKeyframeGroup<NELottieVector3D>.self, forKey: .position) ??
      NEKeyframeGroup(NELottieVector3D(x: Double(0), y: 0, z: 0))
    anchorPoint = try transformContainer
      .decodeIfPresent(NEKeyframeGroup<NELottieVector3D>.self, forKey: .anchorPoint) ??
      NEKeyframeGroup(NELottieVector3D(x: Double(0), y: 0, z: 0))
    scale = try transformContainer
      .decodeIfPresent(NEKeyframeGroup<NELottieVector3D>.self, forKey: .scale) ??
      NEKeyframeGroup(NELottieVector3D(x: Double(100), y: 100, z: 100))
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    if let copiesDictionary = dictionary[NECodingKeys.copies.rawValue] as? [String: Any] {
      copies = try NEKeyframeGroup<NELottieVector1D>(dictionary: copiesDictionary)
    } else {
      copies = NEKeyframeGroup(NELottieVector1D(0))
    }
    if let offsetDictionary = dictionary[NECodingKeys.offset.rawValue] as? [String: Any] {
      offset = try NEKeyframeGroup<NELottieVector1D>(dictionary: offsetDictionary)
    } else {
      offset = NEKeyframeGroup(NELottieVector1D(0))
    }
    let transformDictionary: [String: Any] = try dictionary.value(for: NECodingKeys.transform)
    if let startOpacityDictionary = transformDictionary[TransformKeys.startOpacity.rawValue] as? [String: Any] {
      startOpacity = try NEKeyframeGroup<NELottieVector1D>(dictionary: startOpacityDictionary)
    } else {
      startOpacity = NEKeyframeGroup(NELottieVector1D(100))
    }
    if let endOpacityDictionary = transformDictionary[TransformKeys.endOpacity.rawValue] as? [String: Any] {
      endOpacity = try NEKeyframeGroup<NELottieVector1D>(dictionary: endOpacityDictionary)
    } else {
      endOpacity = NEKeyframeGroup(NELottieVector1D(100))
    }
    if let rotationDictionary = transformDictionary[TransformKeys.rotationX.rawValue] as? [String: Any] {
      rotationX = try NEKeyframeGroup<NELottieVector1D>(dictionary: rotationDictionary)
    } else {
      rotationX = NEKeyframeGroup(NELottieVector1D(0))
    }
    if let rotationDictionary = transformDictionary[TransformKeys.rotationY.rawValue] as? [String: Any] {
      rotationY = try NEKeyframeGroup<NELottieVector1D>(dictionary: rotationDictionary)
    } else {
      rotationY = NEKeyframeGroup(NELottieVector1D(0))
    }
    if let rotationDictionary = transformDictionary[TransformKeys.rotation.rawValue] as? [String: Any] {
      rotationZ = try NEKeyframeGroup<NELottieVector1D>(dictionary: rotationDictionary)
    } else if let rotationDictionary = transformDictionary[TransformKeys.rotationZ.rawValue] as? [String: Any] {
      rotationZ = try NEKeyframeGroup<NELottieVector1D>(dictionary: rotationDictionary)
    } else {
      rotationZ = NEKeyframeGroup(NELottieVector1D(0))
    }
    if let positionDictionary = transformDictionary[TransformKeys.position.rawValue] as? [String: Any] {
      position = try NEKeyframeGroup<NELottieVector3D>(dictionary: positionDictionary)
    } else {
      position = NEKeyframeGroup(NELottieVector3D(x: Double(0), y: 0, z: 0))
    }
    if let anchorPointDictionary = transformDictionary[TransformKeys.anchorPoint.rawValue] as? [String: Any] {
      anchorPoint = try NEKeyframeGroup<NELottieVector3D>(dictionary: anchorPointDictionary)
    } else {
      anchorPoint = NEKeyframeGroup(NELottieVector3D(x: Double(0), y: 0, z: 0))
    }
    if let scaleDictionary = transformDictionary[TransformKeys.scale.rawValue] as? [String: Any] {
      scale = try NEKeyframeGroup<NELottieVector3D>(dictionary: scaleDictionary)
    } else {
      scale = NEKeyframeGroup(NELottieVector3D(x: Double(100), y: 100, z: 100))
    }
    try super.init(dictionary: dictionary)
  }

  // MARK: Internal

  /// The number of copies to repeat
  let copies: NEKeyframeGroup<NELottieVector1D>

  /// The offset of each copy
  let offset: NEKeyframeGroup<NELottieVector1D>

  /// Start Opacity
  let startOpacity: NEKeyframeGroup<NELottieVector1D>

  /// End opacity
  let endOpacity: NEKeyframeGroup<NELottieVector1D>

  /// The rotation on X axis
  let rotationX: NEKeyframeGroup<NELottieVector1D>

  /// The rotation on Y axis
  let rotationY: NEKeyframeGroup<NELottieVector1D>

  /// The rotation on Z axis
  let rotationZ: NEKeyframeGroup<NELottieVector1D>

  /// Anchor Point
  let anchorPoint: NEKeyframeGroup<NELottieVector3D>

  /// Position
  let position: NEKeyframeGroup<NELottieVector3D>

  /// Scale
  let scale: NEKeyframeGroup<NELottieVector3D>

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: NECodingKeys.self)
    try container.encode(copies, forKey: .copies)
    try container.encode(offset, forKey: .offset)
    var transformContainer = container.nestedContainer(keyedBy: TransformKeys.self, forKey: .transform)
    try transformContainer.encode(startOpacity, forKey: .startOpacity)
    try transformContainer.encode(endOpacity, forKey: .endOpacity)
    try transformContainer.encode(rotationX, forKey: .rotationX)
    try transformContainer.encode(rotationY, forKey: .rotationY)
    try transformContainer.encode(rotationZ, forKey: .rotationZ)
    try transformContainer.encode(position, forKey: .position)
    try transformContainer.encode(anchorPoint, forKey: .anchorPoint)
    try transformContainer.encode(scale, forKey: .scale)
  }

  // MARK: Private

  private enum NECodingKeys: String, CodingKey {
    case copies = "c"
    case offset = "o"
    case transform = "tr"
  }

  private enum TransformKeys: String, CodingKey {
    case rotation = "r"
    case rotationX = "rx"
    case rotationY = "ry"
    case rotationZ = "rz"
    case startOpacity = "so"
    case endOpacity = "eo"
    case anchorPoint = "a"
    case position = "p"
    case scale = "s"
  }
}
