
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class TeamUserCell: NEBaseTeamUserCell {
  override func setupUI() {
    super.setupUI()
    userHeaderView.layer.cornerRadius = 16.0
    NSLayoutConstraint.activate([
      userHeaderView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      userHeaderView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      userHeaderView.widthAnchor.constraint(equalToConstant: 32.0),
      userHeaderView.heightAnchor.constraint(equalToConstant: 32.0),
    ])
  }
}
