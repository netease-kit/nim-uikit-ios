// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class FunTeamUserCell: NEBaseTeamUserCell {
  override func setupUI() {
    super.setupUI()
    userHeaderView.layer.cornerRadius = 4
    NSLayoutConstraint.activate([
      userHeaderView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      userHeaderView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      userHeaderView.widthAnchor.constraint(equalToConstant: 36.0),
      userHeaderView.heightAnchor.constraint(equalToConstant: 36.0),
    ])
  }
}
