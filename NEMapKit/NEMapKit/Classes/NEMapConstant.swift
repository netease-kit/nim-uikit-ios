//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatUIKit
import NECoreKit

let mapCoreLoader = MapCoreLoader()
func mapLocalizable(_ key: String) -> String {
  mapCoreLoader.localizable(key)
}

let tencentMapDownloadUrl = "https://apps.apple.com/cn/app/%E8%85%BE%E8%AE%AF%E5%9C%B0%E5%9B%BE-%E8%B7%AF%E7%BA%BF%E8%A7%84%E5%88%92-%E5%AF%BC%E8%88%AA%E6%89%93%E8%BD%A6%E5%87%BA%E8%A1%8C/id481623196"

let aMapDownloadUrl = "https://itunes.apple.com/us/app/gao-tu-zhuan-ye-shou-ji-tu/id461703208?mt=8"

public class MapCoreLoader: NSObject {
  public var bundle: Bundle?

  override public init() {
    super.init()
    if let bundleURL = Bundle.main.url(forResource: "NEMapKit", withExtension: "bundle") {
      bundle = Bundle(url: bundleURL)
    }
  }

  public func localizable(_ key: String) -> String {
    let value = NEChatUIKitClient.instance.getLanguage(key: key) ?? ""
    return value
  }

  public func loadImage(_ name: String) -> UIImage? {
    let image = NEChatUIKitClient.instance.getImageSource(imageName: name)
    return image
  }
}
