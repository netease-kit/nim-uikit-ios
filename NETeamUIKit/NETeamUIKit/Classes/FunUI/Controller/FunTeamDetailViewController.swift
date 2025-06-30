// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import NECoreKit
import NIMSDK
import UIKit

/// 群详情页 - 通用版
@objcMembers
open class FunTeamDetailViewController: NEBaseTeamDetailViewController {
  open func initFun() {
    className = "FunTeamDetailViewController"
  }

  override public init(nim_team: V2NIMTeam) {
    super.init(nim_team: nim_team)
    initFun()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func commonUI() {
    super.commonUI()
    tableView.estimatedRowHeight = 66
  }

  override open func tableView(_ tableView: UITableView,
                               cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let item = data[indexPath.section][indexPath.row]
    let cell = super.tableView(tableView, cellForRowAt: indexPath)
    if let c = cell as? TeamCenterTextCell,
       item.title == commonLocalizable("chat") ||
       item.title == commonLocalizable("join_team") {
      c.titleLabel.textColor = .funTeamDetailTitleTextColor
      return c
    }
    return cell
  }
}
