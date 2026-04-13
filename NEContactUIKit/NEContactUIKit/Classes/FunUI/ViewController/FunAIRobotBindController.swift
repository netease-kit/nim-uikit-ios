// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// Fun 皮肤 - 绑定机器人页
/// Figma 21719-1836：页面背景 #EDEDED，导航栏白色，createBotIconView 圆角 4px
@objcMembers
open class FunAIRobotBindController: NEBaseAIRobotBindController {
  override open func viewDidLoad() {
    super.viewDidLoad()
    // FunUI：导航栏白色（Figma Group 1847），页面背景 #EDEDED
    navigationView.backgroundColor = .white
    tableView.register(FunAIRobotBindCell.self, forCellReuseIdentifier: "\(NEBaseAIRobotBindCell.self)")
  }

  override open func pageBackgroundColor() -> UIColor { .funContactNavigationBackgroundColor }
  override open func bindRowHeight() -> CGFloat { 74 }
  override open func createBotRowHeight() -> CGFloat { 74 }
  override open func confirmButtonColor() -> UIColor { .funContactThemeColor }
  // Fun：分区块 8px，section 标签黑色加粗
  override open func dividerBlockHeight() -> CGFloat { 8 }
  override open func sectionLabelFont() -> UIFont { .systemFont(ofSize: 14, weight: .medium) }
  override open func sectionLabelColor() -> UIColor { .black }
  /// Fun：新建机器人图标圆角 4px（Normal 为圆形 18px）
  override open func setupCreateBotIconStyle() {
    createBotIconView.backgroundColor = .funContactThemeColor
    createBotIconView.layer.cornerRadius = 4
  }
}
