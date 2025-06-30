
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import UIKit

@objcMembers
open class TeamSettingSubtitleSwitchCell: NEBaseTeamSettingSubtitleSwitchCell {
  override open func setupUI() {
    super.setupUI()
    tSwitch.onTintColor = NEConstant.hexRGB(0x337EFF)
    NSLayoutConstraint.activate([
      //      tSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      tSwitch.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      tSwitch.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -36),
    ])

    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 36),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
      titleLabel.rightAnchor.constraint(equalTo: tSwitch.leftAnchor, constant: -chat_cell_margin),
    ])

    NSLayoutConstraint.activate([
      subTitleLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
      subTitleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      subTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6.0),
    ])
  }
}
