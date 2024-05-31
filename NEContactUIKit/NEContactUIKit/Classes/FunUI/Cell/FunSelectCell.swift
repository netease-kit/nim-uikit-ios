
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// 转发-选择页面 TableViewCell -通用版
@objcMembers
open class FunSelectCell: NEBaseSelectCell {
  /// 重写初始化方法
  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    searchTextColor = .ne_funTheme
  }

  /// 重写初始化方法
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    searchTextColor = .ne_funTheme
  }

  /// 重写布局方法
  override open func commonUI() {
    super.commonUI()
    multiSelectImageView.highlightedImage = UIImage.ne_imageNamed(name: "fun_select")
  }

  /// 重写设置文案字体方案
  override open func setConfig() {
    super.setConfig()
    titleLabel.font = .systemFont(ofSize: 16)
    optionLabel.font = .systemFont(ofSize: 16)
    memberLabelMaxWidth = 56
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
}
