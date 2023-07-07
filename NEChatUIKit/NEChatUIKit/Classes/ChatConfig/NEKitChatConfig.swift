
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
public class NEKitChatConfig: NSObject {
  public static let shared = NEKitChatConfig()

  public var maxReadingNum = 200 // 群未读显示限制数，默认超过200人不显示已读未读进度

  // chat UI配置相关
  public var ui = ChatUIConfig()

  // chat 其他配置 待扩展
}
