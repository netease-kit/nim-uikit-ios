// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonKit
import NECommonUIKit
import NECoreIM2Kit
import NECoreKit
import UIKit

@objcMembers
open class NEAISearchManager: NSObject, XKitService, IMKitPluginService {
  public static let shared = NEAISearchManager()
  public var serviceName: String = NEAISearchPlugin
  public var versionName: String = "1.0.0"
  public var appKey: String = IMKitClient.instance.appKey()

  override private init() {
    super.init()
  }

  /// 插件初始化
  public func setupInit() {
    XKit.instance().register(self)
    IMKitPluginManager.shared.registerPlugin(serviceName, self)
  }

  // MARK: - IMKitPluginService

  /// 注册插件模型
  /// - Parameter text: 文本内容
  /// - Returns: 插件模型
  public func registerPlugin(_ text: String) -> OperationItem? {
    let item = OperationItem()
    item.text = localizable("operation_ai_word_search")
    item.image = UIImage.ne_imageNamed(name: "op_ai_word")
    item.type = .plugin
    item.onClick = { viewController in

      // 校验网络
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        viewController?.showToast(commonLocalizable("network_error"))
        return
      }

      // 不支持空文本
      if text.isEmpty {
        viewController?.showToast(localizable("not_supported"))
        return
      }

      let aisearchViewController = NEAIWordSearchViewController(text)
      viewController?.navigationController?.present(aisearchViewController, animated: true)
    }
    return item
  }
}
