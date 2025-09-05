// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

public extension NELottieAnimationView {
  // MARK: Lifecycle

  /// Loads a Lottie animation from a JSON file in the supplied bundle.
  ///
  /// - Parameter name: The string name of the lottie animation with no file extension provided.
  /// - Parameter bundle: The bundle in which the animation is located. Defaults to the Main bundle.
  /// - Parameter subdirectory: A subdirectory in the bundle in which the animation is located. Optional.
  /// - Parameter imageProvider: An image provider for the animation's image data.
  /// If none is supplied Lottie will search in the supplied bundle for images.
  convenience init(name: String,
                   bundle: Bundle = Bundle.main,
                   subdirectory: String? = nil,
                   imageProvider: NEAnimationImageProvider? = nil,
                   animationCache: NEAnimationCacheProvider? = NELottieAnimationCache.shared,
                   configuration: NELottieConfiguration = .shared) {
    let animation = NELottieAnimation.named(name, bundle: bundle, subdirectory: subdirectory, animationCache: animationCache)
    let provider = imageProvider ?? NEBundleImageProvider(bundle: bundle, searchPath: nil)
    self.init(animation: animation, imageProvider: provider, configuration: configuration)
  }

  /// Loads a Lottie animation from a JSON file in a specific path on disk.
  ///
  /// - Parameter name: The absolute path of the Lottie Animation.
  /// - Parameter imageProvider: An image provider for the animation's image data.
  /// If none is supplied Lottie will search in the supplied filepath for images.
  convenience init(filePath: String,
                   imageProvider: NEAnimationImageProvider? = nil,
                   animationCache: NEAnimationCacheProvider? = NELottieAnimationCache.shared,
                   configuration: NELottieConfiguration = .shared) {
    let animation = NELottieAnimation.filepath(filePath, animationCache: animationCache)
    let provider = imageProvider ??
      NEFilepathImageProvider(filepath: URL(fileURLWithPath: filePath).deletingLastPathComponent().path)
    self.init(animation: animation, imageProvider: provider, configuration: configuration)
  }

  /// Loads a Lottie animation asynchronously from the URL
  ///
  /// - Parameter url: The url to load the animation from.
  /// - Parameter imageProvider: An image provider for the animation's image data.
  /// If none is supplied Lottie will search in the main bundle for images.
  /// - Parameter closure: A closure to be called when the animation has loaded.
  convenience init(url: URL,
                   imageProvider: NEAnimationImageProvider? = nil,
                   session: URLSession = .shared,
                   closure: @escaping NELottieAnimationView.DownloadClosure,
                   animationCache: NEAnimationCacheProvider? = NELottieAnimationCache.shared,
                   configuration: NELottieConfiguration = .shared) {
    if let animationCache, let animation = animationCache.animation(forKey: url.absoluteString) {
      self.init(animation: animation, imageProvider: imageProvider, configuration: configuration)
      closure(nil)
    } else {
      self.init(animation: nil, imageProvider: imageProvider, configuration: configuration)

      NELottieAnimation.loadedFrom(url: url, session: session, closure: { animation in
        if let animation {
          self.animation = animation
          closure(nil)
        } else {
          closure(NELottieDownloadError.downloadFailed)
        }
      }, animationCache: animationCache)
    }
  }

  /// Loads a Lottie animation from a JSON file located in the NEAsset catalog of the supplied bundle.
  /// - Parameter name: The string name of the lottie animation in the asset catalog.
  /// - Parameter bundle: The bundle in which the animation is located.
  /// Defaults to the Main bundle.
  /// - Parameter imageProvider: An image provider for the animation's image data.
  /// If none is supplied Lottie will search in the supplied bundle for images.
  convenience init(asset name: String,
                   bundle: Bundle = Bundle.main,
                   imageProvider: NEAnimationImageProvider? = nil,
                   animationCache: NEAnimationCacheProvider? = NELottieAnimationCache.shared,
                   configuration: NELottieConfiguration = .shared) {
    let animation = NELottieAnimation.asset(name, bundle: bundle, animationCache: animationCache)
    let provider = imageProvider ?? NEBundleImageProvider(bundle: bundle, searchPath: nil)
    self.init(animation: animation, imageProvider: provider, configuration: configuration)
  }

  // MARK: DotLottie

