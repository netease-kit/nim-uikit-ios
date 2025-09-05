// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NEValueProviderStore

/// Registration and storage for `NEAnyValueProvider`s that can dynamically
/// provide custom values for `NEAnimationKeypath`s within a `NELottieAnimation`.
final class NEValueProviderStore {
  // MARK: Lifecycle

  init(logger: NELottieLogger) {
    self.logger = logger
  }

  // MARK: Internal

  /// Registers an `NEAnyValueProvider` for the given `NEAnimationKeypath`
  func setValueProvider(_ valueProvider: NEAnyValueProvider, keypath: NEAnimationKeypath) {
    logger.assert(
      valueProvider.typeErasedStorage.isSupportedByCoreAnimationRenderingEngine,
      """
      The Core Animation rendering engine doesn't support Value Providers that vend a closure,
      because that would require calling the closure on the main thread once per frame.
      """
    )

    let supportedProperties = NEPropertyName.allCases.map { $0.rawValue }
    let propertyBeingCustomized = keypath.keys.last ?? ""

    logger.assert(
      supportedProperties.contains(propertyBeingCustomized),
      """
      The Core Animation rendering engine currently doesn't support customizing "\(propertyBeingCustomized)" \
      properties. Supported properties are: \(supportedProperties.joined(separator: ", ")).
      """
    )

    valueProviders.removeAll(where: { $0.keypath == keypath })
    valueProviders.append((keypath: keypath, valueProvider: valueProvider))
  }

  // Retrieves the custom value keyframes for the given property,
  // if an `NEAnyValueProvider` was registered for the given keypath.
  func customKeyframes<Value>(of customizableProperty: NECustomizableProperty<Value>,
                              for keypath: NEAnimationKeypath,
                              context: NELayerAnimationContext)
    throws -> NEKeyframeGroup<Value>? {
    context.recordHierarchyKeypath?(keypath.fullPath)

    guard let anyValueProvider = valueProvider(for: keypath) else {
      return nil
    }

    // Retrieve the type-erased keyframes from the custom `NEValueProvider`
    let typeErasedKeyframes: [NEKeyframe<Any>]
    switch anyValueProvider.typeErasedStorage {
    case let .singleValue(typeErasedValue):
      typeErasedKeyframes = [NEKeyframe(typeErasedValue)]

    case let .keyframes(keyframes, _):
      typeErasedKeyframes = keyframes

    case .closure:
      try context.logCompatibilityIssue("""
      The Core Animation rendering engine doesn't support Value Providers that vend a closure,
      because that would require calling the closure on the main thread once per frame.
      """)
      return nil
    }

    // Convert the type-erased keyframe values using this `NECustomizableProperty`'s conNEVersion closure
    let typedKeyframes = typeErasedKeyframes.compactMap { typeErasedKeyframe -> NEKeyframe<Value>? in
      guard let convertedValue = customizableProperty.conNEVersion(typeErasedKeyframe.value, anyValueProvider) else {
        logger.assertionFailure("""
        Could not convert value of type \(type(of: typeErasedKeyframe.value)) from \(anyValueProvider) to expected type \(
          Value
            .self)
        """)
        return nil
      }

      return typeErasedKeyframe.withValue(convertedValue)
    }

    // Verify that all of the keyframes were successfully converted to the expected type
    guard typedKeyframes.count == typeErasedKeyframes.count else {
      return nil
    }

    return NEKeyframeGroup(keyframes: ContiguousArray(typedKeyframes))
  }

  // MARK: Private

  private let logger: NELottieLogger
  private var valueProviders = [(keypath: NEAnimationKeypath, valueProvider: NEAnyValueProvider)]()

  /// Retrieves the most-recently-registered Value NEProvider that matches the given keypath.
  private func valueProvider(for keypath: NEAnimationKeypath) -> NEAnyValueProvider? {
    // Find the last keypath matching the given keypath,
    // so we return the value provider that was registered most-recently
    valueProviders.last(where: { registeredKeypath, _ in
      keypath.matches(registeredKeypath)
    })?.valueProvider
  }
}

extension NEAnyValueProviderStorage {
  /// Whether or not this type of value provider is supported
  /// by the new Core Animation rendering engine
  var isSupportedByCoreAnimationRenderingEngine: Bool {
    switch self {
    case .singleValue, .keyframes:
      return true
    case .closure:
      return false
    }
  }
}

extension NEAnimationKeypath {
  /// Whether or not this keypath from the animation hierarchy
  /// matches the given keypath (which may contain wildcards)
  func matches(_ keypath: NEAnimationKeypath) -> Bool {
    var regex = "^" // match the start of the string
      + keypath.keys.joined(separator: "\\.") // match this keypath, escaping "." characters
      + "$" // match the end of the string

    // Replace the ** and * wildcards with markers that are guaranteed to be unique
    // and won't conflict with regex syntax (e.g. `.*`).
    let doubleWildcardMarker = UUID().uuidString
    let singleWildcardMarker = UUID().uuidString
    regex = regex.replacingOccurrences(of: "**", with: doubleWildcardMarker)
    regex = regex.replacingOccurrences(of: "*", with: singleWildcardMarker)

    // "**" wildcards match zero or more path segments separated by "\\."
    //  - "**.Color" matches any of "Color", "Layer 1.Color", and "Layer 1.Layer 2.Color"
    regex = regex.replacingOccurrences(of: "\(doubleWildcardMarker)\\.", with: ".*")
    regex = regex.replacingOccurrences(of: doubleWildcardMarker, with: ".*")

    // "*" wildcards match exactly one path component
    //  - "*.Color" matches "Layer 1.Color" but not "Layer 1.Layer 2.Color"
    regex = regex.replacingOccurrences(of: singleWildcardMarker, with: "[^.]+")

    return fullPath.range(of: regex, options: .regularExpression) != nil
  }
}
