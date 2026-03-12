// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit
import UIKit

public extension UIColor {
  static let funContactThemeColor = UIColor.ne_funTheme
  static let funContactThemeDisableColor = UIColor(hexString: "#58BE6B", 0.5)
  static let funContactLineBorderColor = UIColor(hexString: "#E5E5E5")
  static let funContactUserViewChatTitleTextColor = UIColor(hexString: "#525C8C")
  static let funContactDividerLineColor = UIColor(hexString: "#E4E9F2")

  // 通讯录顶部扩展视图背景色
  static let funContactBodyTopViewBackgroundColor = UIColor.clear

  // 通讯录内容视图背景色
  static let funContactBodyViewBackgroundColor = UIColor.clear

  // 通讯录好友列表背景色
  static let funContactTableViewBackgroundColor = UIColor.clear

  // 通讯录好友列表索引字体颜色
  static let funContactTableViewSectionIndexColor = UIColor.ne_greyText

  // 通讯录底部扩展视图背景色
  static let funContactBodyBottomViewBackgroundColor = UIColor.clear

  // 导航栏（包含状态栏）背景色
  static let funContactNavigationBackgroundColor = UIColor(hexString: "#EDEDED")

  // 通讯录背景色
  static let funContactBackgroundColor = UIColor.funContactNavigationBackgroundColor

  // 通讯录好友背景色
  static let funContactItemBackgroundColor = UIColor.white
  // 通讯录好友分割线背景色
  static let funContactItemLineBackgroundColor = UIColor.funContactLineBorderColor

  // 通讯录分组索引背景色
  static let funContactSectionViewBackgroundColor = UIColor.white
  // 通讯录分组索引文案颜色
  static let funContactSectionViewTitleLabelTextColor = ContactUIConfig.shared.contactProperties.indexTitleColor ?? UIColor.ne_emptyTitleColor

  static let funContactGreenDividerLineColor = UIColor(hexString: "#58BE6B")

  static let funContactNormalTextColor = UIColor(hexString: "#333333")
}
