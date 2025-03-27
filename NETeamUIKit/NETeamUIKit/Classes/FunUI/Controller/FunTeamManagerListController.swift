//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import UIKit

@objcMembers
open class FunTeamManagerListController: NEBaseTeamManagerListController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    // key 值 为 tableview section 对应的值
    cellClassDic = [0: FunTeamArrowSettingCell.self, 1: FunTeamManagerMemberCell.self]
  }

  public lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(imageName: "fun_user_empty", content: localizable("no_manager_member"), frame: CGRect.zero)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isUserInteractionEnabled = false
    view.isHidden = true
    return view
  }()

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
      emptyView.widthAnchor.constraint(equalToConstant: 122),
      emptyView.heightAnchor.constraint(equalToConstant: 91),
    ])
    sortAndReloadData()
  }

  override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 0 {
      let cell = tableView.dequeueReusableCell(withIdentifier: "\(indexPath.section)", for: indexPath) as! FunTeamArrowSettingCell
      cell.titleLabel.text = localizable("add_manager")
      return cell
    }
    let cell = tableView.dequeueReusableCell(withIdentifier: "\(indexPath.section)", for: indexPath) as! FunTeamManagerMemberCell
    cell.delegate = self
    cell.index = indexPath.row
    cell.configure(viewmodel.managers[indexPath.row])
    if let type = viewmodel.currentMember?.memberRole, type == .TEAM_MEMBER_ROLE_MANAGER {
      cell.removeButton.isHidden = true
      cell.removeLabel.isHidden = true
    }
    return cell
  }

  override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == 0 {
      return 46
    } else if indexPath.section == 1 {
      return 64
    }
    return 0
  }

  override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 0 {
      let selectController = FunTeamMemberSelectController()
      selectController.teamId = teamId

      selectController.selectMemberBlock = { [weak self] datas in
        self?.didAddManagers(datas)
      }
      navigationController?.pushViewController(selectController, animated: true)
    } else if indexPath.section == 1 {
      super.tableView(tableView, didSelectRowAt: indexPath)
    }
  }

  override open func sortAndReloadData() {
    super.sortAndReloadData()
    emptyView.isHidden = viewmodel.managers.count > 0
  }
}
