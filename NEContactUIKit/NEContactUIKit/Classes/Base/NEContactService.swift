//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit

@objcMembers
public class NEContactService: NSObject, ChatServiceDelegate {
  public static let shared = NEContactService()

  override private init() {
    super.init()
  }

  /// 注册 NEContactUIKit 初始化协议
  /// - Parameter params: 初始化参数
  public func setupInit(_ params: [String: Any]?) {
    registerRouter(params)
  }

  /// 注册路由
  /// - Parameter param: 参数
  public func registerRouter(_ param: [String: Any]?) {
    if let isFun = param?["isFun"] as? Bool, isFun {
      ContactRouter.registerFun()
    } else {
      ContactRouter.register()
    }
  }
}
