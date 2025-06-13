// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit

public extension UIColor {
  // 导航栏（包含状态栏）背景色
  static let normalChatNavigationBg = UIColor.white

  // 导航栏分割线背景色
  static let normalChatNavigationDivideBg = UIColor(hexString: "#E9EFF5")

  // 聊天页面顶部扩展视图背景色
  static let normalChatBodyTopViewBg = UIColor.clear

  // 聊天页面内容视图（包含断网视图和消息列表）背景色
  static let normalChatBodyViewBg = UIColor.clear

  // 聊天页面断网视图背景色
  static let normalChatNetworkBrokenViewBg = UIColor(hexString: "#FEE3E6")
  // 断网文案颜色
  static let normalChatNetworkBrokenTitleColor = UIColor(hexString: "#FC596A")

  // 聊天页面消息列表背景色
  static let normalChatTableViewBg = ChatUIConfig.shared.messageProperties.chatTableViewBackgroundColor ?? UIColor.white

  // 聊天页面底部扩展视图背景色
  static let normalChatBodyBottomViewBg = UIColor.clear

  // 聊天页面输入区域(包含输入框)背景色
  static let normalChatInputViewBg = UIColor(hexString: "#EFF1F3")

  // 输入框背景色(非禁言)
  static let normalChatInputBg = UIColor.white

  // 输入框背景色(禁言)
  static let normalChatInputMuteBg = UIColor(hexString: "#E3E4E4")

  // 回复视图背景色
  static let normalChatReplyViewBg = UIColor(hexString: "#EFF1F2")

  // 录音视图背景色
  static let normalChatRecordViewBg = UIColor.ne_backgroundColor

  // 更多功能视图背景色
  static let normalChatAddMoreViewBg = UIColor.ne_backgroundColor

  // 输入框占位文案颜色
  static let normalChatInputViewPlaceholderTextColor = ChatUIConfig.shared.messageProperties.inputPlaceholderTextColor ?? UIColor.gray
}
