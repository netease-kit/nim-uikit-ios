
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class TeamSettingSwitchCell: NEBaseTeamSettingSwitchCell {
  override open func setupUI() {
    super.setupUI()
    tSwitch.onTintColor = NEConstant.hexRGB(0x337EFF)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 36),
      titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -84),
    ])

    NSLayoutConstraint.activate([
      tSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      tSwitch.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -36),
    ])
  }
}
