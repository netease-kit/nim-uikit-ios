// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// 转发-选择页面-最近转发 CollectionViewCell -基类
@objcMembers
open class NEBaseRecentSelectCell: NEBaseSelectedCell {
  /// 名称标签
  lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = .ne_darkText
    label.textAlignment = .center
    label.font = .systemFont(ofSize: 12)
    label.accessibilityIdentifier = "id.name"
    return label
  }()

  /// 选择状态
  lazy var selectImageView: UIImageView = {
    let imageView = UIImageView(image: UIImage.ne_imageNamed(name: "unselect"))
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()

  /// 重写布局方法
  override func setupUI() {
    contentView.addSubview(avatarImageView)
    avatarImageView.layer.cornerRadius = 18
    avatarImageView.titleLabel.font = UIFont.systemFont(ofSize: 16.0)
    NSLayoutConstraint.activate([
      avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
      avatarImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      avatarImageView.widthAnchor.constraint(equalToConstant: 36),
      avatarImageView.heightAnchor.constraint(equalToConstant: 36),
    ])

    contentView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
      titleLabel.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
      titleLabel.widthAnchor.constraint(equalToConstant: 72),
      titleLabel.heightAnchor.constraint(equalToConstant: 16),
    ])

    contentView.addSubview(selectImageView)
    NSLayoutConstraint.activate([
      selectImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
      selectImageView.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
      selectImageView.widthAnchor.constraint(equalToConstant: 18),
      selectImageView.heightAnchor.constraint(equalToConstant: 18),
    ])
  }

  /// 设置头像宽高
  /// - Parameter height: 宽高
  func setAvatarWH(_ height: CGFloat) {
    avatarImageView.layer.cornerRadius = height / 2
    avatarImageView.updateLayoutConstraint(firstItem: avatarImageView, seconedItem: nil, attribute: .width, constant: height)
    avatarImageView.updateLayoutConstraint(firstItem: avatarImageView, seconedItem: nil, attribute: .height, constant: height)
  }

  /// 设置选中状态显隐
  /// - Parameter isShow: 是否显示
  func showSelect(_ isShow: Bool) {
    selectImageView.isHidden = !isShow
  }

  /// 重写控件赋值方法
  /// - Parameter model: 数据模型（MultiSelectModel）
  override func configure(_ model: Any) {
    guard let model = model as? MultiSelectModel else { return }

    super.configure(model)
    titleLabel.text = model.name
  }
}
