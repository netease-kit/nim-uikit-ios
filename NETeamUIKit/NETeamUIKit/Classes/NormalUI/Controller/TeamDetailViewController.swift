
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit_coexist
import NECoreKit
import NIMSDK2
import UIKit

/// 群详情页 - 协同版
@objcMembers
open class TeamDetailViewController: NEBaseTeamDetailViewController {
  open func initNormal() {
    className = "TeamDetailViewController"
  }

  override public init(nim_team: V2NIM2Team) {
    super.init(nim_team: nim_team)
    initNormal()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func commonUI() {
    super.commonUI()
    tableView.estimatedRowHeight = 66
    headerView.setCornerRadius(30)
  }
}
