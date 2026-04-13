// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// Fun 风格的机器人配置串页面
@objcMembers
open class FunAIRobotConfigController: NEBaseAIRobotConfigController {
  override open func viewDidLoad() {
    super.viewDidLoad()
    // FunUI：导航栏白色，页面背景 #EDEDED
    navigationView.backgroundColor = .white
    view.backgroundColor = .funContactNavigationBackgroundColor
  }

  override open func cardTopMargin() -> CGFloat { 12 }

  // Fun：卡片两侧无间距、无圆角
  override open func cardHorizontalMargin() -> CGFloat { 0 }

  override open func copyButtonHorizontalMargin() -> CGFloat { 16 }

  override open func copyButtonCornerRadius() -> CGFloat { 12 }

  override open func setupCardCornerRadius() {
    cardView.layer.cornerRadius = 0
    cardView.clipsToBounds = true
  }

  override open func copyButtonColor() -> UIColor { .funContactThemeColor }
}
