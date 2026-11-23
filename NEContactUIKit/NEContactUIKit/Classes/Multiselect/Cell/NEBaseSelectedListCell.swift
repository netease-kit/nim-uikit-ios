// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEBaseUIKit
import NEChatKit
import UIKit

/// 转发 - 多选 - 已选详情页面 TableViewCell - 协议
@objc
public protocol NEBaseSelectedListCellDelegate: NSObjectProtocol {
  /// 移除按钮点击事件
  /// - Parameter model: 数据模型
  func removeButtonAction(_ model: MultiSelectModel?)
}

/// 转发 - 多选 - 已选详情页面 TableViewCell -通用版
@objcMembers
open class NEBaseSelectedListCell: NEBaseSelectCell {
  weak var delegate: NEBaseSelectedListCellDelegate?
  private var contentModel: MultiSelectModel?
  /// 上次参与标题宽度计算的 cell 宽度

  /// 移除按钮
  lazy var removeButton: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(coreLoader.loadImage("remove"), for: .normal)
    button.addTarget(self, action: #selector(removeButtonAction), for: .touchUpInside)
    button.accessibilityIdentifier = "id.remove"
    return button
  }()

  /// 分隔线
  public lazy var bottomLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.ne_greyLine
    return view
  }()

  public var bottomLineLeftConstraint: NSLayoutConstraint? // 分隔线左边约束

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  /// 重写布局方法
  override open func commonUI() {
    super.commonUI()

    contentView.addSubview(removeButton)
    NSLayoutConstraint.activate([
      removeButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
      removeButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      removeButton.heightAnchor.constraint(equalToConstant: 20),
      removeButton.widthAnchor.constraint(equalToConstant: 20),
    ])

    contentView.addSubview(bottomLine)
    bottomLineLeftConstraint = bottomLine.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0)
    bottomLineLeftConstraint?.isActive = true
    NSLayoutConstraint.activate([
      bottomLine.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      bottomLine.heightAnchor.constraint(equalToConstant: 1),
    ])

    contentView.updateLayoutConstraint(firstItem: titleLabel, secondItem: contentView, attribute: .right, constant: -48)
  }

  /// 重写设置文案字体方法
  override open func setConfig() {
    super.setConfig()
    titleLabel.textColor = .ne_darkText
    titleLabel.font = .systemFont(ofSize: 16)
    memberLabelMaxWidth = 56
    optionLabel.font = .systemFont(ofSize: 16)
  }

  /// 移除按钮点击事件
  /// - Parameter sender: 按钮
  open func removeButtonAction(_ sender: ExpandButton) {
    delegate?.removeButtonAction(contentModel)
  }

  /// 重写控件内容设置方法
  /// - Parameter model: 数据模型
  override open func setModel(_ model: MultiSelectModel) {
    super.setModel(model)
    contentModel = model
    multiSelectImageView.isHidden = true
    let layoutWidth = contentView.bounds.width > 0 ? contentView.bounds.width : NEConstant.screenWidth
    titleLabelMaxWidth = titleMaxWidth(for: layoutWidth, memberCount: model.memberCount)
  }

  /// “已选”列表的标题上限：按 cell 实际宽度减去人数与移除按钮的预留量。
  ///
  /// 基类在 `layoutSubviews` 里调用本方法；这里覆写以保留“已选”列表自己的预留量。
  override open func recalculateTitleLabelMaxWidth() {
    let width = contentView.bounds.width
    guard width > 0 else { return }
    let target = titleMaxWidth(for: width, memberCount: contentModel?.memberCount ?? 0)
    guard abs(target - titleLabelMaxWidth) > 0.5 else { return }
    titleLabelMaxWidth = target
  }

  /// 标题宽度上限：右侧预留人数与移除按钮的位置，与原先按屏幕宽度计算的分配保持一致。
  /// - Parameters:
  ///   - layoutWidth: 标题所在行的实际宽度
  ///   - memberCount: 会话人数，0 表示单聊（不展示人数）
  private func titleMaxWidth(for layoutWidth: CGFloat, memberCount: Int) -> CGFloat {
    let reservedWidth: CGFloat = memberCount == 0 ? 70 : 122
    return max(0, layoutWidth - reservedWidth - memberLabelMaxWidth)
  }
}
