//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit

@objcMembers
public class NELocalConversationService: NSObject, ChatServiceDelegate {
  public static let shared = NELocalConversationService()

  override private init() {
    super.init()
  }

  /// 注册 NELocalConversationUIKit 初始化协议
  /// - Parameter params: 初始化参数
  open func setupInit(_ params: [String: Any]?) {
    registerRouter(params)
  }

  /// 注册路由
  /// - Parameter param: 参数
  open func registerRouter(_ param: [String: Any]?) {
    // @功能初始化
    if IMKitConfigCenter.shared.enableAtMessage {
      NELocalAtMessageManager.setupInstance()
    }

    if let isFun = param?["isFun"] as? Bool, isFun {
      LocalConversationRouter.registerFun()
    } else {
      LocalConversationRouter.register()
    }
  }
}
