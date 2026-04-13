// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// Normal 风格的机器人配置串页面
@objcMembers
open class AIRobotConfigController: NEBaseAIRobotConfigController {
  override open func viewDidLoad() {
    super.viewDidLoad()
    // NormalUI：导航栏背景与页面背景一致（#EDEDED）
    navigationView.backgroundColor = pageBackgroundColor()
  }

  override open func cardTopMargin() -> CGFloat { 12 }

  override open func cardHorizontalMargin() -> CGFloat { 20 }

  override open func copyButtonCornerRadius() -> CGFloat { 8 }

  override open func setupCardCornerRadius() {
    cardView.layer.cornerRadius = 8
    cardView.clipsToBounds = true
  }

  override open func copyButtonColor() -> UIColor { .normalContactThemeColor }
}
