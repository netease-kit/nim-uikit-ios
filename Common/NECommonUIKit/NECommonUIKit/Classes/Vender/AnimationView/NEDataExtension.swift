
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

extension Data {
  init(assetName: String, in bundle: Bundle) throws {
    #if canImport(UIKit)
      if let asset = NSDataAsset(name: assetName, bundle: bundle) {
        self = asset.data
        return
      } else {
        throw NEDotLottieError.assetNotFound(name: assetName, bundle: bundle)
      }
    #else
      if #available(macOS 10.11, *) {
        if let asset = NSDataAsset(name: assetName, bundle: bundle) {
          self = asset.data
          return
        } else {
          throw NEDotLottieError.assetNotFound(name: assetName, bundle: bundle)
        }
      }
      throw NEDotLottieError.loadingFromAssetNotSupported
    #endif
  }
}
