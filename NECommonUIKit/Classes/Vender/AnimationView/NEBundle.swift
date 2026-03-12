
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)
  import UIKit
#endif

extension Bundle {
  func getAnimationData(_ name: String, subdirectory: String? = nil) throws -> Data {
    // Check for files in the bundle at the given path
    let name = name.removingJSONSuffix()
    if let url = url(forResource: name, withExtension: "json", subdirectory: subdirectory) {
      return try Data(contentsOf: url)
    }

    // Check for data assets
    let assetKey = subdirectory != nil ? "\(subdirectory ?? "")/\(name)" : name
    return try Data(assetName: assetKey, in: self)
  }

  func dotLottieData(_ name: String, subdirectory: String? = nil) throws -> Data {
    // Check for files in the bundle at the given path
    let name = name.removingDotLottieSuffix()
    if let url = url(forResource: name, withExtension: "lottie", subdirectory: subdirectory) {
      return try Data(contentsOf: url)
    }

    let assetKey = subdirectory != nil ? "\(subdirectory ?? "")/\(name)" : name
    return try Data(assetName: assetKey, in: self)
  }
}

private extension String {
  func removingJSONSuffix() -> String {
    // Allow filenames to be passed with a ".json" extension (but not other extensions)
    // to keep the behavior from Lottie 2.x - instead of failing to load the animation
    guard hasSuffix(".json") else {
      return self
    }

    return (self as NSString).deletingPathExtension
  }

  func removingDotLottieSuffix() -> String {
    // Allow filenames to be passed with a ".lottie" extension (but not other extensions)
    // to keep the behavior from Lottie 2.x - instead of failing to load the file
    guard hasSuffix(".lottie") else {
      return self
    }

    return (self as NSString).deletingPathExtension
  }
}
