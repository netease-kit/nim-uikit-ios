// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics
import Foundation

public extension NELottieAnimation {
  /// A closure for an Animation download. The closure is passed `nil` if there was an error.
  typealias DownloadClosure = (NELottieAnimation?) -> Void

  /// The duration in seconds of the animation.
  var duration: TimeInterval {
    Double(endFrame - startFrame) / framerate
  }

  /// The natural bounds in points of the animation.
  var bounds: CGRect {
    CGRect(x: 0, y: 0, width: width, height: height)
  }

  /// The natural size in points of the animation.
  var size: CGSize {
    CGSize(width: width, height: height)
  }

  // MARK: Animation (Loading)

  /// Loads an animation model from a bundle by its name. Returns `nil` if an animation is not found.
  ///
  /// - Parameter name: The name of the json file without the json extension. EG "StarAnimation"
  /// - Parameter bundle: The bundle in which the animation is located. Defaults to `Bundle.main`
  /// - Parameter subdirectory: A subdirectory in the bundle in which the animation is located. Optional.
  /// - Parameter animationCache: A cache for holding loaded animations. Defaults to `NELottieAnimationCache.shared`. Optional.
  ///
  /// - Returns: Deserialized `NELottieAnimation`. Optional.
  static func named(_ name: String,
                    bundle: Bundle = Bundle.main,
                    subdirectory: String? = nil,
                    animationCache: NEAnimationCacheProvider? = NELottieAnimationCache.shared)
    -> NELottieAnimation? {
    /// Create a cache key for the animation.
    let cacheKey = bundle.bundlePath + (subdirectory ?? "") + "/" + name

    /// Check cache for animation
    if
      let animationCache,
      let animation = animationCache.animation(forKey: cacheKey) {
      /// If found, return the animation.
      return animation
    }

    do {
      /// Decode animation.
      let json = try bundle.getAnimationData(name, subdirectory: subdirectory)
      let animation = try NELottieAnimation.from(data: json)
      animationCache?.setAnimation(animation, forKey: cacheKey)
      return animation
    } catch {
      /// Decoding error.
      NELottieLogger.shared.warn("Error when decoding animation \"\(name)\": \(error)")
      return nil
    }
  }

  /// Loads an animation from a specific filepath.
  /// - Parameter filepath: The absolute filepath of the animation to load. EG "/User/Me/starAnimation.json"
  /// - Parameter animationCache: A cache for holding loaded animations. Defaults to `NELottieAnimationCache.shared`. Optional.
  ///
  /// - Returns: Deserialized `NELottieAnimation`. Optional.
  static func filepath(_ filepath: String,
                       animationCache: NEAnimationCacheProvider? = NELottieAnimationCache.shared)
    -> NELottieAnimation? {
    /// Check cache for animation
    if
      let animationCache,
      let animation = animationCache.animation(forKey: filepath) {
      return animation
    }

    do {
      /// Decode the animation.
      let json = try Data(contentsOf: URL(fileURLWithPath: filepath))
      let animation = try NELottieAnimation.from(data: json)
      animationCache?.setAnimation(animation, forKey: filepath)
      return animation
    } catch {
      NELottieLogger.shared.warn("""
      Failed to load animation from filepath \(filepath)
      with underlying error: \(error.localizedDescription)
      """)
      return nil
    }
  }

  ///    Loads an animation model from the asset catalog by its name. Returns `nil` if an animation is not found.
  ///    - Parameter name: The name of the json file in the asset catalog. EG "StarAnimation"
  ///    - Parameter bundle: The bundle in which the animation is located. Defaults to `Bundle.main`
  ///    - Parameter animationCache: A cache for holding loaded animations. Defaults to `NELottieAnimationCache.shared` Optional.
  ///    - Returns: Deserialized `NELottieAnimation`. Optional.
  static func asset(_ name: String,
                    bundle: Bundle = Bundle.main,
                    animationCache: NEAnimationCacheProvider? = NELottieAnimationCache.shared)
    -> NELottieAnimation? {
    /// Create a cache key for the animation.
    let cacheKey = bundle.bundlePath + "/" + name

    /// Check cache for animation
    if
      let animationCache,
      let animation = animationCache.animation(forKey: cacheKey) {
      /// If found, return the animation.
      return animation
    }

    do {
      /// Load jsonData from NEAsset
      let json = try Data(assetName: name, in: bundle)
      /// Decode animation.
      let animation = try NELottieAnimation.from(data: json)
      animationCache?.setAnimation(animation, forKey: cacheKey)
      return animation
    } catch {
      NELottieLogger.shared.warn("""
      Failed to load animation with asset name \(name)
      in \(bundle.bundlePath)
      with underlying error: \(error.localizedDescription)
      """)
      return nil
    }
  }

  /// Loads a Lottie animation from a `Data` object containing a JSON animation.
  ///
  /// - Parameter data: The object to load the animation from.
  /// - Parameter strategy: How the data should be decoded. Defaults to using the strategy set in `NELottieConfiguration.shared`.
  /// - Returns: Deserialized `NELottieAnimation`. Optional.
  ///
  static func from(data: Data,
                   strategy: NEDecodingStrategy = NELottieConfiguration.shared.decodingStrategy)
    throws -> NELottieAnimation {
    switch strategy {
    case .legacyCodable:
      return try JSONDecoder().decode(NELottieAnimation.self, from: data)
    case .dictionaryBased:
      let json = try JSONSerialization.jsonObject(with: data)
      guard let dict = json as? [String: Any] else {
        throw NEInitializableError.invalidInput()
      }
      return try NELottieAnimation(dictionary: dict)
    }
  }

