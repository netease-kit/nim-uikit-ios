// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECommonKit
import NIMSDK
import NECoreIMKit
import NECoreKit

@objcMembers
open class FunTeamUserCell: NEBaseTeamUserCell {
  override func setupUI() {
    super.setupUI()
    userHeader.layer.cornerRadius = 4
    NSLayoutConstraint.activate([
      userHeader.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      userHeader.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      userHeader.widthAnchor.constraint(equalToConstant: 36.0),
      userHeader.heightAnchor.constraint(equalToConstant: 36.0),
    ])
  }
}
