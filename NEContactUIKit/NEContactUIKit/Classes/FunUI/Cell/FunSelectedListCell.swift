// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import UIKit

/// 转发-多选-已选详情页面 TableViewCell -通用版
@objcMembers
open class FunSelectedListCell: NEBaseSelectedListCell {
  /// 重写初始化方法
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  /// 重写设置头像方法
  override open func setupCommonCircleHeader() {
    super.setupCommonCircleHeader()
    avatarImageView.layer.cornerRadius = 4
    NSLayoutConstraint.activate([
      avatarImageView.widthAnchor.constraint(equalToConstant: 40),
      avatarImageView.heightAnchor.constraint(equalToConstant: 40),
      avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),
    ])
  }

  /// 重写布局方法
  override open func commonUI() {
    super.commonUI()
    bottomLineLeftConstraint?.constant = 16
  }
}
