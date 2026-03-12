// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

public extension NEDotLottieFile {
  enum NESynchronouslyBlockingCurrentThread {
    /// Loads an DotLottie from a specific filepath synchronously. Returns a `Result<NEDotLottieFile, Error>`
    /// Please use the asynchronous methods whenever possible. This operation will block the Thread it is running in.
    ///
    /// - Parameter filepath: The absolute filepath of the lottie to load. EG "/User/Me/starAnimation.lottie"
    /// - Parameter dotLottieCache: A cache for holding loaded lotties. Defaults to `LRUDotLottieCache.sharedCache`. Optional.
    public static func loadedFrom(filepath: String,
                                  dotLottieCache: NEDotLottieCacheProvider? = NEDotLottieCache.sharedCache)
      -> Result<NEDotLottieFile, Error> {
      NELottieLogger.shared.assert(
        !Thread.isMainThread,
        "`NEDotLottieFile.NESynchronouslyBlockingCurrentThread` methods shouldn't be called on the main thread."
      )

      /// Check cache for lottie
      if
        let dotLottieCache,
        let lottie = dotLottieCache.file(forKey: filepath) {
        return .success(lottie)
      }

      do {
        /// Decode the lottie.
        let url = URL(fileURLWithPath: filepath)
        let data = try Data(contentsOf: url)
        let lottie = try NEDotLottieFile(data: data, filename: url.deletingPathExtension().lastPathComponent)
        dotLottieCache?.setFile(lottie, forKey: filepath)
        return .success(lottie)
      } catch {
        /// Decoding Error.
        return .failure(error)
      }
    }

    /// Loads a DotLottie model from a bundle by its name synchronously. Returns a `Result<NEDotLottieFile, Error>`
    /// Please use the asynchronous methods whenever possible. This operation will block the Thread it is running in.
    ///
    /// - Parameter name: The name of the lottie file without the lottie extension. EG "StarAnimation"
    /// - Parameter bundle: The bundle in which the lottie is located. Defaults to `Bundle.main`
    /// - Parameter subdirectory: A subdirectory in the bundle in which the lottie is located. Optional.
    /// - Parameter dotLottieCache: A cache for holding loaded lotties. Defaults to `LRUDotLottieCache.sharedCache`. Optional.
    public static func named(_ name: String,
                             bundle: Bundle = Bundle.main,
                             subdirectory: String? = nil,
                             dotLottieCache: NEDotLottieCacheProvider? = NEDotLottieCache.sharedCache)
      -> Result<NEDotLottieFile, Error> {
      NELottieLogger.shared.assert(
        !Thread.isMainThread,
        "`NEDotLottieFile.NESynchronouslyBlockingCurrentThread` methods shouldn't be called on the main thread."
      )

      /// Create a cache key for the lottie.
      let cacheKey = bundle.bundlePath + (subdirectory ?? "") + "/" + name

      /// Check cache for lottie
      if
        let dotLottieCache,
        let lottie = dotLottieCache.file(forKey: cacheKey) {
        return .success(lottie)
      }

      do {
        /// Decode animation.
        let data = try bundle.dotLottieData(name, subdirectory: subdirectory)
        let lottie = try NEDotLottieFile(data: data, filename: name)
        dotLottieCache?.setFile(lottie, forKey: cacheKey)
        return .success(lottie)
      } catch {
        /// Decoding Error.
        NELottieLogger.shared.warn("Error when decoding lottie \"\(name)\": \(error)")
        return .failure(error)
      }
    }

