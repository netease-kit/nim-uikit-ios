// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class FunTeamInfoViewController: NEBaseTeamInfoViewController {
  override init(team: NIMTeam?) {
    super.init(team: team)
    cellClassDic = [
      SettingCellType.SettingArrowCell.rawValue: FunTeamArrowSettingCell.self,
      SettingCellType.SettingHeaderCell.rawValue: FunTeamSettingHeaderCell.self,
    ]
    view.backgroundColor = .funTeamBackgroundColor
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    viewmodel.cellDatas.forEach { cellModel in
      cellModel.cornerType = .none
      if cellModel.type == SettingCellType.SettingArrowCell.rawValue {
        cellModel.rowHeight = 56
      }
    }
  }

  override open func setupUI() {
    super.setupUI()
    navigationController?.navigationBar.backgroundColor = .white
    navigationView.backgroundColor = .white
    navigationView.titleBarBottomLine.isHidden = false
    view.backgroundColor = .funTeamBackgroundColor
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
      let avatar = FunTeamAvatarViewController()
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
      let nameController = FunTeamNameViewController()
      nameController.team = team
      nameController.title = model.cellName
      navigationController?.pushViewController(nameController, animated: true)
    } else if indexPath.row == 2 {
      let intr = FunTeamIntroduceViewController()
      intr.team = team
      intr.title = model.cellName
      navigationController?.pushViewController(intr, animated: true)
    }
  }
}
