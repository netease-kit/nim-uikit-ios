// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import UIKit

/// 转发 - 多选 - 已选详情页面 TableViewCell - 协议
protocol NEBaseSelectedListCellDelegate: NSObjectProtocol {
  /// 移除按钮点击事件
  /// - Parameter model: 数据模型
  func removeButtonAction(_ model: MultiSelectModel?)
}

/// 转发 - 多选 - 已选详情页面 TableViewCell -通用版
@objcMembers
open class NEBaseSelectedListCell: NEBaseSelectCell {
  weak var delegate: NEBaseSelectedListCellDelegate?
  private var contentModel: MultiSelectModel?

  /// 移除按钮
  lazy var removeButton: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(UIImage.ne_imageNamed(name: "remove"), for: .normal)
    button.addTarget(self, action: #selector(removeButtonAction), for: .touchUpInside)
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

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
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

    contentView.updateLayoutConstraint(firstItem: titleLabel, seconedItem: contentView, attribute: .right, constant: -48)
  }

  /// 重写设置文案字体方法
  override open func setConfig() {
    super.setConfig()
    titleLabel.textColor = .ne_darkText
    titleLabel.font = .systemFont(ofSize: 16)
    memberLabelMaxWidth = 56
    optionLabel.font = .systemFont(ofSize: 16)
  }

  /// 重写设置model方法
  /// - Parameter model: 转发选择页面数据模型
  func removeButtonAction(_ sender: ExpandButton) {
    delegate?.removeButtonAction(contentModel)
  }

  /// 重写控件内容设置方法
  /// - Parameter model: 数据模型
  override open func setModel(_ model: MultiSelectModel) {
    super.setModel(model)
    contentModel = model
    multiSelectImageView.isHidden = true
    if model.memberCount == 0 {
      // 单聊（人数为 0）不展示人数
      titleLabelMaxWidth = NEConstant.screenWidth - 70 - memberLabelMaxWidth
    } else {
      titleLabelMaxWidth = NEConstant.screenWidth - 122 - memberLabelMaxWidth
    }
  }
}
