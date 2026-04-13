// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// 通用版（Fun）机器人名片页
/// Figma node 21717-1152：
///   页面背景 #EDEDED
///   Header (Group 1848)：x:0 y:88 w:375 h:82，全宽无圆角，带 inset 底部 0.5px shadow #E5E5E5
///   头像 (Rectangle 1536)：x:16 y:16(header内) w:50 h:50，圆角5，背景 #0F6BFF
///   机器人名 Bot_3：x:82 y:31(header内)，fontSize:16 Regular，#333333
///   操作行（编辑/查看配置串/刷新Token）：每行全宽独立 h:56，文字 x:16，带 inset -0.5px shadow，箭头 x:343 y:20
///   聊天行 (Rectangle 1605)：x:0 y:354 w:375 h:112，聊天文字 #525C8C fontWeight 500
///   删除文字：y:429（距页面顶），距聊天行 y:354 约 56(行)+19=75，文字 #E6605C fontWeight 500
@objcMembers
open class FunAIRobotDetailController: NEBaseAIRobotDetailController {
  override open func viewDidLoad() {
    super.viewDidLoad()
    // Fun 导航栏白色（Figma Group 1847 #FFFFFF）
    navigationView.backgroundColor = .white
    // Fun 头像：50×50，圆角5
    avatarView.layer.cornerRadius = avatarCornerRadius()
    avatarView.clipsToBounds = true
  }

  // MARK: - Figma 精确规格（Fun 皮肤，node 21717-1152）

  override open func pageBackgroundColor() -> UIColor { .funContactNavigationBackgroundColor }
  /// Fun：全宽，无左右边距
  override open func cardHorizontalMargin() -> CGFloat { 0 }
  override open func headerTopMargin() -> CGFloat { 0 }
  /// Header 高度 82pt（layout_HKEAVB: h:82）
  override open func headerHeight() -> CGFloat { 82 }
  /// 头像 50×50（layout_7P5FBO: 50×50）
  override open func avatarSize() -> CGFloat { 50 }
  /// Fun 头像圆角 5px（Figma layout_7P5FBO borderRadius:5px）
  override open func avatarCornerRadius() -> CGFloat { 5 }
  /// 操作区紧接 header（无间隔，各行本身带背景色）
  override open func sectionSpacing() -> CGFloat { 8 }
  /// 操作行高 56pt
  override open func rowHeight() -> CGFloat { 56 }
  /// header 与操作行之间无独立分隔块（Fun 各行直接紧接 header）
  override open func chatSeparatorHeight() -> CGFloat { 8 }
  /// 聊天行高 56pt
  override open func chatRowHeight() -> CGFloat { 56 }
  /// 聊天行与删除按钮之间距离（Figma: 聊天y:373 + 行高56 = 429 = 删除y）
  override open func deleteSeparatorHeight() -> CGFloat { 0 }
  override open func deleteRowHeight() -> CGFloat { 56 }
  /// 聊天文字颜色 #525C8C，fontWeight 500
  override open func chatTextColor() -> UIColor { .funContactUserViewChatTitleTextColor }
  override open func chatLabelFont() -> UIFont { .systemFont(ofSize: 16, weight: .medium) }
  /// 删除文字 fontWeight 500
  override open func deleteLabelFont() -> UIFont { .systemFont(ofSize: 16, weight: .medium) }
  override open func confirmButtonColor() -> UIColor { .funContactThemeColor }

  // MARK: - Style overrides（无圆角，全宽，inset shadow 分隔）

  override open func setupHeaderStyle() {
    // Fun：全宽无圆角，底部分隔线 0.5px #E5E5E5
    headerView.layer.cornerRadius = 0
    headerView.clipsToBounds = false
    headerView.layer.shadowColor = UIColor.funContactLineBorderColor.cgColor
    headerView.layer.shadowOffset = CGSize(width: 0, height: 0.5)
    headerView.layer.shadowRadius = 0
    headerView.layer.shadowOpacity = 1
    headerView.layer.masksToBounds = false
  }

  override open func setupTableStyle() {
    // Fun：无圆角，背景透明（各行自带白色背景）
    tableView.layer.cornerRadius = 0
    tableView.clipsToBounds = false
    tableView.backgroundColor = .clear
  }

  override open func setupChatRowStyle() {
    // Fun：无圆角，全宽（margin=0 已保证）
    chatRowView.layer.cornerRadius = 0
    chatRowView.clipsToBounds = false
  }

  // MARK: - TableView cell：每行独立白色背景 + 底部 inset 0.5px 分隔 #E5E5E5

  override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "AIRobotDetailCell", for: indexPath)
    cell.selectionStyle = .none
    cell.backgroundColor = .white
    cell.textLabel?.text = operationTitles[indexPath.row]
    cell.textLabel?.font = .systemFont(ofSize: 16)
    cell.textLabel?.textColor = .ne_darkText
    // Fun 皮肤：显示右侧箭头（Figma Frame195 x:343 y:20 16×16，每行都有）
    cell.accessoryType = .none
    cell.accessoryView = makeArrowView()
    return cell
  }

  override open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    // Fun：每行（含最后一行）底部 inset 分隔线，inset left:16，颜色 rgba(229,229,229,1)
    let sep = UIView(frame: CGRect(x: 16, y: rowHeight() - 0.5,
                                   width: tableView.bounds.width - 16, height: 0.5))
    sep.backgroundColor = .funContactLineBorderColor
    cell.addSubview(sep)
  }
}
