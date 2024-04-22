
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import UIKit

@objcMembers
open class TeamDefaultIconCell: NEBaseTeamDefaultIconCell {
  override func setupUI() {
    super.setupUI()
    NSLayoutConstraint.activate([
      selectBackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      selectBackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      selectBackView.widthAnchor.constraint(equalToConstant: 48.0),
      selectBackView.heightAnchor.constraint(equalToConstant: 48.0),
    ])

    NSLayoutConstraint.activate([
      iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      iconImageView.heightAnchor.constraint(equalToConstant: 32),
      iconImageView.widthAnchor.constraint(equalToConstant: 32),
    ])
  }
}
