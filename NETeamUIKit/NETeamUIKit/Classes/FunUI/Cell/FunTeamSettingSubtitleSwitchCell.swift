// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import UIKit

@objcMembers
open class FunTeamSettingSubtitleSwitchCell: NEBaseTeamSettingSubtitleSwitchCell {
  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    edgeInset = .zero
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func setupUI() {
    super.setupUI()
    contentView.updateLayoutConstraint(firstItem: dividerLine, secondItem: contentView, attribute: .left, constant: 16)
    contentView.updateLayoutConstraint(firstItem: dividerLine, secondItem: contentView, attribute: .right, constant: 0)

    tSwitch.onTintColor = .funTeamThemeColor
    NSLayoutConstraint.activate([
      //      tSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      tSwitch.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      tSwitch.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -14),
    ])

    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
      titleLabel.rightAnchor.constraint(equalTo: tSwitch.leftAnchor, constant: -chat_cell_margin),
    ])

    NSLayoutConstraint.activate([
      subTitleLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
      subTitleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      subTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4.0),
    ])
  }
}
