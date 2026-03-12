// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NELayerProperty

/// A strongly typed value that can be used as the `keyPath` of a `CAAnimation`
///
/// Supported key paths and their expected value types are described
/// at https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreAnimation_guide/AnimatableProperties/AnimatableProperties.html#//apple_ref/doc/uid/TP40004514-CH11-SW1
/// and https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreAnimation_guide/Key-ValueCodingExtensions/Key-ValueCodingExtensions.html
struct NELayerProperty<ValueRepresentation> {
  /// The `CALayer` KVC key path that this value should be assigned to
  let caLayerKeypath: String

  /// Whether or not the given value is the default value for this property
  ///  - If the keyframe values are just equal to the default value,
  ///    then we can improve performance a bit by just not creating
  ///    a CAAnimation (since it would be redundant).
  let isDefaultValue: (ValueRepresentation?) -> Bool

  /// A description of how this property can be customized dynamically
  /// at runtime using `AnimationView.setValueProvider(_:keypath:)`
  let customizableProperty: NECustomizableProperty<ValueRepresentation>?
}

extension NELayerProperty where ValueRepresentation: Equatable {
  /// Initializes a `NELayerProperty` that corresponds to a property on `CALayer`
  /// or some other `CALayer` subclass like `CAShapeLayer`.
  /// - Parameters:
  ///   - caLayerKeypath: The Objective-C `#keyPath` to the `CALayer` property,
  ///     e.g. `#keyPath(CALayer.opacity)` or `#keyPath(CAShapeLayer.path)`.
  ///   - defaultValue: The default value of the property (e.g. the value of the
  ///     property immediately after calling `CALayer.init()`). Knowing this value
  ///     lets us perform some optimizations in `CALayer+addAnimation`.
  ///   - customizableProperty: A description of how this property can be customized
  ///     dynamically at runtime using `AnimationView.setValueProvider(_:keypath:)`.
  init(caLayerKeypath: String,
       defaultValue: ValueRepresentation?,
       customizableProperty: NECustomizableProperty<ValueRepresentation>?) {
    self.init(
      caLayerKeypath: caLayerKeypath,
      isDefaultValue: { $0 == defaultValue },
      customizableProperty: customizableProperty
    )
  }
}

// MARK: - NECustomizableProperty

/// A description of how a `CALayer` property can be customized dynamically
/// at runtime using `NELottieAnimationView.setValueProvider(_:keypath:)`
struct NECustomizableProperty<ValueRepresentation> {
  /// The name that `NEAnimationKeypath`s can use to refer to this property
  ///  - When building an animation for this property that will be applied
  ///    to a specific layer, this `name` is appended to the end of that
  ///    layer's `NEAnimationKeypath`. The combined keypath is used to query
  ///    the `NEValueProviderStore`.
  let name: [NEPropertyName]

  /// A closure that coverts the type-erased value of an `NEAnyValueProvider`
  /// to the strongly-typed representation used by this property, if possible.
  ///  - `value` is the value for the current frame that should be converted,
  ///    as returned by `NEAnyValueProvider.typeErasedStorage`.
  ///  - `valueProvider` is the `NEAnyValueProvider` that returned the type-erased value.
  let conNEVersion: (_ value: Any, _ valueProvider: NEAnyValueProvider) -> ValueRepresentation?
}

// MARK: - NEPropertyName

/// The name of a customizable property that can be used in an `NEAnimationKeypath`
///  - These values should be shared between the two rendering engines,
///    since they form the public API of the `NEAnimationKeypath` system.
enum NEPropertyName: String, CaseIterable {
  case color = "Color"
  case opacity = "Opacity"
  case scale = "Scale"
  case position = "Position"
  case rotation = "Rotation"
  case strokeWidth = "NEStroke Width"
  case gradientColors = "Colors"
}

// MARK: CALayer properties

extension NELayerProperty {
  static var position: NELayerProperty<CGPoint> {
    .init(
      caLayerKeypath: "transform.translation",
      defaultValue: CGPoint(x: 0, y: 0),
      customizableProperty: .position
    )
  }

  static var positionX: NELayerProperty<CGFloat> {
    .init(
      caLayerKeypath: "transform.translation.x",
      defaultValue: 0,
      customizableProperty: nil /* currently unsupported */
    )
  }

  static var positionY: NELayerProperty<CGFloat> {
    .init(
      caLayerKeypath: "transform.translation.y",
      defaultValue: 0,
      customizableProperty: nil /* currently unsupported */
    )
  }

  static var scale: NELayerProperty<CGFloat> {
    .init(
      caLayerKeypath: "transform.scale",
      defaultValue: 1,
      customizableProperty: nil /* currently unsupported */
    )
  }

  static var scaleX: NELayerProperty<CGFloat> {
    .init(
      caLayerKeypath: "transform.scale.x",
      defaultValue: 1,
      customizableProperty: .scaleX
    )
  }

