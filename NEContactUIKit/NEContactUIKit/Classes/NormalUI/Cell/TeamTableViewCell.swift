// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIMKit
import UIKit

@objcMembers
open class TeamTableViewCell: NEBaseTeamTableViewCell {
  override func commonUI() {
    super.commonUI()
    avatarImage.layer.cornerRadius = 21

    titleLabel.font = UIFont.systemFont(ofSize: 16)
    titleLabel.textColor = UIColor(
      red: 51 / 255.0,
      green: 51 / 255.0,
      blue: 51 / 255.0,
      alpha: 1.0
    )
  }
}
