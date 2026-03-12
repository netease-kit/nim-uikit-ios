
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#if canImport(UIKit)
  import UIKit

  /// An `NEAnimationImageProvider` that provides images by name from a specific bundle.
  /// The NEBundleImageProvider is initialized with a bundle and an optional searchPath.
  public class NEBundleImageProvider: NEAnimationImageProvider {
    // MARK: Lifecycle

    /// Initializes an image provider with a bundle and an optional subpath.
    ///
    /// Provides images for an animation from a bundle. Additionally the provider can
    /// search a specific subpath for the images.
    ///
    /// - Parameter bundle: The bundle containing images for the provider.
    /// - Parameter searchPath: The subpath is a path within the bundle to search for image assets.
    /// - Parameter contentsGravity: The contents gravity to use when rendering the image.
    ///
    public init(bundle: Bundle, searchPath: String?, contentsGravity: CALayerContentsGravity = .resize) {
      self.bundle = bundle
      self.searchPath = searchPath
      self.contentsGravity = contentsGravity
    }

    // MARK: Public

    public func imageForAsset(asset: NEImageAsset) -> CGImage? {
      if let base64Image = asset.base64Image {
        return base64Image
      }

      let imagePath: String?
      /// Try to find the image in the bundle.
      if let searchPath {
        /// Search in the provided search path for the image
        var directoryPath = URL(fileURLWithPath: searchPath)
        directoryPath.appendPathComponent(asset.directory)

        if let path = bundle.path(forResource: asset.name, ofType: nil, inDirectory: directoryPath.path) {
          /// First search for the image in the asset provided sub directory.
          imagePath = path
        } else if let path = bundle.path(forResource: asset.name, ofType: nil, inDirectory: searchPath) {
          /// Try finding the image in the search path.
          imagePath = path
        } else {
          imagePath = bundle.path(forResource: asset.name, ofType: nil)
        }
      } else {
        if let path = bundle.path(forResource: asset.name, ofType: nil, inDirectory: asset.directory) {
          /// First search for the image in the asset provided sub directory.
          imagePath = path
        } else {
          /// First search for the image in bundle.
          imagePath = bundle.path(forResource: asset.name, ofType: nil)
        }
      }

      if imagePath == nil {
        guard let image = UIImage(named: asset.name, in: bundle, compatibleWith: nil) else {
          NELottieLogger.shared.warn("Could not find image \"\(asset.name)\" in bundle")
          return nil
        }
        return image.cgImage
      }

      guard let foundPath = imagePath, let image = UIImage(contentsOfFile: foundPath) else {
        /// No image found.
        NELottieLogger.shared.warn("Could not find image \"\(asset.name)\" in bundle")
        return nil
      }
      return image.cgImage
    }

    public func contentsGravity(for _: NEImageAsset) -> CALayerContentsGravity {
      contentsGravity
    }

    // MARK: Internal

    let bundle: Bundle
    let searchPath: String?
    let contentsGravity: CALayerContentsGravity
  }

  extension NEBundleImageProvider: Equatable {
    public static func == (_ lhs: NEBundleImageProvider, _ rhs: NEBundleImageProvider) -> Bool {
      lhs.bundle == rhs.bundle
        && lhs.searchPath == rhs.searchPath
    }
  }
#endif
