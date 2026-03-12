
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

// MARK: - NEAnyValueProvider

/// `NEAnyValueProvider` is a protocol that return animation data for a property at a
/// given time. Every frame a `NELottieAnimationView` queries all of its properties and asks
/// if their NEValueProvider has an update. If it does the NELottieAnimationView will read the
/// property and update that portion of the animation.
///
/// Value Providers can be used to dynamically set animation properties at run time.
public protocol NEAnyValueProvider {
  /// The Type of the value provider
  var valueType: Any.Type { get }

  /// The type-erased storage for this Value NEProvider
  var typeErasedStorage: NEAnyValueProviderStorage { get }

  /// Asks the provider if it has an update for the given frame.
  func hasUpdate(frame: NEAnimationFrameTime) -> Bool
}

public extension NEAnyValueProvider {
  /// Asks the provider to update the container with its value for the frame.
  func value(frame: NEAnimationFrameTime) -> Any {
    typeErasedStorage.value(frame: frame)
  }
}

// MARK: - NEValueProvider

/// A base protocol for strongly-typed Value Providers
protocol NEValueProvider: NEAnyValueProvider {
  associatedtype Value: NEAnyInterpolatable

  /// The strongly-typed storage for this Value NEProvider
  var storage: NEValueProviderStorage<Value> { get }
}

extension NEValueProvider {
  public var typeErasedStorage: NEAnyValueProviderStorage {
    switch storage {
    case let .closure(typedClosure):
      return .closure(typedClosure)

    case let .singleValue(typedValue):
      return .singleValue(typedValue)

    case let .keyframes(keyframes):
      return .keyframes(
        keyframes.map { keyframe in
          keyframe.withValue(keyframe.value as Any)
        },
        interpolate: storage.value(frame:)
      )
    }
  }
}

// MARK: - NEValueProviderStorage

/// The underlying storage of a `NEValueProvider`
public enum NEValueProviderStorage<T: NEAnyInterpolatable> {
  /// The value provider stores a single value that is used on all frames
  case singleValue(T)

  /// The value provider stores a group of keyframes
  ///  - The main-thread rendering engine interpolates values in these keyframes
  ///    using `T`'s `NEInterpolatable` implementation.
  ///  - The Core Animation rendering engine constructs a `CAKeyframeAnimation`
  ///    using these keyframes. The Core Animation render server performs
  ///    the interpolation, without calling `T`'s `NEInterpolatable` implementation.
  case keyframes([NEKeyframe<T>])

  /// The value provider stores a closure that is invoked on every frame
  ///  - This is only supported by the main-thread rendering engine
  case closure((NEAnimationFrameTime) -> T)

  // MARK: Internal

  func value(frame: NEAnimationFrameTime) -> T {
    switch self {
    case let .singleValue(value):
      return value

    case let .closure(closure):
      return closure(frame)

    case let .keyframes(keyframes):
      return NEKeyframeInterpolator(keyframes: ContiguousArray(keyframes)).storage.value(frame: frame)
    }
  }
}

// MARK: - NEAnyValueProviderStorage

/// A type-erased representation of `NEValueProviderStorage`
public enum NEAnyValueProviderStorage {
  /// The value provider stores a single value that is used on all frames
  case singleValue(Any)

  /// The value provider stores a group of keyframes
  ///  - Since we can't interpolate a type-erased `NEKeyframeGroup`,
  ///    the interpolation has to be performed in the `interpolate` closure.
  case keyframes([NEKeyframe<Any>], interpolate: (NEAnimationFrameTime) -> Any)

  /// The value provider stores a closure that is invoked on every frame
  case closure((NEAnimationFrameTime) -> Any)

  // MARK: Internal

  func value(frame: NEAnimationFrameTime) -> Any {
    switch self {
    case let .singleValue(value):
      return value

    case let .closure(closure):
      return closure(frame)

    case let .keyframes(_, valueForFrame):
      return valueForFrame(frame)
    }
  }
}
