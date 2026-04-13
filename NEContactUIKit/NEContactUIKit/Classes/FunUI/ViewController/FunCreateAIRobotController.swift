// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// 通用版（Fun）创建机器人页面
/// - 背 bgColor：#EFF1F4
/// - 卡片左右留边 20pt，圆角 8pt
/// - 头像圆角改为 4pt（方形）
/// - 分隔线颜色使用 funContactDividerLineColor
/// - 导航保存按钮：蓝色 #337EFF
@objcMembers
open class FunCreateAIRobotController: NEBaseCreateAIRobotController {
  override open func viewDidLoad() {
    super.viewDidLoad()
    // FunUI：导航栏白色，页面背景 #EDEDED
    navigationView.backgroundColor = .white
    // Fun 风格头像改为圆角 4pt（方形）
    avatarImageView.layer.cornerRadius = 4
  }

  override open func pageBackgroundColor() -> UIColor {
    .funContactNavigationBackgroundColor
  }

  override open func saveButtonColor() -> UIColor {
    .funContactThemeColor
  }

  override open func cardHorizontalMargin() -> CGFloat { 20 }

  override open func setupCardBorderRadius() {
    // Fun 风格卡片无圆角
    cardView.layer.cornerRadius = 8
    cardView.clipsToBounds = true
    sectionDivider.backgroundColor = .funContactDividerLineColor
  }
}