    /// Loads an DotLottie from a data synchronously. Returns a `Result<NEDotLottieFile, Error>`
    ///
    /// Please use the asynchronous methods whenever possible. This operation will block the Thread it is running in.
    ///
    /// - Parameters:
    ///   - data: The data(`Foundation.Data`) object to load DotLottie from
    ///   - filename: The name of the lottie file without the lottie extension. eg. "StarAnimation"
    public static func loadedFrom(data: Data,
                                  filename: String)
      -> Result<NEDotLottieFile, Error> {
      NELottieLogger.shared.assert(
        !Thread.isMainThread,
        "`NEDotLottieFile.NESynchronouslyBlockingCurrentThread` methods shouldn't be called on the main thread."
      )

      do {
        let dotLottieFile = try NEDotLottieFile(data: data, filename: filename)
        return .success(dotLottieFile)
      } catch {
        return .failure(error)
      }
    }
  }

  /// Loads a DotLottie model from a bundle by its name. Returns `nil` if a file is not found.
  ///
  /// - Parameter name: The name of the lottie file without the lottie extension. EG "StarAnimation"
  /// - Parameter bundle: The bundle in which the lottie is located. Defaults to `Bundle.main`
  /// - Parameter subdirectory: A subdirectory in the bundle in which the lottie is located. Optional.
  /// - Parameter dotLottieCache: A cache for holding loaded lotties. Defaults to `LRUDotLottieCache.sharedCache`. Optional.
  @available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
  static func named(_ name: String,
                    bundle: Bundle = Bundle.main,
                    subdirectory: String? = nil,
                    dotLottieCache: NEDotLottieCacheProvider? = NEDotLottieCache.sharedCache)
    async throws -> NEDotLottieFile {
    try await withCheckedThrowingContinuation { continuation in
      NEDotLottieFile.named(name, bundle: bundle, subdirectory: subdirectory, dotLottieCache: dotLottieCache) { result in
        continuation.resume(with: result)
      }
    }
  }

  /// Loads a DotLottie model from a bundle by its name. Returns `nil` if a file is not found.
  ///
  /// - Parameter name: The name of the lottie file without the lottie extension. EG "StarAnimation"
  /// - Parameter bundle: The bundle in which the lottie is located. Defaults to `Bundle.main`
  /// - Parameter subdirectory: A subdirectory in the bundle in which the lottie is located. Optional.
  /// - Parameter dotLottieCache: A cache for holding loaded lotties. Defaults to `LRUDotLottieCache.sharedCache`. Optional.
  /// - Parameter dispatchQueue: A dispatch queue used to load animations. Defaults to `DispatchQueue.global()`. Optional.
  /// - Parameter handleResult: A closure to be called when the file has loaded.
  static func named(_ name: String,
                    bundle: Bundle = Bundle.main,
                    subdirectory: String? = nil,
                    dotLottieCache: NEDotLottieCacheProvider? = NEDotLottieCache.sharedCache,
                    dispatchQueue: DispatchQueue = .dotLottie,
                    handleResult: @escaping (Result<NEDotLottieFile, Error>) -> Void) {
    dispatchQueue.async {
      let result = NESynchronouslyBlockingCurrentThread.named(
        name,
        bundle: bundle,
        subdirectory: subdirectory,
        dotLottieCache: dotLottieCache
      )

      DispatchQueue.main.async {
        handleResult(result)
      }
    }
  }

  /// Loads an DotLottie from a specific filepath.
  /// - Parameter filepath: The absolute filepath of the lottie to load. EG "/User/Me/starAnimation.lottie"
  /// - Parameter dotLottieCache: A cache for holding loaded lotties. Defaults to `LRUDotLottieCache.sharedCache`. Optional.
  @available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
  static func loadedFrom(filepath: String,
                         dotLottieCache: NEDotLottieCacheProvider? = NEDotLottieCache.sharedCache)
    async throws -> NEDotLottieFile {
    try await withCheckedThrowingContinuation { continuation in
      NEDotLottieFile.loadedFrom(filepath: filepath, dotLottieCache: dotLottieCache) { result in
        continuation.resume(with: result)
      }
    }
  }

