
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
import NECommonKit
import SDWebImage
import SDWebImageWebPCoder
import SDWebImageSVGKitPlugin

@objcMembers
public class ChatRouter: NSObject {
  public static func setupInit() {
    NIMKitFileLocationHelper.setStaticAppkey(NIMSDK.shared().appKey())
    NIMKitFileLocationHelper.setStaticUserId(NIMSDK.shared().loginManager.currentAccount())
    let webpCoder = SDImageWebPCoder()
    SDImageCodersManager.shared.addCoder(webpCoder)
    let svgCoder = SDImageSVGKCoder.shared
    SDImageCodersManager.shared.addCoder(svgCoder)
  }
}
