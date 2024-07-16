//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonUIKit
import UIKit

@objcMembers
open class NEBaseAIUserListCell: UITableViewCell {
  var currentModel: NEAIUserModel?

  /// 数字人头像
  public lazy var aiUserHeaderView: NEUserHeaderView = {
    let header = NEUserHeaderView(frame: .zero)
    header.titleLabel.font = NEConstant.defaultTextFont(14)
    header.titleLabel.textColor = UIColor.white
    header.layer.cornerRadius = 21
    header.clipsToBounds = true
    header.translatesAutoresizingMaskIntoConstraints = false
    return header
  }()

  /// 数字人名称
  public lazy var aiUserNameLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = NEConstant.defaultTextFont(16.0)
    label.textColor = .ne_darkText
    label.accessibilityIdentifier = "id.userName"
    return label
  }()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    setupAIUserListCellUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  /// UI初始化
  open func setupAIUserListCellUI() {
    contentView.addSubview(aiUserHeaderView)
    NSLayoutConstraint.activate([
      aiUserHeaderView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 21),
      aiUserHeaderView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      aiUserHeaderView.widthAnchor.constraint(equalToConstant: 42),
      aiUserHeaderView.heightAnchor.constraint(equalToConstant: 42),
    ])

    contentView.addSubview(aiUserNameLabel)
    NSLayoutConstraint.activate([
      aiUserNameLabel.leftAnchor.constraint(equalTo: aiUserHeaderView.rightAnchor, constant: 14.0),
      aiUserNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      aiUserNameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -116),
    ])
  }

  /// 数据源与UI绑定
  func configure(_ model: NEAIUserModel) {
    currentModel = model
    if let url = model.aiUser?.avatar, !url.isEmpty {
      aiUserHeaderView.sd_setImage(with: URL(string: url), completed: nil)
      aiUserHeaderView.setTitle("")
    } else {
      aiUserHeaderView.image = nil
      aiUserHeaderView.setTitle(model.aiUser?.name ?? "")
      aiUserHeaderView.backgroundColor = UIColor.colorWithString(string: model.aiUser?.accountId)
    }
    if let name = model.aiUser?.name {
      aiUserNameLabel.text = name
    } else {
      aiUserNameLabel.text = model.aiUser?.accountId
    }
  }
}
