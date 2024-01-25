//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonUIKit
import UIKit

@objcMembers
open class NEBaseTeamManagerListController: NEBaseViewController, UITableViewDelegate, UITableViewDataSource, TeamMemberCellDelegate, TeamManagerListViewModelDelegate {
  public var teamId: String?

  let viewmodel = TeamManagerListViewModel()

  public lazy var contentTable: UITableView = {
    let table = UITableView()
    table.translatesAutoresizingMaskIntoConstraints = false
    table.backgroundColor = .clear
    table.dataSource = self
    table.delegate = self
    table.separatorColor = .clear
    table.separatorStyle = .none
    table.keyboardDismissMode = .onDrag
    table.sectionHeaderHeight = 12.0
    table
      .tableFooterView =
      UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 12))
    if #available(iOS 15.0, *) {
      table.sectionHeaderTopPadding = 0.0
    }
    return table
  }()

  public var cellClassDic = [Int: UITableViewCell.Type]() // key 值为 table section 值

  override open func viewDidLoad() {
    super.viewDidLoad()

    title = localizable("group_manager")

    viewmodel.teamId = teamId

    viewmodel.delegate = self

    if let tid = teamId {
      viewmodel.getCurrentMember(tid)
      viewmodel.getManagerDatas(tid) { [weak self] error in
        if let err = error {
          self?.view.makeToast(err.localizedDescription)
        } else {
          self?.sortAndReloadData()
        }
      }
    }
    view.addSubview(contentTable)
    NSLayoutConstraint.activate([
      contentTable.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
      contentTable.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
      contentTable.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      contentTable.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
    ])

    cellClassDic.forEach { (key: Int, value: UITableViewCell.Type) in
      contentTable.register(value, forCellReuseIdentifier: "\(key)")
    }
  }

  open func numberOfSections(in tableView: UITableView) -> Int {
    2
  }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return 1
    }
    return viewmodel.managers.count
  }

  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    UITableViewCell()
  }

  open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    0
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 1 {
      let model = viewmodel.managers[indexPath.row]
      if let user = model.nimUser {
        if IMKitClient.instance.isMySelf(user.userId) {
          Router.shared.use(
            MeSettingRouter,
            parameters: ["nav": navigationController as Any],
            closure: nil
          )
        } else {
          if let uid = user.userId {
            Router.shared.use(
              ContactUserInfoPageRouter,
              parameters: ["nav": navigationController as Any, "uid": uid],
              closure: nil
            )
          }
        }
      }
    }
  }

  open func didAddManagers(_ managers: [TeamMemberInfoModel]) {
    if let tid = teamId {
      var uids = [String]()
      managers.forEach { member in
        if let uid = member.nimUser?.userId {
          uids.append(uid)
        }
      }
      viewmodel.addTeamManager(tid, uids) { [weak self] error in
        if let err = error {
          self?.view.makeToast(err.localizedDescription)
        } else {
          self?.viewmodel.managers.insert(contentsOf: managers, at: 0)
          self?.sortAndReloadData()
        }
      }
    }
  }

  func didClickRemoveButton(_ model: TeamMemberInfoModel?, _ index: Int) {
    print("did click remove button")
    weak var weakSelf = self
    // let content = String(format: localizable("confirm_delete_text"), model?.atNameInTeam() ?? "") + localizable("question_mark")
    showAlert(title: localizable("remove_manager_title"), message: localizable("remove_manager_tip")) {
      if let tid = weakSelf?.teamId, let uid = model?.nimUser?.userId {
        weakSelf?.viewmodel.removeTeamManager(tid, [uid]) { error in
          if let err = error {
            weakSelf?.view.makeToast(err.localizedDescription)
          } else {
            if weakSelf?.viewmodel.managers.count ?? 0 > index {
              weakSelf?.viewmodel.managers.remove(at: index)
              weakSelf?.sortAndReloadData()
            }
          }
        }
      }
    }
  }

  open func getFilters() -> Set<String> {
    var filters = Set<String>()
    viewmodel.managers.forEach { model in
      if let uid = model.nimUser?.userId {
        filters.insert(uid)
      }
    }
    return filters
  }

  open func sortAndReloadData() {
    // 数据源根据时间排序
    viewmodel.managers.sort { model1, model2 -> Bool in
      if let time1 = model1.teamMember?.createTime, let time2 = model2.teamMember?.createTime {
        return time2 > time1
      }
      return false
    }
    contentTable.reloadData()
  }

  open func didNeedReloadData() {
    sortAndReloadData()
  }
}
