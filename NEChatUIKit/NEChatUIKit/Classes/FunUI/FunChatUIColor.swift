// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit

public extension UIColor {
  static let funChatThemeColor = UIColor.ne_funTheme
  static let funChatBackgroundColor = UIColor(hexString: "#EDEDED")
  static let funChatLineBorderColor = UIColor(hexString: "#E5E5E5")

  // 导航栏（包含状态栏）背景色
  static let funChatNavigationBg = UIColor.funChatBackgroundColor

  // 导航栏分割线背景色
  static let funChatNavigationDivideBg = UIColor(hexString: "#D5D5D5", 0.4)

  // 聊天页面顶部扩展视图背景色
  static let funChatBodyTopViewBg = UIColor.clear

  // 聊天页面内容视图（包含断网视图和消息列表）背景色
  static let funChatBodyViewBg = UIColor.clear

  // 聊天页面断网视图背景色
  static let funChatNetworkBrokenViewBg = UIColor(hexString: "#FCEEEE")
  // 断网文案颜色
  static let funChatNetworkBrokenTitleColor = UIColor(white: 0, alpha: 0.5)

  // 聊天页面消息列表背景色
  static let funChatTableViewBg = ChatUIConfig.shared.messageProperties.chatTableViewBackgroundColor ?? UIColor.clear

  // 聊天页面底部扩展视图背景色
  static let funChatBodyBottomViewBg = UIColor.clear

  // 聊天页面输入区域(包含输入框)背景色
  static let funChatInputViewBg = UIColor(hexString: "#F5F5F5")

  // 输入框背景色(非禁言)
  static let funChatInputBg = UIColor.white

  // 输入框背景色(禁言)
  static let funChatInputMuteBg = UIColor(hexString: "#E0E0E0")

  // 回复视图背景色
  static let funChatReplyViewBg = UIColor(hexString: "#E1E1E1")

  // 更多功能视图背景色
  static let funChatAddMoreViewBg = UIColor(hexString: "#F5F5F5")

  // 【按住 说话】视图背景色
  static let funChatInputHoldspeakBg = UIColor(hexString: "#FFFFFF")
  // 【按住 说话】文案颜色
  static let funChatInputHoldspeakTextColor = UIColor(hexString: "#222222")
  // 更多功能 视图分割线背景色
  static let funChatAddMoreActionViewLineColor = UIColor(hexString: "#DDDDDD")

  static let funRecordAudioViewBg = UIColor(hexString: "#000000")
  static let funRecordAudioTextColor = UIColor(hexString: "#AAAAAA")
  static let funRecordAudioProgressNormalColor = UIColor(hexString: "#A9EA7A")
  static let funRecordAudioProgressCancelColor = UIColor(hexString: "#E75D58")
  static let funRecordAudioLastTimeColor = UIColor(hexString: "#000000", 0.4)

  // 输入框占位文案颜色
  static let funChatInputViewPlaceholderTextColor = ChatUIConfig.shared.messageProperties.inputPlaceholderTextColor ?? UIColor(hexString: "#AAAAAA")

  static let funChatMultiForwardContentColor = UIColor(hexString: "#BBBBBB")
}
