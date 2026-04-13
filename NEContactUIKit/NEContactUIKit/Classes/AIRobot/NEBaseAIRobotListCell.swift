// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonUIKit
import UIKit

@objcMembers
open class NEBaseAIRobotListCell: UITableViewCell {
  public var currentModel: NEAIRobotModel?

  /// 机器人头像
  public lazy var robotHeaderView: NEUserHeaderView = {
    let header = NEUserHeaderView(frame: .zero)
    header.titleLabel.font = NEConstant.defaultTextFont(14)
    header.titleLabel.textColor = UIColor.white
    header.layer.cornerRadius = avatarCornerRadius()
    header.clipsToBounds = true
    header.translatesAutoresizingMaskIntoConstraints = false
    return header
  }()

  /// 机器人名称
  public lazy var robotNameLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(ofSize: nameFont())
    label.textColor = .ne_darkText
    label.accessibilityIdentifier = "id.robotName"
    return label
  }()

  // MARK: - Customization points（子类 override）

  /// 头像尺寸
  open func avatarSize() -> CGFloat { 36 }
  /// 头像圆角（Normal 默认圆形 = size/2 = 18）
  open func avatarCornerRadius() -> CGFloat { 18 }
  /// 头像距左边缘
  open func avatarLeading() -> CGFloat { 20 }
  /// 头像与名字间距
  open func avatarNameSpacing() -> CGFloat { 12 }
  /// 名字字号
  open func nameFont() -> CGFloat { 14 }
  /// 右侧箭头视图（与群设置 Cell 保持一致，使用 NECommonUIKit arrow_right 资源）
  public lazy var arrowView: UIImageView = {
    let imageView = UIImageView(image: coreLoader.loadImage("arrow_right"))
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFit
    return imageView
  }()

  /// 是否显示右侧箭头
  open func showArrow() -> Bool { true }
  /// 箭头距 contentView 右边缘的距离（负值）
  open func arrowRightMargin() -> CGFloat { -16 }
  /// 名字标签距 contentView 右边缘的距离（负值），有箭头时需留出箭头区域
  open func nameRightMargin() -> CGFloat { showArrow() ? arrowRightMargin() - 22 : -16 }

  // MARK: - Init

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    setupRobotListCellUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  /// UI 初始化
  open func setupRobotListCellUI() {
    // 右侧箭头：不设置宽高（使用图片 intrinsicContentSize，与群设置 Cell 完全一致）
    if showArrow() {
      contentView.addSubview(arrowView)
      NSLayoutConstraint.activate([
        arrowView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: arrowRightMargin()),
        arrowView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      ])
    }

    contentView.addSubview(robotHeaderView)
    NSLayoutConstraint.activate([
      robotHeaderView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: avatarLeading()),
      robotHeaderView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      robotHeaderView.widthAnchor.constraint(equalToConstant: avatarSize()),
      robotHeaderView.heightAnchor.constraint(equalToConstant: avatarSize()),
    ])

    contentView.addSubview(robotNameLabel)
    NSLayoutConstraint.activate([
      robotNameLabel.leftAnchor.constraint(equalTo: robotHeaderView.rightAnchor, constant: avatarNameSpacing()),
      robotNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      robotNameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: nameRightMargin()),
    ])
  }

  /// 数据源与 UI 绑定
  open func configure(_ model: NEAIRobotModel) {
    currentModel = model
    let url = model.bot?.icon
    let name = model.bot?.name ?? model.bot?.accid ?? ""
    let shortName = NEFriendUserCache.getShortName(name)
    robotHeaderView.configHeadData(headUrl: url, name: shortName, uid: model.bot?.accid ?? "")
    robotNameLabel.text = name.isEmpty ? model.bot?.accid : name
  }
}
