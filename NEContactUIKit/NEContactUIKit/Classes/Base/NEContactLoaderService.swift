//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit

@objcMembers
public class NEContactLoaderService: NSObject {
  public static let shared = NEContactLoaderService()

  override private init() {
    super.init()
  }

  /// 初始化方法
  /// 此方法会在模块被加载时调用
  public func setupInit() {
    ChatKitClient.shared.registerInit(NEContactService.shared)
  }
}
