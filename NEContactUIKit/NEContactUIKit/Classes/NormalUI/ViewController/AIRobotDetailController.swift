// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// 基础版（Normal）机器人名片页
/// Figma node 21724-1554：
///   页面背景 #EFF1F4，NavBar 白色
///   Header：x:20 y:101 w:335 h:74，圆角8，clipsToBounds
///   头像：42×42 圆形（radius:21），距左16
///   操作卡片：x:20 y:187 w:335 h:142，圆角8，行高48，分隔线 #F5F8FC（非最后行）
///   灰色分隔块：h:6，页面全宽
///   聊天行：左右边距20，h:56，圆角8，文字 #337EFF Regular 16
///   删除按钮：距聊天行底 12pt，文字 #E6605C
@objcMembers
open class AIRobotDetailController: NEBaseAIRobotDetailController {
  override open func viewDidLoad() {
    super.viewDidLoad()
    // NormalUI：导航栏背景与页面背景一致（#EFF1F4）
    navigationView.backgroundColor = pageBackgroundColor()
  }

  // MARK: - Figma 精确规格（Normal 皮肤，node 21724-1554）

  override open func pageBackgroundColor() -> UIColor { .ne_lightBackgroundColor }
  override open func cardHorizontalMargin() -> CGFloat { 20 }
  override open func headerTopMargin() -> CGFloat { 0 }
  override open func headerHeight() -> CGFloat { 74 }
  override open func avatarSize() -> CGFloat { 42 }
  /// 问题4：Normal 头像圆形，radius = size/2 = 21
  override open func avatarCornerRadius() -> CGFloat { 21 }
  override open func sectionSpacing() -> CGFloat { 12 }
  override open func rowHeight() -> CGFloat { 48 }
  override open func chatSeparatorHeight() -> CGFloat { 6 }
  override open func chatRowHeight() -> CGFloat { 50 }
  /// Normal：聊天和删除之间间距，让删除文字垂直居中于下半区
  override open func deleteSeparatorHeight() -> CGFloat { 0 }
  override open func deleteRowHeight() -> CGFloat { 50 }
  override open func chatTextColor() -> UIColor { .ne_normalTheme }
  override open func chatLabelFont() -> UIFont { .systemFont(ofSize: 16) }
  override open func deleteLabelFont() -> UIFont { .systemFont(ofSize: 16) }
  override open func confirmButtonColor() -> UIColor { .normalContactThemeColor }

  // MARK: - Style：圆角8，clipsToBounds

  override open func setupHeaderStyle() {
    headerView.layer.cornerRadius = 8
    headerView.clipsToBounds = true
  }

  override open func setupTableStyle() {
    tableView.layer.cornerRadius = 8
    tableView.clipsToBounds = true
    tableView.backgroundColor = .white
  }

  override open func setupChatRowStyle() {
    chatRowView.layer.cornerRadius = 8
    chatRowView.clipsToBounds = true
  }
}
