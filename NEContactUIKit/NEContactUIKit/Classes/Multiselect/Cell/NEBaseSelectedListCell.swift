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
  private var measuredLayoutWidth: CGFloat = 0

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
    titleLabelMaxWidth = titleMaxWidth(for: titleLayoutWidth, memberCount: model.memberCount)
  }

  /// 重写布局方法：折叠屏上页面宽度会随当前列宽变化，需要按 cell 的实际宽度重算标题上限。
  override open func layoutSubviews() {
    super.layoutSubviews()
    let width = contentView.bounds.width
    // 宽度没变时直接返回：既避免重复改约束，也避免每次布局都读取设备门禁。
    guard width > 0, abs(width - measuredLayoutWidth) > 0.5 else { return }
    measuredLayoutWidth = width
    guard NEAdaptiveDeviceGate.isFoldableDevice, let contentModel else { return }
    titleLabelMaxWidth = titleMaxWidth(for: width, memberCount: contentModel.memberCount)
  }

  /// 标题宽度上限的参考宽度。
  ///
  /// 折叠屏上转发页跟随当前列布局：单屏时窗口右侧有导航 rail 占位，
  /// 展开双栏时只占详情列，列宽都小于 `NEConstant.screenWidth`。
  /// 继续按屏幕宽度计算上限会让长会话名越过右侧移除按钮，因此改用 cell 的实际宽度；
  /// 普通机型保持按屏幕宽度计算，布局结果与改动前一致。
  private var titleLayoutWidth: CGFloat {
    guard NEAdaptiveDeviceGate.isFoldableDevice else { return NEConstant.screenWidth }
    let width = contentView.bounds.width
    return width > 0 ? width : NEConstant.screenWidth
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
