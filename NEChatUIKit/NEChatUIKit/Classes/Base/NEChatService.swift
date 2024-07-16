//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NIMSDK
import SDWebImage
import SDWebImageSVGKitPlugin
import SDWebImageWebPCoder

@objcMembers
public class NEChatService: NSObject, ChatServiceDelegate, NEChatEmojProtocol {
  public static let shared = NEChatService()

  override private init() {
    super.init()
  }

  /// 注册 NEChatUIKit 初始化协议
  /// - Parameter params: 初始化参数
  public func setupInit(_ params: [String: Any]?) {
    registerRouter(params)
  }

  /// 注册路由
  /// - Parameter param: 参数
  public func registerRouter(_ param: [String: Any]?) {
    if let isFun = param?["isFun"] as? Bool, isFun {
      ChatRouter.registerFun()
    } else {
      ChatRouter.register()
    }

    NIMKitFileLocationHelper.setStaticAppkey(NIMSDK.shared().appKey())
    NIMKitFileLocationHelper.setStaticUserId(IMKitClient.instance.account())
    let webpCoder = SDImageWebPCoder()
    SDImageCodersManager.shared.addCoder(webpCoder)
    let svgCoder = SDImageSVGKCoder.shared
    SDImageCodersManager.shared.addCoder(svgCoder)

    NEChatKitClient.instance.addEmojDelegate(self)
  }

  public func getEmojAttributeString(_ content: String, _ font: CGFloat) -> NSAttributedString? {
    let attributeStr = NEEmotionTool.getAttWithStr(
      str: content,
      font: UIFont.systemFont(ofSize: font)
    )
    return attributeStr
  }
}
