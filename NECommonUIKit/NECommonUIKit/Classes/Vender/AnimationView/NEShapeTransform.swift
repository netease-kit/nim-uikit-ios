// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

final class NEShapeTransform: NEShapeItem {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NEShapeTransform.NECodingKeys.self)
    anchor = try container
      .decodeIfPresent(NEKeyframeGroup<NELottieVector3D>.self, forKey: .anchor) ??
      NEKeyframeGroup(NELottieVector3D(x: Double(0), y: 0, z: 0))
    position = try container
      .decodeIfPresent(NEKeyframeGroup<NELottieVector3D>.self, forKey: .position) ??
      NEKeyframeGroup(NELottieVector3D(x: Double(0), y: 0, z: 0))
    scale = try container
      .decodeIfPresent(NEKeyframeGroup<NELottieVector3D>.self, forKey: .scale) ??
      NEKeyframeGroup(NELottieVector3D(x: Double(100), y: 100, z: 100))

    rotationX = try container
      .decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .rotationX) ?? NEKeyframeGroup(NELottieVector1D(0))
    rotationY = try container
      .decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .rotationY) ?? NEKeyframeGroup(NELottieVector1D(0))
    if
      let rotation = try container
      .decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .rotation) {
      rotationZ = rotation
    } else if
      let rotation = try container
      .decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .rotationZ) {
      rotationZ = rotation
    } else {
      rotationZ = NEKeyframeGroup(NELottieVector1D(0))
    }

    opacity = try container
      .decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .opacity) ?? NEKeyframeGroup(NELottieVector1D(100))
    skew = try container.decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .skew) ?? NEKeyframeGroup(NELottieVector1D(0))
    skewAxis = try container
      .decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .skewAxis) ?? NEKeyframeGroup(NELottieVector1D(0))
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    if
      let anchorDictionary = dictionary[NECodingKeys.anchor.rawValue] as? [String: Any],
      let anchor = try? NEKeyframeGroup<NELottieVector3D>(dictionary: anchorDictionary) {
      self.anchor = anchor
    } else {
      anchor = NEKeyframeGroup(NELottieVector3D(x: Double(0), y: 0, z: 0))
    }
    if
      let positionDictionary = dictionary[NECodingKeys.position.rawValue] as? [String: Any],
      let position = try? NEKeyframeGroup<NELottieVector3D>(dictionary: positionDictionary) {
      self.position = position
    } else {
      position = NEKeyframeGroup(NELottieVector3D(x: Double(0), y: 0, z: 0))
    }
    if
      let scaleDictionary = dictionary[NECodingKeys.scale.rawValue] as? [String: Any],
      let scale = try? NEKeyframeGroup<NELottieVector3D>(dictionary: scaleDictionary) {
      self.scale = scale
    } else {
      scale = NEKeyframeGroup(NELottieVector3D(x: Double(100), y: 100, z: 100))
    }

    if
      let rotationDictionary = dictionary[NECodingKeys.rotationX.rawValue] as? [String: Any],
      let rotation = try? NEKeyframeGroup<NELottieVector1D>(dictionary: rotationDictionary) {
      rotationX = rotation
    } else {
      rotationX = NEKeyframeGroup(NELottieVector1D(0))
    }

    if
      let rotationDictionary = dictionary[NECodingKeys.rotationY.rawValue] as? [String: Any],
      let rotation = try? NEKeyframeGroup<NELottieVector1D>(dictionary: rotationDictionary) {
      rotationY = rotation
    } else {
      rotationY = NEKeyframeGroup(NELottieVector1D(0))
    }

    if
      let rotationDictionary = dictionary[NECodingKeys.rotation.rawValue] as? [String: Any],
      let rotation = try? NEKeyframeGroup<NELottieVector1D>(dictionary: rotationDictionary) {
      rotationZ = rotation
    } else if
      let rotationDictionary = dictionary[NECodingKeys.rotationZ.rawValue] as? [String: Any],
      let rotation = try? NEKeyframeGroup<NELottieVector1D>(dictionary: rotationDictionary) {
      rotationZ = rotation
    } else {
      rotationZ = NEKeyframeGroup(NELottieVector1D(0))
    }

    if
      let opacityDictionary = dictionary[NECodingKeys.opacity.rawValue] as? [String: Any],
      let opacity = try? NEKeyframeGroup<NELottieVector1D>(dictionary: opacityDictionary) {
      self.opacity = opacity
    } else {
      opacity = NEKeyframeGroup(NELottieVector1D(100))
    }
    if
      let skewDictionary = dictionary[NECodingKeys.skew.rawValue] as? [String: Any],
      let skew = try? NEKeyframeGroup<NELottieVector1D>(dictionary: skewDictionary) {
      self.skew = skew
    } else {
      skew = NEKeyframeGroup(NELottieVector1D(0))
    }
    if
      let skewAxisDictionary = dictionary[NECodingKeys.skewAxis.rawValue] as? [String: Any],
      let skewAxis = try? NEKeyframeGroup<NELottieVector1D>(dictionary: skewAxisDictionary) {
      self.skewAxis = skewAxis
    } else {
      skewAxis = NEKeyframeGroup(NELottieVector1D(0))
    }

    try super.init(dictionary: dictionary)
  }

  // MARK: Internal

  /// Anchor Point
  let anchor: NEKeyframeGroup<NELottieVector3D>

  /// Position
  let position: NEKeyframeGroup<NELottieVector3D>

  /// Scale
  let scale: NEKeyframeGroup<NELottieVector3D>

  /// Rotation on X axis
  let rotationX: NEKeyframeGroup<NELottieVector1D>

  /// Rotation on Y axis
  let rotationY: NEKeyframeGroup<NELottieVector1D>

  /// Rotation on Z axis
  let rotationZ: NEKeyframeGroup<NELottieVector1D>

  /// opacity
  let opacity: NEKeyframeGroup<NELottieVector1D>

  /// Skew
  let skew: NEKeyframeGroup<NELottieVector1D>

  /// Skew Axis
  let skewAxis: NEKeyframeGroup<NELottieVector1D>

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: NECodingKeys.self)
    try container.encode(anchor, forKey: .anchor)
    try container.encode(position, forKey: .position)
    try container.encode(scale, forKey: .scale)
    try container.encode(rotationX, forKey: .rotationX)
    try container.encode(rotationY, forKey: .rotationY)
    try container.encode(rotationZ, forKey: .rotationZ)
    try container.encode(opacity, forKey: .opacity)
    try container.encode(skew, forKey: .skew)
    try container.encode(skewAxis, forKey: .skewAxis)
  }

  // MARK: Private

  private enum NECodingKeys: String, CodingKey {
    case anchor = "a"
    case position = "p"
    case scale = "s"
    case rotation = "r"
    case rotationX = "rx"
    case rotationY = "ry"
    case rotationZ = "rz"
    case opacity = "o"
    case skew = "sk"
    case skewAxis = "sa"
  }
}
