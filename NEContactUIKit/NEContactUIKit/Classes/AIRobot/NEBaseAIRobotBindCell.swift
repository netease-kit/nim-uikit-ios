// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseAIRobotBindCell: UITableViewCell {
  // MARK: - Views

  /// 头像
  public lazy var avatarView: NEUserHeaderView = {
    let v = NEUserHeaderView(frame: .zero)
    v.translatesAutoresizingMaskIntoConstraints = false
    v.layer.cornerRadius = avatarCornerRadius()
    v.clipsToBounds = true
    v.titleLabel.font = .systemFont(ofSize: 14)
    v.titleLabel.textColor = .white
    return v
  }()

  /// 机器人名称
  public lazy var nameLabel: UILabel = {
    let l = UILabel()
    l.translatesAutoresizingMaskIntoConstraints = false
    l.font = .systemFont(ofSize: nameFont())
    l.textColor = .ne_darkText
    return l
  }()

  /// 右侧箭头（与群设置 Cell 保持一致，使用 NECommonUIKit arrow_right 资源）
  public lazy var arrowView: UIImageView = {
    let iv = UIImageView(image: coreLoader.loadImage("arrow_right"))
    iv.translatesAutoresizingMaskIntoConstraints = false
    iv.contentMode = .scaleAspectFit
    return iv
  }()

  /// 底部分割线
  public lazy var separator: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.backgroundColor = separatorColor()
    return v
  }()

  // MARK: - Init

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    backgroundColor = .white
    setupCellUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func setupCellUI() {
    // 右侧箭头：不设置宽高（使用图片 intrinsicContentSize，与群设置 Cell 一致）
    contentView.addSubview(arrowView)
    NSLayoutConstraint.activate([
      arrowView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: arrowRightMargin()),
      arrowView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      arrowView.widthAnchor.constraint(equalToConstant: 14),
      arrowView.heightAnchor.constraint(equalToConstant: 14),
    ])

    contentView.addSubview(avatarView)
    NSLayoutConstraint.activate([
      avatarView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
      avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      avatarView.widthAnchor.constraint(equalToConstant: avatarSize()),
      avatarView.heightAnchor.constraint(equalToConstant: avatarSize()),
    ])

    contentView.addSubview(nameLabel)
    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: avatarView.rightAnchor, constant: 12),
      nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      nameLabel.rightAnchor.constraint(equalTo: arrowView.leftAnchor, constant: -8),
    ])

    contentView.addSubview(separator)
    NSLayoutConstraint.activate([
      separator.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
      separator.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      separator.heightAnchor.constraint(equalToConstant: 0.5),
    ])
  }

  // MARK: - Override 点

  /// 头像尺寸（Normal: 36，Fun: 40）
  open func avatarSize() -> CGFloat { 36 }
  /// 头像圆角（Normal: 18 圆形，Fun: 4 方形）
  open func avatarCornerRadius() -> CGFloat { 18 }
  /// 名字字号（Normal: 14，Fun: 17）
  open func nameFont() -> CGFloat { 14 }
  /// 箭头右距（统一 22px，与用户需求一致）
  open func arrowRightMargin() -> CGFloat { -22 }
  /// 分隔线颜色（Normal: .ne_greyLine，Fun: .funContactLineBorderColor）
  open func separatorColor() -> UIColor { .ne_greyLine }

  // MARK: - 数据绑定

  open func configure(bot: V2NIMUserAIBot, isSelected: Bool) {
    let name = bot.name ?? bot.accid
    let shortName = name.count > 2 ? String(name[name.index(name.endIndex, offsetBy: -2)...]) : name
    avatarView.configHeadData(headUrl: bot.icon, name: shortName, uid: bot.accid)
    nameLabel.text = name
    // 绑定页用勾选替代箭头：有选中时隐藏箭头、显示勾；无选中时显示箭头
    arrowView.isHidden = isSelected
  }
}
