// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// 转发-选择页面-最近转发 CollectionViewCell -通用版
@objcMembers
open class FunRecentSelectCell: NEBaseRecentSelectCell {
  /// 重写布局方法
  override func setupUI() {
    avatarImageView.layer.cornerRadius = 4
    contentView.addSubview(avatarImageView)
    NSLayoutConstraint.activate([
      avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
      avatarImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      avatarImageView.widthAnchor.constraint(equalToConstant: 56),
      avatarImageView.heightAnchor.constraint(equalToConstant: 56),
    ])

    titleLabel.font = .systemFont(ofSize: 12)
    titleLabel.textColor = .ne_greyText
    contentView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
      titleLabel.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
      titleLabel.widthAnchor.constraint(equalToConstant: 64),
      titleLabel.heightAnchor.constraint(equalToConstant: 16),
    ])

    contentView.addSubview(selectImageView)
    NSLayoutConstraint.activate([
      selectImageView.topAnchor.constraint(equalTo: avatarImageView.topAnchor, constant: 4),
      selectImageView.rightAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: -4),
      selectImageView.widthAnchor.constraint(equalToConstant: 18),
      selectImageView.heightAnchor.constraint(equalToConstant: 18),
    ])
  }

  /// 重写控件赋值方法
  /// - Parameter model: 数据模型（MultiSelectModel）
  override func configure(_ model: Any) {
    guard let model = model as? MultiSelectModel else { return }

    super.configure(model)
    selectImageView.image = model.isSelected ? UIImage.ne_imageNamed(name: "fun_select") : UIImage.ne_imageNamed(name: "fun_unselect")
  }
}
