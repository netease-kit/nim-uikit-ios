
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class TeamSettingSubtitleCell: NEBaseTeamSettingCell {
  public var titleWidthAnchor: NSLayoutConstraint?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    setupUI()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open func setupUI() {
    contentView.addSubview(titleLabel)
    contentView.addSubview(subTitleLabel)
    contentView.addSubview(arrow)

    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 36),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
      titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])
    titleWidthAnchor = titleLabel.widthAnchor.constraint(equalToConstant: 0)
    titleWidthAnchor?.isActive = true

    NSLayoutConstraint.activate([
      arrow.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      arrow.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -36),
      arrow.widthAnchor.constraint(equalToConstant: 7),
    ])

    NSLayoutConstraint.activate([
      subTitleLabel.leftAnchor.constraint(equalTo: titleLabel.rightAnchor, constant: 10),
      subTitleLabel.rightAnchor.constraint(equalTo: arrow.leftAnchor, constant: -10),
      subTitleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])
  }

  override open func configure(_ anyModel: Any) {
    super.configure(anyModel)
    if let m = anyModel as? SettingCellModel {
      titleWidthAnchor?.constant = m.titleWidth
      subTitleLabel.text = m.subTitle
    }
  }

  public lazy var subTitleLabel: UILabel = {
    let label = UILabel()
    label.textColor = UIColor(hexString: "0xA6ADB6")
    label.font = NEConstant.defaultTextFont(12.0)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textAlignment = .right
    label.accessibilityIdentifier = "id.subTitleLabel"
    return label
  }()
}
