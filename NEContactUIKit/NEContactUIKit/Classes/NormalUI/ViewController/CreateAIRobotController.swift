// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// 基础版（Normal）创建机器人页面
/// - 背景色：#EDEDED
/// - 卡片左右留边，圆角 8pt
/// - 导航保存按钮：绿色 #58BE6B
@objcMembers
open class CreateAIRobotController: NEBaseCreateAIRobotController {
  override open func viewDidLoad() {
    super.viewDidLoad()
    // NormalUI：导航栏背景与页面背景一致（#EDEDED）
    navigationView.backgroundColor = pageBackgroundColor()
  }

  override open func pageBackgroundColor() -> UIColor {
    .funContactNavigationBackgroundColor
  }

  override open func saveButtonColor() -> UIColor {
    .normalContactThemeColor
  }

  override open func cardHorizontalMargin() -> CGFloat { 20 }
}
