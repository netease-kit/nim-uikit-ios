//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonKit
import NECommonUIKit
import UIKit

@objcMembers
open class NEBaseTeamManagerListController: NEBaseViewController, UITableViewDelegate, UITableViewDataSource, TeamMemberCellDelegate, TeamManagerListViewModelDelegate {
  public var teamId: String?

  let viewmodel = TeamManagerListViewModel()

  /// 内容视图
  public lazy var contentTableView: UITableView = {
    let tableView = UITableView()
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .clear
    tableView.dataSource = self
    tableView.delegate = self
    tableView.separatorColor = .clear
    tableView.separatorStyle = .none
    tableView.sectionHeaderHeight = 12.0
    tableView
      .tableFooterView =
      UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 12))
    tableView.keyboardDismissMode = .onDrag

    if #available(iOS 11.0, *) {
      tableView.estimatedRowHeight = 0
      tableView.estimatedSectionHeaderHeight = 0
      tableView.estimatedSectionFooterHeight = 0
    }
    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }
    return tableView
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
    view.addSubview(contentTableView)
    NSLayoutConstraint.activate([
      contentTableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
      contentTableView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
      contentTableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      contentTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
    ])

    for (key, value) in cellClassDic {
      contentTableView.register(value, forCellReuseIdentifier: "\(key)")
    }
    navigationView.moreButton.isHidden = true
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
        if IMKitClient.instance.isMe(user.user?.accountId) {
          Router.shared.use(
            MeSettingRouter,
            parameters: ["nav": navigationController as Any],
            closure: nil
          )
        } else {
          if let uid = user.user?.accountId {
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

  open func didAddManagers(_ managers: [NETeamMemberInfoModel]) {
    if let tid = teamId {
      var uids = [String]()
      for member in managers {
        if let uid = member.nimUser?.user?.accountId {
          uids.append(uid)
        }
      }
      viewmodel.addTeamManager(tid, uids) { [weak self] error in
        if error != nil {
          self?.view.makeToast(localizable("failed_operation"))
        } else {
          self?.viewmodel.managers.insert(contentsOf: managers, at: 0)
          self?.sortAndReloadData()
        }
      }
    }
  }

  func didClickRemoveButton(_ model: NETeamMemberInfoModel?, _ index: Int) {
    print("did click remove button")
    weak var weakSelf = self
    // let content = String(format: localizable("confirm_delete_text"), model?.atNameInTeam() ?? "") + localizable("question_mark")
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }
    showAlert(title: localizable("remove_manager_title"), message: localizable("remove_manager_tip")) {
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        weakSelf?.showToast(commonLocalizable("network_error"))
        return
      }
      if let tid = weakSelf?.teamId, let uid = model?.nimUser?.user?.accountId {
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
    for model in viewmodel.managers {
      if let uid = model.nimUser?.user?.accountId {
        filters.insert(uid)
      }
    }
    return filters
  }

  open func sortAndReloadData() {
    // 数据源根据时间排序
    viewmodel.managers.sort { model1, model2 -> Bool in
      if let time1 = model1.teamMember?.joinTime, let time2 = model2.teamMember?.joinTime {
        return time2 > time1
      }
      return false
    }
    contentTableView.reloadData()
  }

  open func didNeedReloadData() {
    sortAndReloadData()
  }
}