  /// Loads a Lottie animation asynchronously from the URL.
  ///
  /// - Parameter url: The url to load the animation from.
  /// - Parameter animationCache: A cache for holding loaded animations. Defaults to `NELottieAnimationCache.shared`. Optional.
  ///
  @available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
  static func loadedFrom(url: URL,
                         session: URLSession = .shared,
                         animationCache: NEAnimationCacheProvider? = NELottieAnimationCache.shared)
    async -> NELottieAnimation? {
    await withCheckedContinuation { continuation in
      NELottieAnimation.loadedFrom(
        url: url,
        session: session,
        closure: { result in
          continuation.resume(returning: result)
        },
        animationCache: animationCache
      )
    }
  }

  /// Loads a Lottie animation asynchronously from the URL.
  ///
  /// - Parameter url: The url to load the animation from.
  /// - Parameter closure: A closure to be called when the animation has loaded.
  /// - Parameter animationCache: A cache for holding loaded animations. Defaults to `NELottieAnimationCache.shared`. Optional.
  ///
  static func loadedFrom(url: URL,
                         session: URLSession = .shared,
                         closure: @escaping NELottieAnimation.DownloadClosure,
                         animationCache: NEAnimationCacheProvider? = NELottieAnimationCache.shared) {
    if let animationCache, let animation = animationCache.animation(forKey: url.absoluteString) {
      closure(animation)
    } else {
      let task = session.dataTask(with: url) { data, _, error in
        guard error == nil, let jsonData = data else {
          DispatchQueue.main.async {
            closure(nil)
          }
          return
        }
        do {
          let animation = try NELottieAnimation.from(data: jsonData)
          DispatchQueue.main.async {
            animationCache?.setAnimation(animation, forKey: url.absoluteString)
            closure(animation)
          }
        } catch {
          DispatchQueue.main.async {
            closure(nil)
          }
        }
      }
      task.resume()
    }
  }

  // MARK: Animation (Helpers)

  /// Markers are a way to describe a point in time by a key name.
  ///
  /// Markers are encoded into animation JSON. By using markers a designer can mark
  /// playback points for a developer to use without having to worry about keeping
  /// track of animation frames. If the animation file is updated, the developer
  /// does not need to update playback code.
  ///
  /// Returns the Progress Time for the marker named. Returns nil if no marker found.
  func progressTime(forMarker named: String) -> NEAnimationProgressTime? {
    guard let markers = markerMap, let marker = markers[named] else {
      return nil
    }
    return progressTime(forFrame: marker.frameTime)
  }

  /// Markers are a way to describe a point in time by a key name.
  ///
  /// Markers are encoded into animation JSON. By using markers a designer can mark
  /// playback points for a developer to use without having to worry about keeping
  /// track of animation frames. If the animation file is updated, the developer
  /// does not need to update playback code.
  ///
  /// Returns the Frame Time for the marker named. Returns nil if no marker found.
  func frameTime(forMarker named: String) -> NEAnimationFrameTime? {
    guard let markers = markerMap, let marker = markers[named] else {
      return nil
    }
    return marker.frameTime
  }

  /// Markers are a way to describe a point in time and a duration by a key name.
  ///
  /// Markers are encoded into animation JSON. By using markers a designer can mark
  /// playback points for a developer to use without having to worry about keeping
  /// track of animation frames. If the animation file is updated, the developer
  /// does not need to update playback code.
  ///
  /// - Returns: The duration frame time for the marker, or `nil` if no marker found.
  func durationFrameTime(forMarker named: String) -> NEAnimationFrameTime? {
    guard let marker = markerMap?[named] else {
      return nil
    }
    return marker.durationFrameTime
  }

  /// Converts Frame Time (Seconds * Framerate) into Progress Time
  /// (optionally clamped to between 0 and 1).
  func progressTime(forFrame frameTime: NEAnimationFrameTime,
                    clamped: Bool = true)
    -> NEAnimationProgressTime {
    let progressTime = ((frameTime - startFrame) / (endFrame - startFrame))

    if clamped {
      return progressTime.clamp(0, 1)
    } else {
      return progressTime
    }
  }

  /// Converts Progress Time (0 to 1) into Frame Time (Seconds * Framerate)
  func frameTime(forProgress progressTime: NEAnimationProgressTime) -> NEAnimationFrameTime {
    ((endFrame - startFrame) * progressTime) + startFrame
  }

  /// Converts Frame Time (Seconds * Framerate) into Time (Seconds)
  func time(forFrame frameTime: NEAnimationFrameTime) -> TimeInterval {
    Double(frameTime - startFrame) / framerate
  }

  /// Converts Time (Seconds) into Frame Time (Seconds * Framerate)
  func frameTime(forTime time: TimeInterval) -> NEAnimationFrameTime {
    CGFloat(time * framerate) + startFrame
  }
}

// MARK: - Foundation.Bundle + Sendable

/// Necessary to suppress warnings like:
/// ```
/// Non-sendable type 'Bundle' exiting main actor-isolated context in call to non-isolated
/// static method 'named(_:bundle:subdirectory:dotLottieCache:)' cannot cross actor boundary
/// ```
/// This retroactive conformance is safe because Sendable is a marker protocol that doesn't
/// include any runtime component. Multiple modules in the same package graph can provide this
/// conformance without causing any conflicts.
///
// swiftlint:disable:next no_unchecked_sendable
extension Foundation.Bundle: @unchecked Sendable {}
