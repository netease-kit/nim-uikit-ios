// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit

public extension UIColor {
  // 导航栏（包含状态栏）背景色
  static let normalContactNavigationBackgroundColor = UIColor.white

  // 导航栏分割线背景色
  static let normalContactNavigationDivideBg = UIColor(hexString: "#E9EFF5")

  // 通讯录背景色
  static let normalContactBackgroundColor = UIColor.normalContactNavigationBackgroundColor

  // 通讯录顶部扩展视图背景色
  static let normalContactBodyTopViewBackgroundColor = UIColor.clear

  // 通讯录内容视图背景色
  static let normalContactBodyViewBackgroundColor = UIColor.clear

  // 通讯录好友列表背景色
  static let normalContactTableViewBackgroundColor = UIColor.clear

  // 通讯录好友列表索引字体颜色
  static let normalContactTableViewSectionIndexColor = UIColor.ne_greyText

  // 通讯录底部扩展视图背景色
  static let normalContactBodyBottomViewBackgroundColor = UIColor.clear

  // 通讯录分组索引背景色
  static let normalContactSectionViewBackgroundColor = UIColor.white
  // 通讯录分组索引分割线背景色
  static let normalContactSectionViewLineColor = ContactUIConfig.shared.contactProperties.divideLineColor
  // 通讯录分组索引文案颜色
  static let normalContactSectionViewTitleLabelTextColor = ContactUIConfig.shared.contactProperties.indexTitleColor ?? UIColor.ne_emptyTitleColor

  // 通讯录好友背景色
  static let normalContactItemBackgroundColor = UIColor.white
  // 通讯录好友分割线背景色
  static let normalContactItemLineBackgroundColor = UIColor.ne_greyLine

  static let disableButtonTitleColor = UIColor(hexString: "#DDDDDD")
  /// #F2F4F5, 搜索区域背景颜色
  static let searchTextFeildBackColor = UIColor(hexString: "#F2F4F5")

  static let contactBlueDividerLineColor = UIColor(hexString: "#337EFF")

  static let contactNormalTextColor = UIColor(hexString: "#333333")

  static let contactFusionSelectButtonBGColor = UIColor(hexString: "#337EFF")
}
