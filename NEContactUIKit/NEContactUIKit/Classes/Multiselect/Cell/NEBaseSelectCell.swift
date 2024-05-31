
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIM2Kit
import NECoreKit
import UIKit

/// 转发-选择页面 TableViewCell - 基类
@objcMembers
open class NEBaseSelectCell: NEBaseContactViewCell {
  /// 名称最大宽度（不包含人数）
  public var titleLabelMaxWidth = NEConstant.screenWidth - 170 {
    didSet {
      titleLabelWidthAnchor?.constant = titleLabelMaxWidth
    }
  }

  /// 人数最大宽度
  public var memberLabelMaxWidth: CGFloat = 52 {
    didSet {
      memberLabelWidthAnchor?.constant = titleLabelMaxWidth
    }
  }

  /// 名称宽度约束（受单选/多选状态影响）
  public var titleLabelWidthAnchor: NSLayoutConstraint?
  /// 名称宽度约束（受单选/多选状态影响）
  public var memberLabelWidthAnchor: NSLayoutConstraint?
  /// 搜索匹配字符颜色
  public var searchTextColor: UIColor = .ne_normalTheme

  /// 多选选中状态
  lazy var multiSelectImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = UIImage.ne_imageNamed(name: "unselect")
    imageView.accessibilityIdentifier = "id.selector"
    return imageView
  }()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  /// 初始化布局
  open func commonUI() {
    setupCommonCircleHeader()

    // 选中的状态
    contentView.addSubview(multiSelectImageView)
    NSLayoutConstraint.activate([
      multiSelectImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      multiSelectImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
    ])

    // 名称
    contentView.addSubview(titleLabel)
    titleLabelWidthAnchor = titleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: titleLabelMaxWidth)
    titleLabelWidthAnchor?.isActive = true
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 12),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
      titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    // 人数
    contentView.addSubview(optionLabel)
    memberLabelWidthAnchor = optionLabel.widthAnchor.constraint(equalToConstant: memberLabelMaxWidth)
    memberLabelWidthAnchor?.isActive = true
    NSLayoutConstraint.activate([
      optionLabel.leftAnchor.constraint(equalTo: titleLabel.rightAnchor, constant: -0),
      optionLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
      optionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  /// 设置文案字体字号
  open func setConfig() {
    titleLabel.textColor = NEKitContactConfig.shared.ui.contactProperties.itemTitleColor
    nameLabel.font = UIFont.systemFont(ofSize: 14.0)
    nameLabel.textColor = UIColor.white
  }

  /// 设置选中状态显隐
  /// - Parameter isShow: 是否显示
  open func showSelect(_ isShow: Bool) {
    multiSelectImageView.isHidden = !isShow
    leftConstraint?.constant = isShow ? 50 : 20
    titleLabelMaxWidth = NEConstant.screenWidth - (isShow ? 118 + memberLabelMaxWidth : 88 + memberLabelMaxWidth)
  }

  /// 设置控件内容
  /// - Parameter model: 数据模型
  open func setModel(_ model: MultiSelectModel) {
    setConfig()

    multiSelectImageView.isHighlighted = model.isSelected
    titleLabel.text = model.name
    nameLabel.text = NEFriendUserCache.getShortName(model.name ?? "")
    optionLabel.text = model.memberCount > 0 ? " (\(model.memberCount))" : nil

    // 单聊（人数为 0）不展示人数
    if model.memberCount == 0 {
      titleLabelMaxWidth += memberLabelMaxWidth
    }

    if let imageUrl = model.avatar, !imageUrl.isEmpty {
      nameLabel.isHidden = true
      avatarImageView.sd_setImage(with: URL(string: imageUrl), completed: nil)
      avatarImageView.backgroundColor = .clear
    } else {
      nameLabel.isHidden = false
      avatarImageView.sd_setImage(with: nil)
      if let cid = model.conversationId, let sessionId = V2NIMConversationIdUtil.conversationTargetId(cid) {
        avatarImageView.backgroundColor = UIColor.colorWithString(string: sessionId)
      }
    }
  }

  /// 搜索字符
  public var searchText: String? {
    didSet {
      if let searchText = searchText, let titleText = titleLabel.text {
        let attributedStr = NSMutableAttributedString(string: titleText)
        // range 表示从索引几开始取几个字符
        let range = attributedStr.mutableString.range(of: searchText)
        attributedStr.addAttribute(
          .foregroundColor,
          value: searchTextColor,
          range: range
        )
        titleLabel.attributedText = attributedStr
      }
    }
  }
}