  /// Loads an DotLottie from a specific filepath.
  /// - Parameter filepath: The absolute filepath of the lottie to load. EG "/User/Me/starAnimation.lottie"
  /// - Parameter dotLottieCache: A cache for holding loaded lotties. Defaults to `LRUDotLottieCache.sharedCache`. Optional.
  /// - Parameter dispatchQueue: A dispatch queue used to load animations. Defaults to `DispatchQueue.global()`. Optional.
  /// - Parameter handleResult: A closure to be called when the file has loaded.
  static func loadedFrom(filepath: String,
                         dotLottieCache: NEDotLottieCacheProvider? = NEDotLottieCache.sharedCache,
                         dispatchQueue: DispatchQueue = .dotLottie,
                         handleResult: @escaping (Result<NEDotLottieFile, Error>) -> Void) {
    dispatchQueue.async {
      let result = NESynchronouslyBlockingCurrentThread.loadedFrom(
        filepath: filepath,
        dotLottieCache: dotLottieCache
      )

      DispatchQueue.main.async {
        handleResult(result)
      }
    }
  }

  /// Loads a DotLottie model from the asset catalog by its name. Returns `nil` if a lottie is not found.
  /// - Parameter name: The name of the lottie file in the asset catalog. EG "StarAnimation"
  /// - Parameter bundle: The bundle in which the lottie is located. Defaults to `Bundle.main`
  /// - Parameter dotLottieCache: A cache for holding loaded lottie files. Defaults to `LRUDotLottieCache.sharedCache` Optional.
  @available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
  static func asset(named name: String,
                    bundle: Bundle = Bundle.main,
                    dotLottieCache: NEDotLottieCacheProvider? = NEDotLottieCache.sharedCache)
    async throws -> NEDotLottieFile {
    try await withCheckedThrowingContinuation { continuation in
      NEDotLottieFile.asset(named: name, bundle: bundle, dotLottieCache: dotLottieCache) { result in
        continuation.resume(with: result)
      }
    }
  }

  ///    Loads a DotLottie model from the asset catalog by its name. Returns `nil` if a lottie is not found.
  ///    - Parameter name: The name of the lottie file in the asset catalog. EG "StarAnimation"
  ///    - Parameter bundle: The bundle in which the lottie is located. Defaults to `Bundle.main`
  ///    - Parameter dotLottieCache: A cache for holding loaded lottie files. Defaults to `LRUDotLottieCache.sharedCache` Optional.
  ///    - Parameter dispatchQueue: A dispatch queue used to load animations. Defaults to `DispatchQueue.global()`. Optional.
  ///    - Parameter handleResult: A closure to be called when the file has loaded.
  static func asset(named name: String,
                    bundle: Bundle = Bundle.main,
                    dotLottieCache: NEDotLottieCacheProvider? = NEDotLottieCache.sharedCache,
                    dispatchQueue: DispatchQueue = .dotLottie,
                    handleResult: @escaping (Result<NEDotLottieFile, Error>) -> Void) {
    dispatchQueue.async {
      /// Create a cache key for the lottie.
      let cacheKey = bundle.bundlePath + "/" + name

      /// Check cache for lottie
      if
        let dotLottieCache,
        let lottie = dotLottieCache.file(forKey: cacheKey) {
        /// If found, return the lottie.
        DispatchQueue.main.async {
          handleResult(.success(lottie))
        }
        return
      }

      do {
        /// Load data from NEAsset
        let data = try Data(assetName: name, in: bundle)

        /// Decode lottie.
        let lottie = try NEDotLottieFile(data: data, filename: name)
        dotLottieCache?.setFile(lottie, forKey: cacheKey)
        DispatchQueue.main.async {
          handleResult(.success(lottie))
        }
      } catch {
        /// Decoding Error.
        DispatchQueue.main.async {
          handleResult(.failure(error))
        }
      }
    }
  }

