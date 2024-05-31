
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// 转发-选择页面 TableViewCell -协同版
@objcMembers
open class SelectCell: NEBaseSelectCell {
  /// 重写初始化方法
  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    searchTextColor = UIColor.ne_normalTheme
  }

  /// 重写初始化方法
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    searchTextColor = UIColor.ne_normalTheme
  }

  /// 重写布局方法
  override open func commonUI() {
    super.commonUI()
    multiSelectImageView.highlightedImage = UIImage.ne_imageNamed(name: "select")
  }

  /// 重写设置文案字体方案
  override open func setConfig() {
    super.setConfig()
    titleLabel.font = .systemFont(ofSize: NEKitContactConfig.shared.ui.contactProperties.itemTitleSize > 0 ? NEKitContactConfig.shared.ui.contactProperties.itemTitleSize : 14)
  }

  /// 重写设置头像方法
  override open func setupCommonCircleHeader() {
    super.setupCommonCircleHeader()
    avatarImageView.layer.cornerRadius = 18
    NSLayoutConstraint.activate([
      avatarImageView.widthAnchor.constraint(equalToConstant: 36),
      avatarImageView.heightAnchor.constraint(equalToConstant: 36),
      avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),
    ])
  }
}
