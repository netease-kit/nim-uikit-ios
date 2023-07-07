
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class TeamArrowSettingCell: NEBaseTeamArrowSettingCell {
  override open func setupUI() {
    super.setupUI()
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 36),
      titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -84),
    ])

    NSLayoutConstraint.activate([
      arrow.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      arrow.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -36),
    ])
  }
}
