//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIMKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseTeamManageController: NEBaseViewController, UITableViewDelegate, UITableViewDataSource, TeamManageViewModelDelegate {
  public let viewmodel = TeamManageViewModel()

  public var managerUsers = [TeamMemberInfoModel]()

  public var cellClassDic = [Int: NEBaseTeamSettingCell.Type]()

  public lazy var contentTable: UITableView = {
    let table = UITableView()
    table.translatesAutoresizingMaskIntoConstraints = false
    table.backgroundColor = .clear
    table.dataSource = self
    table.delegate = self
    table.separatorColor = .clear
    table.separatorStyle = .none
    table.sectionHeaderHeight = 12.0
    table
      .tableFooterView =
      UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 12))
    if #available(iOS 15.0, *) {
      table.sectionHeaderTopPadding = 0.0
    }
    return table
  }()

  override open func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    title = localizable("manage_team")
    viewmodel.managerUsers = managerUsers
    viewmodel.delegate = self
    view.backgroundColor = .ne_lightBackgroundColor
    view.addSubview(contentTable)

    NSLayoutConstraint.activate([
      contentTable.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentTable.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentTable.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      contentTable.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    cellClassDic.forEach { (key: Int, value: NEBaseTeamSettingCell.Type) in
      contentTable.register(value, forCellReuseIdentifier: "\(key)")
    }
    if let tid = viewmodel.teamInfoModel?.team?.teamId {
      viewmodel.getTeamInfo(tid) { [weak self] error in
        self?.reloadSectionData()
        self?.contentTable.reloadData()
      }
    }
  }

  open func reloadSectionData() {}

  // MARK: UITableViewDataSource, UITableViewDelegate

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if viewmodel.sectionData.count > section {
      let model = viewmodel.sectionData[section]
      return model.cellModels.count
    }
    return 0
  }

  open func numberOfSections(in tableView: UITableView) -> Int {
    viewmodel.sectionData.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = viewmodel.sectionData[indexPath.section].cellModels[indexPath.row]
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(model.type)",
      for: indexPath
    ) as? NEBaseTeamSettingCell {
      cell.configure(model)
      return cell
    }
    return UITableViewCell()
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let model = viewmodel.sectionData[indexPath.section].cellModels[indexPath.row]
    if let block = model.cellClick {
      block()
    }
  }

  open func tableView(_ tableView: UITableView,
                      heightForRowAt indexPath: IndexPath) -> CGFloat {
    let model = viewmodel.sectionData[indexPath.section].cellModels[indexPath.row]
    return model.rowHeight
  }

  open func tableView(_ tableView: UITableView,
                      heightForHeaderInSection section: Int) -> CGFloat {
    if viewmodel.sectionData.count > section {
      let model = viewmodel.sectionData[section]
      if model.cellModels.count > 0 {
        return 12.0
      }
    }
    return 0
  }

  open func tableView(_ tableView: UITableView,
                      viewForHeaderInSection section: Int) -> UIView? {
    let header = UIView()
    header.backgroundColor = .ne_lightBackgroundColor
    return header
  }

  open func tableView(_ tableView: UITableView,
                      heightForFooterInSection section: Int) -> CGFloat {
    if section == viewmodel.sectionData.count - 1 {
      return 12.0
    }
    return 0
  }

  open func getFooterView() -> UIView? {
    nil
  }

  open func transferOwner() {}

  func updateTeamInfoAllAction(_ model: SettingCellModel) {
    weak var weakSelf = self
    view.makeToastActivity(.center)
    viewmodel.repo
      .updateTeamInfoPrivilege(.all, viewmodel.teamInfoModel?.team?.teamId ?? "") { error in
        NELog.infoLog(
          ModuleName + " " + self.className(),
          desc: "CALLBACK updateTeamInfoPrivilege " + (error?.localizedDescription ?? "no error")
        )
        weakSelf?.view.hideToastActivity()
        if let err = error as? NSError {
          if err.code == noNetworkCode {
            weakSelf?.showToast(commonLocalizable("network_error"))
          } else if err.code == noPermissionCode {
            weakSelf?.showToast(localizable("no_permission_tip"))
          } else {
            weakSelf?.showToast(localizable("failed_operation"))
          }
        } else {
          weakSelf?.viewmodel.teamInfoModel?.team?.updateInfoMode = .all
          model.subTitle = localizable("team_all")
          weakSelf?.contentTable.reloadData()
        }
      }
  }

  open func didUpdateTeamInfoClick(_ model: SettingCellModel) {
    weak var weakSelf = self

    let actionSheetController = UIAlertController(
      title: nil,
      message: nil,
      preferredStyle: .actionSheet
    )

    let cancelActionButton = UIAlertAction(title: localizable("cancel"), style: .cancel) { _ in
      print("Cancel")
    }
    cancelActionButton.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    actionSheetController.addAction(cancelActionButton)

    let all = UIAlertAction(title: localizable("team_all"), style: .default) { _ in
      weakSelf?.updateTeamInfoAllAction(model)
    }
    all.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    all.accessibilityIdentifier = "id.teamAllMember"
    actionSheetController.addAction(all)

    let manager = UIAlertAction(title: localizable("team_owner_and_manager"), style: .default) { _ in
      weakSelf?.updateTeamInfoOwnerAction(model)
    }
    manager.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    manager.accessibilityIdentifier = "id.teamOwner"
    actionSheetController.addAction(manager)

    actionSheetController.fixIpadAction()

    navigationController?.present(actionSheetController, animated: true, completion: nil)
  }

  func updateTeamInfoOwnerAction(_ model: SettingCellModel) {
    weak var weakSelf = self
    view.makeToastActivity(.center)
    viewmodel.repo
      .updateTeamInfoPrivilege(.manager, viewmodel.teamInfoModel?.team?.teamId ?? "") { error in
        NELog.infoLog(
          ModuleName + " " + self.className(),
          desc: "CALLBACK updateTeamInfoPrivilege " + (error?.localizedDescription ?? "no error")
        )
        weakSelf?.view.hideToastActivity()
        if let err = error as? NSError {
          if err.code == noNetworkCode {
            weakSelf?.showToast(commonLocalizable("network_error"))
          } else if err.code == noPermissionCode {
            weakSelf?.showToast(localizable("no_permission_tip"))
          } else {
            weakSelf?.showToast(localizable("failed_operation"))
          }
        } else {
          weakSelf?.viewmodel.teamInfoModel?.team?.updateInfoMode = .manager
          model.subTitle = localizable("team_owner_and_manager")
          weakSelf?.contentTable.reloadData()
        }
      }
  }

  func updateInviteModeOwnerAction(_ model: SettingCellModel) {
    weak var weakSelf = self
    view.makeToastActivity(.center)
    viewmodel.repo.updateInviteMode(.manager, viewmodel.teamInfoModel?.team?.teamId ?? "") { error in
      NELog.infoLog(
        ModuleName + " " + self.className(),
        desc: "CALLBACK updateInviteMode " + (error?.localizedDescription ?? "no error")
      )
      weakSelf?.view.hideToastActivity()
      if let err = error as? NSError {
        if err.code == noNetworkCode {
          weakSelf?.showToast(commonLocalizable("network_error"))
        } else if err.code == noPermissionCode {
          weakSelf?.showToast(localizable("no_permission_tip"))
        } else {
          weakSelf?.showToast(localizable("failed_operation"))
        }
      } else {
        weakSelf?.viewmodel.teamInfoModel?.team?.inviteMode = .manager
        model.subTitle = localizable("team_owner_and_manager")
        weakSelf?.contentTable.reloadData()
      }
    }
  }

  func updateInviteModeAllAction(_ model: SettingCellModel) {
    weak var weakSelf = self
    view.makeToastActivity(.center)
    viewmodel.repo.updateInviteMode(.all, viewmodel.teamInfoModel?.team?.teamId ?? "") { error in
      NELog.infoLog(
        ModuleName + " " + self.className(),
        desc: "CALLBACK updateInviteMode " + (error?.localizedDescription ?? "no error")
      )
      weakSelf?.view.hideToastActivity()
      if let err = error as? NSError {
        if err.code == noNetworkCode {
          weakSelf?.showToast(commonLocalizable("network_error"))
        } else if err.code == noPermissionCode {
          weakSelf?.showToast(localizable("no_permission_tip"))
        } else {
          weakSelf?.showToast(localizable("failed_operation"))
        }
      } else {
        weakSelf?.viewmodel.teamInfoModel?.team?.inviteMode = .all
        model.subTitle = localizable("team_all")
        weakSelf?.contentTable.reloadData()
      }
    }
  }

  open func didChangeInviteModeClick(_ model: SettingCellModel) {
    weak var weakSelf = self

    let actionSheetController = UIAlertController(
      title: nil,
      message: nil,
      preferredStyle: .actionSheet
    )

    let cancelActionButton = UIAlertAction(title: localizable("cancel"), style: .cancel) { _ in
      print("Cancel")
    }
    cancelActionButton.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    actionSheetController.addAction(cancelActionButton)

    let allActionButton = UIAlertAction(title: localizable("team_all"), style: .default) { _ in
      weakSelf?.updateInviteModeAllAction(model)
    }

    allActionButton.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    allActionButton.accessibilityIdentifier = "id.teamAllMember"
    actionSheetController.addAction(allActionButton)

    let ownerActionButton = UIAlertAction(title: localizable("team_owner_and_manager"), style: .default) { _ in
      weakSelf?.updateInviteModeOwnerAction(model)
    }
    ownerActionButton.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    ownerActionButton.accessibilityIdentifier = "id.teamOwner"
    actionSheetController.addAction(ownerActionButton)

    actionSheetController.fixIpadAction()
    navigationController?.present(actionSheetController, animated: true, completion: nil)
  }

  open func didAtPermissionClick(_ model: SettingCellModel) {
    weak var weakSelf = self

    let actionSheetController = UIAlertController(
      title: nil,
      message: nil,
      preferredStyle: .actionSheet
    )

    let cancelActionButton = UIAlertAction(title: localizable("cancel"), style: .cancel) { _ in
      print("Cancel")
    }
    cancelActionButton.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    actionSheetController.addAction(cancelActionButton)

    let all = UIAlertAction(title: localizable("team_all"), style: .default) { _ in
      weakSelf?.viewmodel.updateTeamAtPermission(false) { error in
        if let err = error as? NSError {
          if err.code == noNetworkCode {
            weakSelf?.showToast(commonLocalizable("network_error"))
          } else if err.code == noPermissionCode {
            weakSelf?.showToast(localizable("no_permission_tip"))
          } else {
            weakSelf?.showToast(localizable("failed_operation"))
          }
        } else {
          weakSelf?.viewmodel.sendTipNoti(false) { error in
          }
          model.subTitle = localizable("team_all")
          weakSelf?.contentTable.reloadData()
        }
      }
    }
    all.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    all.accessibilityIdentifier = "id.teamAllMember"
    actionSheetController.addAction(all)
    actionSheetController.fixIpadAction()

    let manager = UIAlertAction(title: localizable("team_owner_and_manager"), style: .default) { _ in
      weakSelf?.viewmodel.updateTeamAtPermission(true) { error in
        if let err = error as? NSError {
          if err.code == noNetworkCode {
            weakSelf?.showToast(commonLocalizable("network_error"))
          } else if err.code == noPermissionCode {
            weakSelf?.showToast(localizable("no_permission_tip"))
          } else {
            weakSelf?.showToast(localizable("failed_operation"))
          }
        } else {
          weakSelf?.viewmodel.sendTipNoti(true) { error in
          }
          model.subTitle = localizable("team_owner_and_manager")
          weakSelf?.contentTable.reloadData()
        }
      }
    }
    manager.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    manager.accessibilityIdentifier = "id.teamOwner"
    actionSheetController.addAction(manager)

    navigationController?.present(actionSheetController, animated: true, completion: nil)
  }

  open func didManagerClick() {}

  open func didRefreshData() {
    reloadSectionData()
    contentTable.reloadData()
  }

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       // Get the new view controller using segue.destination.
       // Pass the selected object to the new view controller.
   }
   */
}
