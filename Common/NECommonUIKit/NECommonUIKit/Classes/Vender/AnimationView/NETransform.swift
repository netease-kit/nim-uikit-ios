// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// The animatable transform for a layer. Controls position, rotation, scale, and opacity.
final class NETransform: Codable, NEDictionaryInitializable {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    /// This manual override of decode is required because we want to throw an error
    /// in the case that there is not position data.
    let container = try decoder.container(keyedBy: NETransform.NECodingKeys.self)

    // AnchorPoint
    anchorPoint = try container
      .decodeIfPresent(NEKeyframeGroup<NELottieVector3D>.self, forKey: .anchorPoint) ??
      NEKeyframeGroup(NELottieVector3D(x: Double(0), y: 0, z: 0))

    // Position
    if container.contains(.positionX), container.contains(.positionY) {
      // Position dimensions are split into two keyframe groups
      positionX = try container.decode(NEKeyframeGroup<NELottieVector1D>.self, forKey: .positionX)
      positionY = try container.decode(NEKeyframeGroup<NELottieVector1D>.self, forKey: .positionY)
      position = nil
    } else if let positionKeyframes = try? container.decode(NEKeyframeGroup<NELottieVector3D>.self, forKey: .position) {
      // Position dimensions are a single keyframe group.
      position = positionKeyframes
      positionX = nil
      positionY = nil
    } else if
      let positionContainer = try? container.nestedContainer(keyedBy: PositionCodingKeys.self, forKey: .position),
      let positionX = try? positionContainer.decode(NEKeyframeGroup<NELottieVector1D>.self, forKey: .positionX),
      let positionY = try? positionContainer.decode(NEKeyframeGroup<NELottieVector1D>.self, forKey: .positionY) {
      /// Position keyframes are split and nested.
      self.positionX = positionX
      self.positionY = positionY
      position = nil
    } else {
      /// Default value.
      position = NEKeyframeGroup(NELottieVector3D(x: Double(0), y: 0, z: 0))
      positionX = nil
      positionY = nil
    }

    // Scale
    scale = try container
      .decodeIfPresent(NEKeyframeGroup<NELottieVector3D>.self, forKey: .scale) ??
      NEKeyframeGroup(NELottieVector3D(x: Double(100), y: 100, z: 100))

