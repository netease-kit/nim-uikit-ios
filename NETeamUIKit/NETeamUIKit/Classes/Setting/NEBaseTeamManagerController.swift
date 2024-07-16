//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseTeamManagerController: NEBaseViewController, UITableViewDelegate, UITableViewDataSource, TeamManagerViewModelDelegate {
  public let viewModel = TeamManagerViewModel()

  /// UI样式注册(用户可以自定义)
  public var cellClassDic = [Int: NEBaseTeamSettingCell.Type]()

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

  override open func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    title = localizable("manage_team")
    viewModel.delegate = self
    view.backgroundColor = .ne_lightBackgroundColor
    view.addSubview(contentTableView)

    if let teamId = viewModel.teamInfoModel?.team?.teamId {
      viewModel.getCurrentUserTeamMember(IMKitClient.instance.account(), teamId) { member, error in
      }
    }

    NSLayoutConstraint.activate([
      contentTableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentTableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentTableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      contentTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    for (key, value) in cellClassDic {
      contentTableView.register(value, forCellReuseIdentifier: "\(key)")
    }
    navigationView.moreButton.isHidden = true
  }

  /// 页面出现回到(系统类生命周期函数)
  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if let tid = viewModel.teamInfoModel?.team?.teamId {
      viewModel.getTeamWithMembers(tid) { [weak self] error in
        self?.reloadSectionData()
        self?.contentTableView.reloadData()
      }
    }
  }

  /// 从新加载数据回调，在子类中实现
  open func reloadSectionData() {}

  // MARK: UITableViewDataSource, UITableViewDelegate

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if viewModel.sectionData.count > section {
      let model = viewModel.sectionData[section]
      return model.cellModels.count
    }
    return 0
  }

  open func numberOfSections(in tableView: UITableView) -> Int {
    viewModel.sectionData.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = viewModel.sectionData[indexPath.section].cellModels[indexPath.row]
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
    let model = viewModel.sectionData[indexPath.section].cellModels[indexPath.row]
    if let block = model.cellClick {
      block()
    }
  }

  open func tableView(_ tableView: UITableView,
                      heightForRowAt indexPath: IndexPath) -> CGFloat {
    let model = viewModel.sectionData[indexPath.section].cellModels[indexPath.row]
    return model.rowHeight
  }

  open func tableView(_ tableView: UITableView,
                      heightForHeaderInSection section: Int) -> CGFloat {
    if viewModel.sectionData.count > section {
      let model = viewModel.sectionData[section]
      if model.cellModels.count > 0 {
        return 12.0
      }
    }
    return 0
  }

  open func tableView(_ tableView: UITableView,
                      viewForHeaderInSection section: Int) -> UIView? {
    let headerView = UIView()
    headerView.backgroundColor = .ne_lightBackgroundColor
    return headerView
  }

  open func tableView(_ tableView: UITableView,
                      heightForFooterInSection section: Int) -> CGFloat {
    if section == viewModel.sectionData.count - 1 {
      return 12.0
    }
    return 0
  }

  /// 更新编辑群信息权限为任意群成员可以发at消息
  /// - Parameter model: 数据模型
  func updateEditTeamInfoPermissionToEveryone(_ model: SettingCellModel) {
    weak var weakSelf = self
    view.makeToastActivity(.center)
    viewModel.updateTeamInfoPrivilege(weakSelf?.viewModel.teamInfoModel?.team?.teamId ?? "", .TEAM_UPDATE_INFO_MODE_ALL) { error, team in
      NEALog.infoLog(
        ModuleName + " " + self.className(),
        desc: "CALLBACK updateTeamInfoPrivilege " + (error?.localizedDescription ?? "no error")
      )
      weakSelf?.view.hideToastActivity()
      if let err = error {
        if err.code == protocolSendFailed {
          weakSelf?.showToast(commonLocalizable("network_error"))
        } else if err.code == noPermissionCode {
          weakSelf?.showToast(localizable("no_permission_tip"))
        } else {
          weakSelf?.showToast(localizable("failed_operation"))
        }
      } else {
        weakSelf?.viewModel.teamInfoModel?.team = team
        model.subTitle = localizable("team_all")
        weakSelf?.contentTableView.reloadData()
      }
    }
  }

  /// 更新编辑群信权限为管理员可发送权限
  /// - Parameter model: 数据模型
  func updateEditTeamInfoPermissionToManager(_ model: SettingCellModel) {
    weak var weakSelf = self
    view.makeToastActivity(.center)
    viewModel.updateTeamInfoPrivilege(viewModel.teamInfoModel?.team?.teamId ?? "", .TEAM_UPDATE_INFO_MODE_MANAGER) { error, team in
      NEALog.infoLog(
        ModuleName + " " + self.className(),
        desc: "CALLBACK updateTeamInfoPrivilege " + (error?.localizedDescription ?? "no error")
      )
      weakSelf?.view.hideToastActivity()
      if let err = error {
        if err.code == protocolSendFailed {
          weakSelf?.showToast(commonLocalizable("network_error"))
        } else if err.code == noPermissionCode {
          weakSelf?.showToast(localizable("no_permission_tip"))
        } else {
          weakSelf?.showToast(localizable("failed_operation"))
        }
      } else {
        weakSelf?.viewModel.teamInfoModel?.team = team
        model.subTitle = localizable("team_owner_and_manager")
        weakSelf?.contentTableView.reloadData()
      }
    }
  }

  /// 更新邀请模式为管理员可邀请
  /// - Parameter model: 数据模型
  func updateInvitePermissionToManager(_ model: SettingCellModel) {
    weak var weakSelf = self
    view.makeToastActivity(.center)
    viewModel.updateInviteMode(viewModel.teamInfoModel?.team?.teamId ?? "", .TEAM_INVITE_MODE_MANAGER) { error, team in
      NEALog.infoLog(
        ModuleName + " " + self.className(),
        desc: "CALLBACK updateInviteMode " + (error?.localizedDescription ?? "no error")
      )
      weakSelf?.view.hideToastActivity()
      if let err = error {
        if err.code == protocolSendFailed {
          weakSelf?.showToast(commonLocalizable("network_error"))
        } else if err.code == noPermissionCode {
          weakSelf?.showToast(localizable("no_permission_tip"))
        } else {
          weakSelf?.showToast(localizable("failed_operation"))
        }
      } else {
        weakSelf?.viewModel.teamInfoModel?.team = team
        model.subTitle = localizable("team_owner_and_manager")
        weakSelf?.contentTableView.reloadData()
      }
    }
  }

  /// 更新邀请人权限为所有人
  /// - Parameter model: 数据模型
  func updateInvitePermissionToEveryone(_ model: SettingCellModel) {
    if viewModel.teamMember?.memberRole == .TEAM_MEMBER_ROLE_NORMAL {
      showToast(localizable("failed_operation"))
      return
    }
    weak var weakSelf = self
    view.makeToastActivity(.center)
    viewModel.updateInviteMode(viewModel.teamInfoModel?.team?.teamId ?? "", .TEAM_INVITE_MODE_ALL) { error, team in
      NEALog.infoLog(
        ModuleName + " " + self.className(),
        desc: "CALLBACK updateInviteMode " + (error?.localizedDescription ?? "no error")
      )
      weakSelf?.view.hideToastActivity()
      if let err = error {
        if err.code == protocolSendFailed {
          weakSelf?.showToast(commonLocalizable("network_error"))
        } else if err.code == noPermissionCode {
          weakSelf?.showToast(localizable("no_permission_tip"))
        } else {
          weakSelf?.showToast(localizable("failed_operation"))
        }
      } else {
        weakSelf?.viewModel.teamInfoModel?.team = team
        model.subTitle = localizable("team_all")
        weakSelf?.contentTableView.reloadData()
      }
    }
  }

  /// 点击修改群信息权限回调
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

    let allAction = UIAlertAction(title: localizable("team_all"), style: .default) { [weak self] _ in
      if self?.viewModel.teamMember?.memberRole != .TEAM_MEMBER_ROLE_OWNER, self?.viewModel.teamMember?.memberRole != .TEAM_MEMBER_ROLE_MANAGER {
        self?.showToast(localizable("no_permission_tip"))
        return
      }
      weakSelf?.updateEditTeamInfoPermissionToEveryone(model)
    }
    allAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    allAction.accessibilityIdentifier = "id.teamAllMember"
    actionSheetController.addAction(allAction)

    let managerAction = UIAlertAction(title: localizable("team_owner_and_manager"), style: .default) { [weak self] _ in
      if self?.viewModel.teamMember?.memberRole != .TEAM_MEMBER_ROLE_OWNER, self?.viewModel.teamMember?.memberRole != .TEAM_MEMBER_ROLE_MANAGER {
        self?.showToast(localizable("no_permission_tip"))
        return
      }
      weakSelf?.updateEditTeamInfoPermissionToManager(model)
    }
    managerAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    managerAction.accessibilityIdentifier = "id.teamOwner"
    actionSheetController.addAction(managerAction)

    actionSheetController.fixIpadAction()

    navigationController?.present(actionSheetController, animated: true, completion: nil)
  }

  /// 点击修改邀请权限回调
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

    let allAction = UIAlertAction(title: localizable("team_all"), style: .default) { [weak self] _ in
      if self?.viewModel.teamMember?.memberRole != .TEAM_MEMBER_ROLE_OWNER, self?.viewModel.teamMember?.memberRole != .TEAM_MEMBER_ROLE_MANAGER {
        self?.showToast(localizable("no_permission_tip"))
        return
      }
      weakSelf?.updateInvitePermissionToEveryone(model)
    }

    allAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    allAction.accessibilityIdentifier = "id.teamAllMember"
    actionSheetController.addAction(allAction)

    let managerAction = UIAlertAction(title: localizable("team_owner_and_manager"), style: .default) { [weak self] _ in
      if self?.viewModel.teamMember?.memberRole != .TEAM_MEMBER_ROLE_OWNER, self?.viewModel.teamMember?.memberRole != .TEAM_MEMBER_ROLE_MANAGER {
        self?.showToast(localizable("no_permission_tip"))
        return
      }
      weakSelf?.updateInvitePermissionToManager(model)
    }
    managerAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    managerAction.accessibilityIdentifier = "id.teamOwner"
    actionSheetController.addAction(managerAction)

    actionSheetController.fixIpadAction()
    navigationController?.present(actionSheetController, animated: true, completion: nil)
  }

  /// 点击修改at权限回调
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

    let allAction = UIAlertAction(title: localizable("team_all"), style: .default) { [weak self] _ in

      if self?.viewModel.teamMember?.memberRole != .TEAM_MEMBER_ROLE_OWNER, self?.viewModel.teamMember?.memberRole != .TEAM_MEMBER_ROLE_MANAGER {
        self?.showToast(localizable("no_permission_tip"))
        return
      }
      weakSelf?.viewModel.updateTeamAtAllPermission(false) { error in
        if let err = error as? NSError {
          if err.code == protocolSendFailed {
            weakSelf?.showToast(commonLocalizable("network_error"))
          } else if err.code == noPermissionCode {
            weakSelf?.showToast(localizable("no_permission_tip"))
          } else {
            weakSelf?.showToast(localizable("failed_operation"))
          }
        } else {
          model.subTitle = localizable("team_all")
          weakSelf?.contentTableView.reloadData()
        }
      }
    }
    allAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    allAction.accessibilityIdentifier = "id.teamAllMember"
    actionSheetController.addAction(allAction)
    actionSheetController.fixIpadAction()

    let managerAction = UIAlertAction(title: localizable("team_owner_and_manager"), style: .default) { [weak self] _ in
      if self?.viewModel.teamMember?.memberRole != .TEAM_MEMBER_ROLE_OWNER, self?.viewModel.teamMember?.memberRole != .TEAM_MEMBER_ROLE_MANAGER {
        self?.showToast(localizable("no_permission_tip"))
        return
      }
      weakSelf?.viewModel.updateTeamAtAllPermission(true) { error in
        if let err = error as? NSError {
          if err.code == protocolSendFailed {
            weakSelf?.showToast(commonLocalizable("network_error"))
          } else if err.code == noPermissionCode {
            weakSelf?.showToast(localizable("no_permission_tip"))
          } else {
            weakSelf?.showToast(localizable("failed_operation"))
          }
        } else {
          model.subTitle = localizable("team_owner_and_manager")
          weakSelf?.contentTableView.reloadData()
        }
      }
    }
    managerAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    managerAction.accessibilityIdentifier = "id.teamOwner"
    actionSheetController.addAction(managerAction)

    navigationController?.present(actionSheetController, animated: true, completion: nil)
  }

  /// 点击修改置顶权限回调
  open func didTopMessagePermissionClick(_ model: SettingCellModel) {
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

    let allAction = UIAlertAction(title: localizable("team_all"), style: .default) { [weak self] _ in

      if self?.viewModel.teamMember?.memberRole != .TEAM_MEMBER_ROLE_OWNER, self?.viewModel.teamMember?.memberRole != .TEAM_MEMBER_ROLE_MANAGER {
        self?.showToast(localizable("no_permission_tip"))
        return
      }
      weakSelf?.viewModel.updateTeamTopMessagePermission(false) { error in
        if let err = error as? NSError {
          if err.code == protocolSendFailed {
            weakSelf?.showToast(commonLocalizable("network_error"))
          } else if err.code == noPermissionCode {
            weakSelf?.showToast(localizable("no_permission_tip"))
          } else {
            weakSelf?.showToast(localizable("failed_operation"))
          }
        } else {
          model.subTitle = localizable("team_all")
          weakSelf?.contentTableView.reloadData()
        }
      }
    }
    allAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    allAction.accessibilityIdentifier = "id.teamAllMember"
    actionSheetController.addAction(allAction)
    actionSheetController.fixIpadAction()

    let managerAction = UIAlertAction(title: localizable("team_owner_and_manager"), style: .default) { [weak self] _ in
      if self?.viewModel.teamMember?.memberRole != .TEAM_MEMBER_ROLE_OWNER, self?.viewModel.teamMember?.memberRole != .TEAM_MEMBER_ROLE_MANAGER {
        self?.showToast(localizable("no_permission_tip"))
        return
      }
      weakSelf?.viewModel.updateTeamTopMessagePermission(true) { error in
        if let err = error as? NSError {
          if err.code == protocolSendFailed {
            weakSelf?.showToast(commonLocalizable("network_error"))
          } else if err.code == noPermissionCode {
            weakSelf?.showToast(localizable("no_permission_tip"))
          } else {
            weakSelf?.showToast(localizable("failed_operation"))
          }
        } else {
          model.subTitle = localizable("team_owner_and_manager")
          weakSelf?.contentTableView.reloadData()
        }
      }
    }
    managerAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    managerAction.accessibilityIdentifier = "id.teamOwner"
    actionSheetController.addAction(managerAction)

    navigationController?.present(actionSheetController, animated: true, completion: nil)
  }

  open func didManagerClick() {}

  /// 刷新数据
  open func didRefreshData() {
    reloadSectionData()
    contentTableView.reloadData()
  }
}
