
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
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
      memberLabelWidthAnchor?.constant = memberLabelMaxWidth
    }
  }

  /// 是否展示人数（决定右侧预留宽度）
  private var showsMemberCount = false
  /// 名称宽度约束（受单选/多选状态影响）
  public var titleLabelWidthAnchor: NSLayoutConstraint?
  /// 名称宽度约束（受单选/多选状态影响）
  public var memberLabelWidthAnchor: NSLayoutConstraint?
  /// 搜索匹配字符颜色
  public var searchTextColor: UIColor = .neUIKitDefaultPrimaryColor

  /// 多选选中状态
  lazy var multiSelectImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = coreLoader.loadImage("unselect")
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
      titleLabel.leftAnchor.constraint(equalTo: userHeaderView.rightAnchor, constant: 12),
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
    titleLabel.textColor = ContactUIConfig.shared.contactProperties.itemTitleColor
  }

  /// 设置选中状态显隐
  /// - Parameter isShow: 是否显示
  open func showSelect(_ isShow: Bool) {
    multiSelectImageView.isHidden = !isShow
    leftConstraint?.constant = isShow ? 50 : 20
    // 名称宽度改由 `recalculateTitleLabelMaxWidth()` 按 cell 实际宽度计算：
    // 折叠屏折叠/展开时列宽会变，继续用 `NEConstant.screenWidth` 会算出超过列宽的上限。
    setNeedsLayout()
  }

  /// 按 cell 的实际宽度重算名称上限。
  ///
  /// 子类可覆写以保留自己的预留量（如“已选”列表）。
  open func recalculateTitleLabelMaxWidth() {
    let width = contentView.bounds.width
    guard width > 0 else { return }
    let left = titleLabel.frame.minX
    guard left > 0 else { return }
    let reserved = (showsMemberCount ? memberLabelMaxWidth : 0) + 20
    let candidate = max(0, width - left - reserved)
    guard abs(candidate - titleLabelMaxWidth) > 0.5 else { return }
    titleLabelMaxWidth = candidate
  }

  override open func layoutSubviews() {
    super.layoutSubviews()
    recalculateTitleLabelMaxWidth()
  }

  /// 设置控件内容
  /// - Parameter model: 数据模型
  open func setModel(_ model: MultiSelectModel) {
    setConfig()

    multiSelectImageView.isHighlighted = model.isSelected
    titleLabel.text = model.name
    showsMemberCount = model.memberCount > 0
    optionLabel.text = showsMemberCount ? " (\(model.memberCount))" : nil
    memberLabelWidthAnchor?.constant = memberLabelMaxWidth
    setNeedsLayout()

    let url = model.avatar
    let accountId = V2NIMConversationIdUtil.conversationTargetId(model.conversationId ?? "") ?? ""
    let name = model.avatarName
      ?? NEFriendUserCache.shared.getFriendInfo(accountId)?.user?.name
      ?? accountId
    userHeaderView.configHeadData(headUrl: url, name: name, uid: accountId)
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
