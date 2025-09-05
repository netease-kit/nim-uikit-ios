// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

// MARK: - NEDotLottieUtils

enum NEDotLottieUtils {
  static let dotLottieExtension = "lottie"
  static let jsonExtension = "json"

  /// Temp folder to app directory
  static var tempDirectoryURL: URL {
    if #available(iOS 10.0, macOS 10.12, *) {
      return FileManager.default.temporaryDirectory
    }
    return URL(fileURLWithPath: NSTemporaryDirectory())
  }
}

extension URL {
  /// Checks if url is a lottie file
  var isDotLottie: Bool {
    pathExtension == NEDotLottieUtils.dotLottieExtension
  }

  /// Checks if url is a json file
  var isJsonFile: Bool {
    pathExtension == NEDotLottieUtils.jsonExtension
  }

  var urls: [URL] {
    FileManager.default.urls(for: self) ?? []
  }
}

extension FileManager {
  /// Lists urls for all files in a directory
  /// - Parameters:
  ///  - url: URL of directory to search
  ///  - skipsHiddenFiles: If should or not show hidden files
  /// - Returns: Returns urls of all files matching criteria in the directory
  func urls(for url: URL, skipsHiddenFiles: Bool = true) -> [URL]? {
    try? contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: skipsHiddenFiles ? .skipsHiddenFiles : [])
  }
}

// MARK: - NEDotLottieError

public enum NEDotLottieError: Error {
  /// URL response has no data.
  case noDataLoaded
  /// NEAsset with this name was not found in the provided bundle.
  case assetNotFound(name: String, bundle: Bundle?)
  /// Animation loading from asset is not supported on macOS 10.10.
  case loadingFromAssetNotSupported

  @available(*, deprecated, message: "Unused")
  case invalidFileFormat
  @available(*, deprecated, message: "Unused")
  case invalidData
  @available(*, deprecated, message: "Unused")
  case animationNotAvailable
}