    // Rotation
    if let rotation = try container.decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .rotationX) {
      rotationX = rotation
    } else {
      rotationX = NEKeyframeGroup(NELottieVector1D(0))
    }

    if let rotation = try container.decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .rotationY) {
      rotationY = rotation
    } else {
      rotationY = NEKeyframeGroup(NELottieVector1D(0))
    }

    if let rotation = try container.decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .rotationZ) {
      rotationZ = rotation
    } else {
      rotationZ = try container
        .decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .rotation) ?? NEKeyframeGroup(NELottieVector1D(0))
    }
    rotation = nil
    // Opacity
    opacity = try container
      .decodeIfPresent(NEKeyframeGroup<NELottieVector1D>.self, forKey: .opacity) ?? NEKeyframeGroup(NELottieVector1D(100))
  }

  init(dictionary: [String: Any]) throws {
    if
      let anchorPointDictionary = dictionary[NECodingKeys.anchorPoint.rawValue] as? [String: Any],
      let anchorPoint = try? NEKeyframeGroup<NELottieVector3D>(dictionary: anchorPointDictionary) {
      self.anchorPoint = anchorPoint
    } else {
      anchorPoint = NETransform.default.anchorPoint
    }

    if
      let xDictionary = dictionary[NECodingKeys.positionX.rawValue] as? [String: Any],
      let yDictionary = dictionary[NECodingKeys.positionY.rawValue] as? [String: Any] {
      positionX = try NEKeyframeGroup<NELottieVector1D>(dictionary: xDictionary)
      positionY = try NEKeyframeGroup<NELottieVector1D>(dictionary: yDictionary)
      position = nil
    } else if
      let positionDictionary = dictionary[NECodingKeys.position.rawValue] as? [String: Any],
      positionDictionary[NEKeyframeGroup<NELottieVector3D>.KeyframeWrapperKey.keyframeData.rawValue] != nil {
      position = try NEKeyframeGroup<NELottieVector3D>(dictionary: positionDictionary)
      positionX = nil
      positionY = nil
    } else if
      let positionDictionary = dictionary[NECodingKeys.position.rawValue] as? [String: Any],
      let xDictionary = positionDictionary[PositionCodingKeys.positionX.rawValue] as? [String: Any],
      let yDictionary = positionDictionary[PositionCodingKeys.positionY.rawValue] as? [String: Any] {
      positionX = try NEKeyframeGroup<NELottieVector1D>(dictionary: xDictionary)
      positionY = try NEKeyframeGroup<NELottieVector1D>(dictionary: yDictionary)
      position = nil
    } else {
      position = NETransform.default.position
      positionX = nil
      positionY = nil
    }

    if
      let scaleDictionary = dictionary[NECodingKeys.scale.rawValue] as? [String: Any],
      let scale = try? NEKeyframeGroup<NELottieVector3D>(dictionary: scaleDictionary) {
      self.scale = scale
    } else {
      scale = NETransform.default.scale
    }

    if
      let rotationDictionary = dictionary[NECodingKeys.rotationX.rawValue] as? [String: Any],
      let rotation = try? NEKeyframeGroup<NELottieVector1D>(dictionary: rotationDictionary) {
      rotationX = rotation
    } else {
      rotationX = NETransform.default.rotationX
    }

    if
      let rotationDictionary = dictionary[NECodingKeys.rotationY.rawValue] as? [String: Any],
      let rotation = try? NEKeyframeGroup<NELottieVector1D>(dictionary: rotationDictionary) {
      rotationY = rotation
    } else {
      rotationY = NETransform.default.rotationY
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
      rotationZ = NETransform.default.rotationZ
    }
    rotation = nil
    if
      let opacityDictionary = dictionary[NECodingKeys.opacity.rawValue] as? [String: Any],
      let opacity = try? NEKeyframeGroup<NELottieVector1D>(dictionary: opacityDictionary) {
      self.opacity = opacity
    } else {
      opacity = NETransform.default.opacity
    }
  }

  init(anchorPoint: NEKeyframeGroup<NELottieVector3D>,
       position: NEKeyframeGroup<NELottieVector3D>?,
       positionX: NEKeyframeGroup<NELottieVector1D>?,
       positionY: NEKeyframeGroup<NELottieVector1D>?,
       scale: NEKeyframeGroup<NELottieVector3D>,
       rotationX: NEKeyframeGroup<NELottieVector1D>,
       rotationY: NEKeyframeGroup<NELottieVector1D>,
       rotationZ: NEKeyframeGroup<NELottieVector1D>,
       opacity: NEKeyframeGroup<NELottieVector1D>,
       rotation: NEKeyframeGroup<NELottieVector1D>?) {
    self.anchorPoint = anchorPoint
    self.position = position
    self.positionX = positionX
    self.positionY = positionY
    self.scale = scale
    self.rotationX = rotationX
    self.rotationY = rotationY
    self.rotationZ = rotationZ
    self.opacity = opacity
    self.rotation = rotation
  }

  // MARK: Internal

  enum NECodingKeys: String, CodingKey {
    case anchorPoint = "a"
    case position = "p"
    case positionX = "px"
    case positionY = "py"
    case scale = "s"
    case rotation = "r"
    case rotationX = "rx"
    case rotationY = "ry"
    case rotationZ = "rz"
    case opacity = "o"
  }

  enum PositionCodingKeys: String, CodingKey {
    case split = "s"
    case positionX = "x"
    case positionY = "y"
  }

  /// Default transform values to use if no transform is provided
  static var `default`: NETransform {
    NETransform(
      anchorPoint: NEKeyframeGroup(NELottieVector3D(x: Double(0), y: 0, z: 0)),
      position: NEKeyframeGroup(NELottieVector3D(x: Double(0), y: 0, z: 0)),
      positionX: nil,
      positionY: nil,
      scale: NEKeyframeGroup(NELottieVector3D(x: Double(100), y: 100, z: 100)),
      rotationX: NEKeyframeGroup(NELottieVector1D(0)),
      rotationY: NEKeyframeGroup(NELottieVector1D(0)),
      rotationZ: NEKeyframeGroup(NELottieVector1D(0)),
      opacity: NEKeyframeGroup(NELottieVector1D(100)),
      rotation: nil
    )
  }

  /// The anchor point of the transform.
  let anchorPoint: NEKeyframeGroup<NELottieVector3D>

  /// The position of the transform. This is nil if the position data was split.
  let position: NEKeyframeGroup<NELottieVector3D>?

  /// The positionX of the transform. This is nil if the position property is set.
  let positionX: NEKeyframeGroup<NELottieVector1D>?

  /// The positionY of the transform. This is nil if the position property is set.
  let positionY: NEKeyframeGroup<NELottieVector1D>?

  /// The scale of the transform.
  let scale: NEKeyframeGroup<NELottieVector3D>

  /// The rotation of the transform on X axis.
  let rotationX: NEKeyframeGroup<NELottieVector1D>

  /// The rotation of the transform on Y axis.
  let rotationY: NEKeyframeGroup<NELottieVector1D>

  /// The rotation of the transform on Z axis.
  let rotationZ: NEKeyframeGroup<NELottieVector1D>

  /// The opacity of the transform.
  let opacity: NEKeyframeGroup<NELottieVector1D>

  // MARK: Private

  /// Here for the NECodingKeys.rotation = "r". `r` and `rz` are the same.
  private let rotation: NEKeyframeGroup<NELottieVector1D>?
}
