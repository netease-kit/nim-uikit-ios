// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// Fun 皮肤 - 绑定页机器人列表 Cell
/// Figma 21719-1836：头像 40×40 圆角4，名字 17px，箭头右距 22px
open class FunAIRobotBindCell: NEBaseAIRobotBindCell {
  override open func avatarSize() -> CGFloat { 40 }
  override open func avatarCornerRadius() -> CGFloat { 4 }
  override open func nameFont() -> CGFloat { 17 }
  // 箭头右距与 Normal 一致：22px（由基类默认值提供，无需覆写）
  override open func separatorColor() -> UIColor { .funContactLineBorderColor }
}