  /// Loads a Lottie animation from a .lottie file in the supplied bundle.
  ///
  /// - Parameter dotLottieName: The name of the lottie file without the lottie extension. EG "StarAnimation"
  /// - Parameter bundle: The bundle in which the lottie is located. Defaults to `Bundle.main`
  /// - Parameter subdirectory: A subdirectory in the bundle in which the lottie is located. Optional.
  /// - Parameter animationId: Animation id to play. Optional
  /// - Parameter completion: A closure that is called when the .lottie file is finished loading
  /// Defaults to first animation in file
  convenience init(dotLottieName name: String,
                   bundle: Bundle = Bundle.main,
                   subdirectory: String? = nil,
                   animationId: String? = nil,
                   dotLottieCache: NEDotLottieCacheProvider? = NEDotLottieCache.sharedCache,
                   configuration: NELottieConfiguration = .shared,
                   completion: ((NELottieAnimationView, Error?) -> Void)? = nil) {
    self.init(dotLottie: nil, animationId: animationId, configuration: configuration)
    NEDotLottieFile.named(name, bundle: bundle, subdirectory: subdirectory, dotLottieCache: dotLottieCache) { result in
      switch result {
      case let .success(dotLottieFile):
        self.loadAnimation(animationId, from: dotLottieFile)
        completion?(self, nil)
      case let .failure(error):
        completion?(self, error)
      }
    }
  }

  /// Loads a Lottie from a .lottie file in a specific path on disk.
  ///
  /// - Parameter dotLottieFilePath: The absolute path of the Lottie file.
  /// - Parameter animationId: Animation id to play. Optional
  /// - Parameter completion: A closure that is called when the .lottie file is finished loading
  /// Defaults to first animation in file
  convenience init(dotLottieFilePath filePath: String,
                   animationId: String? = nil,
                   dotLottieCache: NEDotLottieCacheProvider? = NEDotLottieCache.sharedCache,
                   configuration: NELottieConfiguration = .shared,
                   completion: ((NELottieAnimationView, Error?) -> Void)? = nil) {
    self.init(dotLottie: nil, animationId: animationId, configuration: configuration)
    NEDotLottieFile.loadedFrom(filepath: filePath, dotLottieCache: dotLottieCache) { result in
      switch result {
      case let .success(dotLottieFile):
        self.loadAnimation(animationId, from: dotLottieFile)
        completion?(self, nil)
      case let .failure(error):
        completion?(self, error)
      }
    }
  }

  /// Loads a Lottie file asynchronously from the URL
  ///
  /// - Parameter dotLottieUrl: The url to load the lottie file from.
  /// - Parameter animationId: Animation id to play. Optional. Defaults to first animation in file.
  /// - Parameter completion: A closure to be called when the animation has loaded.
  convenience init(dotLottieUrl url: URL,
                   animationId: String? = nil,
                   dotLottieCache: NEDotLottieCacheProvider? = NEDotLottieCache.sharedCache,
                   configuration: NELottieConfiguration = .shared,
                   session: URLSession = .shared,
                   completion: ((NELottieAnimationView, Error?) -> Void)? = nil) {
    if let dotLottieCache, let lottie = dotLottieCache.file(forKey: url.absoluteString) {
      self.init(dotLottie: lottie, animationId: animationId, configuration: configuration)
      completion?(self, nil)
    } else {
      self.init(dotLottie: nil, configuration: configuration)
      NEDotLottieFile.loadedFrom(url: url, session: session, dotLottieCache: dotLottieCache) { result in
        switch result {
        case let .success(lottie):
          self.loadAnimation(animationId, from: lottie)
          completion?(self, nil)
        case let .failure(error):
          completion?(self, error)
        }
      }
    }
  }

  /// Loads a Lottie from a .lottie file located in the NEAsset catalog of the supplied bundle.
  /// - Parameter name: The string name of the lottie file in the asset catalog.
  /// - Parameter bundle: The bundle in which the file is located. Defaults to the Main bundle.
  /// - Parameter animationId: Animation id to play. Optional
  /// - Parameter completion: A closure that is called when the .lottie file is finished loading
  /// Defaults to first animation in file
  convenience init(dotLottieAsset name: String,
                   bundle: Bundle = Bundle.main,
                   animationId: String? = nil,
                   dotLottieCache: NEDotLottieCacheProvider? = NEDotLottieCache.sharedCache,
                   configuration: NELottieConfiguration = .shared,
                   completion: ((NELottieAnimationView, Error?) -> Void)? = nil) {
    self.init(dotLottie: nil, animationId: animationId, configuration: configuration)
    NEDotLottieFile.asset(named: name, bundle: bundle, dotLottieCache: dotLottieCache) { result in
      switch result {
      case let .success(dotLottieFile):
        self.loadAnimation(animationId, from: dotLottieFile)
        completion?(self, nil)
      case let .failure(error):
        completion?(self, error)
      }
    }
  }

  // MARK: Public

  typealias DownloadClosure = (Error?) -> Void
}

// MARK: - NELottieDownloadError

enum NELottieDownloadError: Error {
  case downloadFailed
}