  static var scaleY: NELayerProperty<CGFloat> {
    .init(
      caLayerKeypath: "transform.scale.y",
      defaultValue: 1,
      customizableProperty: .scaleY
    )
  }

  static var rotationX: NELayerProperty<CGFloat> {
    .init(
      caLayerKeypath: "transform.rotation.x",
      defaultValue: 0,
      customizableProperty: nil /* currently unsupported */
    )
  }

  static var rotationY: NELayerProperty<CGFloat> {
    .init(
      caLayerKeypath: "transform.rotation.y",
      defaultValue: 0,
      customizableProperty: nil /* currently unsupported */
    )
  }

  static var rotationZ: NELayerProperty<CGFloat> {
    .init(
      caLayerKeypath: "transform.rotation.z",
      defaultValue: 0,
      customizableProperty: .rotation
    )
  }

  static var anchorPoint: NELayerProperty<CGPoint> {
    .init(
      caLayerKeypath: #keyPath(CALayer.anchorPoint),
      // This is intentionally not `GGPoint(x: 0.5, y: 0.5)` (the actual default)
      // to opt `anchorPoint` out of the KVC `setValue` flow, which causes issues.
      defaultValue: nil,
      customizableProperty: nil /* currently unsupported */
    )
  }

  static var opacity: NELayerProperty<CGFloat> {
    .init(
      caLayerKeypath: #keyPath(CALayer.opacity),
      defaultValue: 1,
      customizableProperty: .opacity
    )
  }

  static var isHidden: NELayerProperty<Bool> {
    .init(
      caLayerKeypath: #keyPath(CALayer.isHidden),
      defaultValue: false,
      customizableProperty: nil /* unsupported */
    )
  }

  static var transform: NELayerProperty<CATransform3D> {
    .init(
      caLayerKeypath: #keyPath(CALayer.transform),
      isDefaultValue: { transform in
        guard let transform else { return false }
        return CATransform3DIsIdentity(transform)
      },
      customizableProperty: nil /* currently unsupported */
    )
  }

  static var shadowOpacity: NELayerProperty<CGFloat> {
    .init(
      caLayerKeypath: #keyPath(CALayer.shadowOpacity),
      defaultValue: 0,
      customizableProperty: nil /* currently unsupported */
    )
  }

  static var shadowColor: NELayerProperty<CGColor> {
    .init(
      caLayerKeypath: #keyPath(CALayer.shadowColor),
      defaultValue: .neRgb(0, 0, 0),
      customizableProperty: nil /* currently unsupported */
    )
  }

  static var shadowRadius: NELayerProperty<CGFloat> {
    .init(
      caLayerKeypath: #keyPath(CALayer.shadowRadius),
      defaultValue: 3.0,
      customizableProperty: nil /* currently unsupported */
    )
  }

  static var shadowOffset: NELayerProperty<CGSize> {
    .init(
      caLayerKeypath: #keyPath(CALayer.shadowOffset),
      defaultValue: CGSize(width: 0, height: -3.0),
      customizableProperty: nil /* currently unsupported */
    )
  }
}

// MARK: CAShapeLayer properties

extension NELayerProperty {
  static var path: NELayerProperty<CGPath> {
    .init(
      caLayerKeypath: #keyPath(CAShapeLayer.path),
      defaultValue: nil,
      customizableProperty: nil /* currently unsupported */
    )
  }

  static var fillColor: NELayerProperty<CGColor> {
    .init(
      caLayerKeypath: #keyPath(CAShapeLayer.fillColor),
      defaultValue: nil,
      customizableProperty: .color
    )
  }

  static var lineWidth: NELayerProperty<CGFloat> {
    .init(
      caLayerKeypath: #keyPath(CAShapeLayer.lineWidth),
      defaultValue: 1,
      customizableProperty: .floatValue(.strokeWidth)
    )
  }

  static var lineDashPhase: NELayerProperty<CGFloat> {
    .init(
      caLayerKeypath: #keyPath(CAShapeLayer.lineDashPhase),
      defaultValue: 0,
      customizableProperty: nil /* currently unsupported */
    )
  }

  static var strokeColor: NELayerProperty<CGColor> {
    .init(
      caLayerKeypath: #keyPath(CAShapeLayer.strokeColor),
      defaultValue: nil,
      customizableProperty: .color
    )
  }

  static var strokeStart: NELayerProperty<CGFloat> {
    .init(
      caLayerKeypath: #keyPath(CAShapeLayer.strokeStart),
      defaultValue: 0,
      customizableProperty: nil /* currently unsupported */
    )
  }

  static var strokeEnd: NELayerProperty<CGFloat> {
    .init(
      caLayerKeypath: #keyPath(CAShapeLayer.strokeEnd),
      defaultValue: 1,
      customizableProperty: nil /* currently unsupported */
    )
  }
}

