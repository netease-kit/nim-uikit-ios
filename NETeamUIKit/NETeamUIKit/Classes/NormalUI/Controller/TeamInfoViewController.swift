
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class TeamInfoViewController: NEBaseTeamInfoViewController {
  override public init(team: NIMTeam?) {
    super.init(team: team)
    cellClassDic = [
      SettingCellType.SettingArrowCell.rawValue: TeamArrowSettingCell.self,
      SettingCellType.SettingHeaderCell.rawValue: TeamSettingHeaderCell.self,
    ]
    view.backgroundColor = .ne_lightBackgroundColor
    navigationView.backgroundColor = .ne_lightBackgroundColor
    navigationController?.navigationBar.backgroundColor = .ne_lightBackgroundColor
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func setupUI() {
    super.setupUI()
    view.backgroundColor = .ne_lightBackgroundColor
  }

  // MARK: UITableViewDelegate, UITableViewDataSource

  override open func tableView(_ tableView: UITableView,
                               cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = viewmodel.cellDatas[indexPath.row]
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(model.type)",
      for: indexPath
    ) as? NEBaseTeamSettingCell {
      cell.configure(model)
      return cell
    }
    return UITableViewCell()
  }

  override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let model = viewmodel.cellDatas[indexPath.row]
    if indexPath.row == 0 {
      let avatar = TeamAvatarViewController()
      avatar.team = team
      weak var weakSelf = self
      avatar.block = {
        if let t = weakSelf?.team {
          weakSelf?.viewmodel.getData(t)
          weakSelf?.contentTable.reloadData()
        }
      }
      navigationController?.pushViewController(avatar, animated: true)

    } else if indexPath.row == 1 {
      let nameController = TeamNameViewController()
      nameController.team = team
      nameController.title = model.cellName
      navigationController?.pushViewController(nameController, animated: true)
    } else if indexPath.row == 2 {
      let intr = TeamIntroduceViewController()
      intr.team = team
      intr.title = model.cellName
      navigationController?.pushViewController(intr, animated: true)
    }
  }

  override open func tableView(_ tableView: UITableView,
                               heightForRowAt indexPath: IndexPath) -> CGFloat {
    let model = viewmodel.cellDatas[indexPath.row]
    return model.rowHeight
  }
}
