
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class FunTeamListViewController: NEBaseTeamListViewController {
  override open func commonUI() {
    super.commonUI()
    tableView.register(
      FunTeamTableViewCell.self,
      forCellReuseIdentifier: "\(NSStringFromClass(FunTeamTableViewCell.self))"
    )
    tableView.rowHeight = 72
    emptyView.setEmptyImage(name: "fun_user_empty")
  }

  override open func tableView(_ tableView: UITableView,
                               cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(NSStringFromClass(FunTeamTableViewCell.self))",
      for: indexPath
    ) as! FunTeamTableViewCell
    cell.setModel(viewModel.teamList[indexPath.row])
    return cell
  }
}