// MARK: CAGradientLayer properties

extension NELayerProperty {
  static var colors: NELayerProperty<[CGColor]> {
    .init(
      caLayerKeypath: #keyPath(CAGradientLayer.colors),
      defaultValue: nil,
      customizableProperty: .gradientColors
    )
  }

  static var locations: NELayerProperty<[CGFloat]> {
    .init(
      caLayerKeypath: #keyPath(CAGradientLayer.locations),
      defaultValue: nil,
      customizableProperty: .gradientLocations
    )
  }

  static var startPoint: NELayerProperty<CGPoint> {
    .init(
      caLayerKeypath: #keyPath(CAGradientLayer.startPoint),
      defaultValue: nil,
      customizableProperty: nil /* currently unsupported */
    )
  }

  static var endPoint: NELayerProperty<CGPoint> {
    .init(
      caLayerKeypath: #keyPath(CAGradientLayer.endPoint),
      defaultValue: nil,
      customizableProperty: nil /* currently unsupported */
    )
  }
}

// MARK: - NECustomizableProperty types

extension NECustomizableProperty {
  static var color: NECustomizableProperty<CGColor> {
    .init(
      name: [.color],
      conNEVersion: { typeErasedValue, _ in
        guard let color = typeErasedValue as? NELottieColor else {
          return nil
        }

        return .neRgba(CGFloat(color.r), CGFloat(color.g), CGFloat(color.b), CGFloat(color.a))
      }
    )
  }

  static var opacity: NECustomizableProperty<CGFloat> {
    .init(
      name: [.opacity],
      conNEVersion: { typeErasedValue, _ in
        guard let vector = typeErasedValue as? NELottieVector1D else { return nil }

        // Lottie animation files express opacity as a numerical percentage value
        // (e.g. 50%, 100%, 200%) so we divide by 100 to get the decimal values
        // expected by Core Animation (e.g. 0.5, 1.0, 2.0).
        return vector.cgFloatValue / 100
      }
    )
  }

  static var scaleX: NECustomizableProperty<CGFloat> {
    .init(
      name: [.scale],
      conNEVersion: { typeErasedValue, _ in
        guard let vector = typeErasedValue as? NELottieVector3D else { return nil }

        // Lottie animation files express scale as a numerical percentage value
        // (e.g. 50%, 100%, 200%) so we divide by 100 to get the decimal values
        // expected by Core Animation (e.g. 0.5, 1.0, 2.0).
        return vector.pointValue.x / 100
      }
    )
  }

  static var scaleY: NECustomizableProperty<CGFloat> {
    .init(
      name: [.scale],
      conNEVersion: { typeErasedValue, _ in
        guard let vector = typeErasedValue as? NELottieVector3D else { return nil }

        // Lottie animation files express scale as a numerical percentage value
        // (e.g. 50%, 100%, 200%) so we divide by 100 to get the decimal values
        // expected by Core Animation (e.g. 0.5, 1.0, 2.0).
        return vector.pointValue.y / 100
      }
    )
  }

  static var rotation: NECustomizableProperty<CGFloat> {
    .init(
      name: [.rotation],
      conNEVersion: { typeErasedValue, _ in
        guard let vector = typeErasedValue as? NELottieVector1D else { return nil }

        // Lottie animation files express rotation in degrees
        // (e.g. 90º, 180º, 360º) so we covert to radians to get the
        // values expected by Core Animation (e.g. π/2, π, 2π)
        return vector.cgFloatValue * .pi / 180
      }
    )
  }

  static var position: NECustomizableProperty<CGPoint> {
    .init(
      name: [.position],
      conNEVersion: { typeErasedValue, _ in
        guard let vector = typeErasedValue as? NELottieVector3D else { return nil }
        return vector.pointValue
      }
    )
  }

  static var gradientColors: NECustomizableProperty<[CGColor]> {
    .init(
      name: [.gradientColors],
      conNEVersion: { _, typeErasedValueProvider in
        guard let gradientValueProvider = typeErasedValueProvider as? NEGradientValueProvider else { return nil }
        return gradientValueProvider.colors.map { $0.cgColorValue }
      }
    )
  }

  static var gradientLocations: NECustomizableProperty<[CGFloat]> {
    .init(
      name: [.gradientColors],
      conNEVersion: { _, typeErasedValueProvider in
        guard let gradientValueProvider = typeErasedValueProvider as? NEGradientValueProvider else { return nil }
        return gradientValueProvider.locations.map { CGFloat($0) }
      }
    )
  }

  static func floatValue(_ name: NEPropertyName...) -> NECustomizableProperty<CGFloat> {
    .init(
      name: name,
      conNEVersion: { typeErasedValue, _ in
        guard let vector = typeErasedValue as? NELottieVector1D else { return nil }
        return vector.cgFloatValue
      }
    )
  }
}
