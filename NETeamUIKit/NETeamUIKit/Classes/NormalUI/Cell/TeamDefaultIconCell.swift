
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
      selectBack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      selectBack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      selectBack.widthAnchor.constraint(equalToConstant: 48.0),
      selectBack.heightAnchor.constraint(equalToConstant: 48.0),
    ])

    NSLayoutConstraint.activate([
      iconImage.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      iconImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      iconImage.heightAnchor.constraint(equalToConstant: 32),
      iconImage.widthAnchor.constraint(equalToConstant: 32),
    ])
  }
}
