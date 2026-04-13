// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// Normal 皮肤 - 绑定机器人页
/// Figma 21852-5678：页面背景 #EFF1F4，导航栏白色，"新建机器人"行右侧有箭头
@objcMembers
open class AIRobotBindController: NEBaseAIRobotBindController {
  override open func viewDidLoad() {
    super.viewDidLoad()
    // NormalUI：导航栏白色，页面背景 #EFF1F4
    navigationView.backgroundColor = .white
    // Normal：新建机器人行显示右侧箭头（Figma layout_Y8ABEI）
    createBotArrowView.isHidden = false
  }

  override open func pageBackgroundColor() -> UIColor { .ne_lightBackgroundColor }
  override open func confirmButtonColor() -> UIColor { .normalContactThemeColor }
}
