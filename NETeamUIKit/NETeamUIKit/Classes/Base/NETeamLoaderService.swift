//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit

@objcMembers
public class NETeamLoaderService: NSObject {
  public static let shared = NETeamLoaderService()

  override private init() {
    super.init()
  }

  /// 初始化方法
  /// 此方法会在模块被加载时调用
  open func setupInit() {
    ChatKitClient.shared.registerInit(NETeamService.shared)
  }
}
