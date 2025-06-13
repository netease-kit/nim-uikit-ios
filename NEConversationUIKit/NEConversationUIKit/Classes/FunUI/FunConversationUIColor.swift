// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit

extension UIColor {
  // 导航栏（包含状态栏）背景色
  static let funConversationNavigationBg = UIColor(hexString: "#EDEDED")

  // 更多功能 背景色
  static let funConversationPopViewBg = UIColor(hexString: "#4C4C4C")

  // 会话列表背景色
  static let funConversationBackgroundColor = UIColor.funConversationNavigationBg
  static let funConversationLineBorderColor = UIColor(hexString: "#E5E5E5")
  static let funConversationListLineBorderColor = UIColor(hexString: "#D8D8D8")
  static let funConversationSearchHeaderViewTitleColor = UIColor(hexString: "#737373")

  // 左滑删除按钮背景色
  static let funConversationDeleteActionColor = UIColor(hexString: "#E75E58")
  // 左滑置顶按钮背景色
  static let funConversationTopActionColor = NEConstant.hexRGB(0x337EFF)

  // 非置顶会话背景色
  static let funConversationItemBackgroundColor = UIColor.white
  // 置顶会话背景色
  static let funConversationTopItemBackgroundColor = UIColor.funConversationBackgroundColor

  // 断网视图背景色
  static let funConversationNetworkBrokenBackgroundColor = UIColor(hexString: "#FCEEEE")
  // 断网文案颜色
  static let funConversationNetworkBrokenTitleColor = UIColor(white: 0, alpha: 0.5)
}
