// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunAIRobotController: NEBaseAIRobotController {
  override open func viewDidLoad() {
    super.viewDidLoad()
    // Fun 页面背景 #EDEDED，导航栏白色（Figma Group 1847 fill_EGVIBM #FFFFFF）
    view.backgroundColor = .funContactNavigationBackgroundColor
    navigationView.backgroundColor = .white
    robotTableView.register(FunAIRobotListCell.self, forCellReuseIdentifier: "\(FunAIRobotListCell.self)")
    robotEmptyView.setEmptyImage(name: "fun_user_empty")
  }

  override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(FunAIRobotListCell.self)",
      for: indexPath
    ) as? FunAIRobotListCell,
      indexPath.row < viewModel.datas.count {
      cell.configure(viewModel.datas[indexPath.row])
      cell.dividerLine.isHidden = isLastRobot(indexPath.row)
      return cell
    }
    return UITableViewCell()
  }

  override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    74.0 // Figma: Group1848 y:88 h:74, Group1849 y:162 h:74
  }
}
