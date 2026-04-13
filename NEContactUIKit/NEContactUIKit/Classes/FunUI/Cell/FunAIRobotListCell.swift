// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// Fun 皮肤机器人列表 Cell
/// Figma node 21703-521：头像40×40圆角4，左16，名字17，无箭头，分隔线 #E5E5E5
@objcMembers
open class FunAIRobotListCell: NEBaseAIRobotListCell {
  /// 列表分隔线（颜色 #E5E5E5，非最后行显示）
  public lazy var dividerLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .funContactLineBorderColor
    return view
  }()

  // Fun：头像 40×40 圆角4，左16，名字17，显示箭头（Figma 21703-521: Frame195 x=343 y=29 16×16）
  override open func avatarSize() -> CGFloat { 40 }
  override open func avatarCornerRadius() -> CGFloat { 4 }
  override open func avatarLeading() -> CGFloat { 16 }
  override open func avatarNameSpacing() -> CGFloat { 11 }
  override open func nameFont() -> CGFloat { 17 }
  override open func showArrow() -> Bool { true }

  override open func setupRobotListCellUI() {
    super.setupRobotListCellUI()
    contentView.addSubview(dividerLine)
    NSLayoutConstraint.activate([
      dividerLine.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
      dividerLine.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      dividerLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      dividerLine.heightAnchor.constraint(equalToConstant: 0.5),
    ])
  }
}
