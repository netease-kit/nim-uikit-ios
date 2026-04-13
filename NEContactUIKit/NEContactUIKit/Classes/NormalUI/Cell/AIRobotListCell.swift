// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// Normal 皮肤机器人列表 Cell
/// Figma node 21724-843：头像36×36圆形，左20，名字14，右侧系统箭头，分隔线 #F5F8FC
@objcMembers
open class AIRobotListCell: NEBaseAIRobotListCell {
  /// 底部分隔线（颜色 #F5F8FC，非最后行显示）
  public lazy var dividerLine: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.backgroundColor = .ne_greyLine
    return v
  }()

  // Normal：头像 36×36 圆形，左20，名字14，箭头右距 -36（与群设置 Normal Cell 一致）
  override open func avatarSize() -> CGFloat { 36 }
  override open func avatarCornerRadius() -> CGFloat { 18 }
  override open func avatarLeading() -> CGFloat { 20 }
  override open func avatarNameSpacing() -> CGFloat { 12 }
  override open func nameFont() -> CGFloat { 14 }
  override open func showArrow() -> Bool { true }
  override open func arrowRightMargin() -> CGFloat { -36 }

  override open func setupRobotListCellUI() {
    super.setupRobotListCellUI()
    contentView.addSubview(dividerLine)
    NSLayoutConstraint.activate([
      dividerLine.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
      dividerLine.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      dividerLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      dividerLine.heightAnchor.constraint(equalToConstant: 0.5),
    ])
  }
}
