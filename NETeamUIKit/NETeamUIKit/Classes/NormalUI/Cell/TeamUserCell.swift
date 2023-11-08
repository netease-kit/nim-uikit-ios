
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECoreIMKit
import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class TeamUserCell: NEBaseTeamUserCell {
  override func setupUI() {
    super.setupUI()
    userHeader.layer.cornerRadius = 16.0
    NSLayoutConstraint.activate([
      userHeader.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      userHeader.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      userHeader.widthAnchor.constraint(equalToConstant: 32.0),
      userHeader.heightAnchor.constraint(equalToConstant: 32.0),
    ])
  }
}