  /// Loads a DotLottie animation asynchronously from the URL.
  ///
  /// - Parameter url: The url to load the animation from.
  /// - Parameter animationCache: A cache for holding loaded animations. Defaults to `NELRUAnimationCache.sharedCache`. Optional.
  @available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
  static func loadedFrom(url: URL,
                         session: URLSession = .shared,
                         dotLottieCache: NEDotLottieCacheProvider? = NEDotLottieCache.sharedCache)
    async throws -> NEDotLottieFile {
    try await withCheckedThrowingContinuation { continuation in
      NEDotLottieFile.loadedFrom(url: url, session: session, dotLottieCache: dotLottieCache) { result in
        continuation.resume(with: result)
      }
    }
  }

  /// Loads a DotLottie animation asynchronously from the URL.
  ///
  /// - Parameter url: The url to load the animation from.
  /// - Parameter animationCache: A cache for holding loaded animations. Defaults to `NELRUAnimationCache.sharedCache`. Optional.
  /// - Parameter handleResult: A closure to be called when the animation has loaded.
  static func loadedFrom(url: URL,
                         session: URLSession = .shared,
                         dotLottieCache: NEDotLottieCacheProvider? = NEDotLottieCache.sharedCache,
                         handleResult: @escaping (Result<NEDotLottieFile, Error>) -> Void) {
    if let dotLottieCache, let lottie = dotLottieCache.file(forKey: url.absoluteString) {
      handleResult(.success(lottie))
    } else {
      let task = session.dataTask(with: url) { data, _, error in
        do {
          if let error {
            throw error
          }
          guard let data else {
            throw NEDotLottieError.noDataLoaded
          }
          let lottie = try NEDotLottieFile(data: data, filename: url.deletingPathExtension().lastPathComponent)
          DispatchQueue.main.async {
            dotLottieCache?.setFile(lottie, forKey: url.absoluteString)
            handleResult(.success(lottie))
          }
        } catch {
          DispatchQueue.main.async {
            handleResult(.failure(error))
          }
        }
      }
      task.resume()
    }
  }

  /// Loads an DotLottie from a data asynchronously.
  ///
  /// - Parameters:
  ///   - data: The data(`Foundation.Data`) object to load DotLottie from
  ///   - filename: The name of the lottie file without the lottie extension. eg. "StarAnimation"
  ///   - dispatchQueue: A dispatch queue used to load animations. Defaults to `DispatchQueue.global()`. Optional.
  ///   - handleResult: A closure to be called when the file has loaded.
  static func loadedFrom(data: Data,
                         filename: String,
                         dispatchQueue: DispatchQueue = .dotLottie,
                         handleResult: @escaping (Result<NEDotLottieFile, Error>) -> Void) {
    dispatchQueue.async {
      do {
        let dotLottie = try NEDotLottieFile(data: data, filename: filename)
        DispatchQueue.main.async {
          handleResult(.success(dotLottie))
        }
      } catch {
        DispatchQueue.main.async {
          handleResult(.failure(error))
        }
      }
    }
  }

  /// Loads an DotLottie from a data asynchronously.
  ///
  /// - Parameters:
  ///   - data: The data(`Foundation.Data`) object to load DotLottie from
  ///   - filename: The name of the lottie file without the lottie extension. eg. "StarAnimation"
  ///   - dispatchQueue: A dispatch queue used to load animations. Defaults to `DispatchQueue.global()`. Optional.
  @available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
  static func loadedFrom(data: Data,
                         filename: String,
                         dispatchQueue: DispatchQueue = .dotLottie)
    async throws -> NEDotLottieFile {
    try await withCheckedThrowingContinuation { continuation in
      loadedFrom(data: data, filename: filename, dispatchQueue: dispatchQueue) { result in
        continuation.resume(with: result)
      }
    }
  }
}

public extension DispatchQueue {
  /// A serial dispatch queue ensures that IO related to loading dot Lottie files don't overlap,
  /// which can trigger file loading Errors due to concurrent unzipping on a single archive.
  static let dotLottie = DispatchQueue(
    label: "com.airbnb.lottie.dot-lottie",
    qos: .userInitiated
  )
}
