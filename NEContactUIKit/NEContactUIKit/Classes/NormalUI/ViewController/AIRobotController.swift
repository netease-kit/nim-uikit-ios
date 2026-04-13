// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class AIRobotController: NEBaseAIRobotController {
  override open func viewDidLoad() {
    super.viewDidLoad()
    navigationView.backgroundColor = .white
    navigationController?.navigationBar.backgroundColor = .white
    robotTableView.register(AIRobotListCell.self, forCellReuseIdentifier: "\(AIRobotListCell.self)")
  }

  override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(AIRobotListCell.self)",
      for: indexPath
    ) as? AIRobotListCell,
      indexPath.row < viewModel.datas.count {
      cell.configure(viewModel.datas[indexPath.row])
      cell.dividerLine.isHidden = isLastRobot(indexPath.row)
      return cell
    }
    return UITableViewCell()
  }

  override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    60.0 // Figma: 第1行y:117, 第2行y:177, 差值60
  }
}
