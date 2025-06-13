// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit
import UIKit

extension UIColor {
  // 导航栏（包含状态栏）背景色
  static let normalConversationNavigationBg = UIColor.white

  // 更多功能 背景色
  static let normalConversationPopViewBg = UIColor.white

  // 会话列表背景色
  static let normalConversationBackgroundColor = UIColor.white

  // 左滑删除按钮背景色
  static let normalConversationDeleteActionColor = NEConstant.hexRGB(0xA8ABB6)
  // 左滑置顶按钮背景色
  static let normalConversationTopActionColor = NEConstant.hexRGB(0x337EFF)

  // 非置顶会话背景色
  static let normalConversationItemBackgroundColor = UIColor.white
  // 置顶会话背景色
  static let normalConversationTopItemBackgroundColor = UIColor(hexString: "#F3F5F7")

  // 断网视图背景色
  static let normalConversationNetworkBrokenBackgroundColor = UIColor(hexString: "#FEE3E6")
  // 断网文案颜色
  static let normalConversationNetworkBrokenTitleColor = UIColor(hexString: "#FC596A")
}
