
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitCoreIM

typealias RoleUpdateCompletion = (_ role: ServerRole) -> Void
public class QChatPermissionViewController: NEBaseTableViewController,UITableViewDelegate, UITableViewDataSource, QChatTextEditCellDelegate, ViewModelDelegate, QChatSwitchCellDelegate {
  var idGroup: IdGroupModel?

  let viewmodel = PermissionViewModel()

  var serverName = ""

  var completion: RoleUpdateCompletion?

  override public func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    viewmodel.delegate = self
    if let name = idGroup?.role?.name {
      serverName = name
    }
    if let serverRole = idGroup?.role {
      viewmodel.getData(serverRole)
    } else {
      fatalError("permission server role is nil ")
    }
    setupUI()
  }

  func setupUI() {
    if let type = idGroup?.role?.type, type != .everyone {
      addRightAction(localizable("qchat_save"), #selector(savePermission), self)
    }

    setupTable()
    title = idGroup?.idName
    tableView.backgroundColor = .ne_backcolor
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(
      QChatTextEditCell.self,
      forCellReuseIdentifier: "\(QChatTextEditCell.self)"
    )
    tableView.register(QChatSwitchCell.self, forCellReuseIdentifier: "\(QChatSwitchCell.self)")
    tableView.register(
      QChatTextArrowCell.self,
      forCellReuseIdentifier: "\(QChatTextArrowCell.self)"
    )
  }

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   // Get the new view controller using segue.destination.
   // Pass the selected object to the new view controller.
   }
   */
    //MARK: UITableViewDelegate, UITableViewDataSource, QChatTextEditCellDelegate, ViewModelDelegate, QChatSwitchCellDelegate
    
    func didChangeSwitchValue(_ cell: QChatSwitchCell) {
      print("did change switch value : ", cell)
      if let key = cell.model?.permissionKey,
         let value = cell.model?.permission?.value(forKey: key) as? String,
         let type = ChatPermissionType(rawValue: value) {
        updatePermission(type, cell.qSwitch.isOn) { success in
          if success == false {
            cell.qSwitch.isOn = !cell.qSwitch.isOn
          }
        }
      }
    }

    public func dataDidChange() {
      tableView.reloadData()
    }

    public func dataDidError(_ error: Error) {
      showToast(error.localizedDescription)
    }

    func textDidChange(_ textField: UITextField) {
      if let text = textField.text {
        serverName = text
      }
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
      5
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      if section == 0 {
        return 1
      }
      if section == 1 {
        if let type = idGroup?.role?.type, type == .everyone {
          return 0
        }
        return 1
      }
      if section == 2 {
        return viewmodel.commons.count
      }
      if section == 3 {
        return viewmodel.messages.count
      }
      if section == 4 {
        return viewmodel.members.count
      }
      return 0
    }

    public func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      if indexPath.section == 0 {
        let cell: QChatTextEditCell = tableView.dequeueReusableCell(
          withIdentifier: "\(QChatTextEditCell.self)",
          for: indexPath
        ) as! QChatTextEditCell
        if serverName.count > 0 {
          cell.textFied.text = serverName
        } else {
          cell.textFied.text = nil
        }
        cell.textFied.placeholder = localizable("qchat_please_input_role_name")
        cell.delegate = self
        cell.limit = 20
        cell.cornerType = CornerType.topLeft.union(CornerType.topRight)
          .union(CornerType.bottomLeft).union(CornerType.bottomRight)
        return cell
      }

      if indexPath.section == 1 {
        let cell: QChatTextArrowCell = tableView.dequeueReusableCell(
          withIdentifier: "\(QChatTextArrowCell.self)",
          for: indexPath
        ) as! QChatTextArrowCell
        cell.titleLabel.text = localizable("qchat_member")
        cell.detailLabel.text = "\(idGroup?.role?.memberCount ?? 0)"
        cell.cornerType = CornerType.topLeft.union(CornerType.topRight)
          .union(CornerType.bottomLeft).union(CornerType.bottomRight)
        return cell
      }

      if indexPath.section == 2 || indexPath.section == 3 || indexPath.section == 4 {
        let cell: QChatSwitchCell = tableView.dequeueReusableCell(
          withIdentifier: "\(QChatSwitchCell.self)",
          for: indexPath
        ) as! QChatSwitchCell
        var model: PermissionCellModel?
        if indexPath.section == 2 {
          model = viewmodel.commons[indexPath.row]
        } else if indexPath.section == 3 {
          model = viewmodel.messages[indexPath.row]
        } else if indexPath.section == 4 {
          model = viewmodel.members[indexPath.row]
        }
        cell.delegate = self
        cell.model = model
        return cell
      }

      return UITableViewCell()
    }

    public func tableView(_ tableView: UITableView,
                          heightForRowAt indexPath: IndexPath) -> CGFloat {
      50
    }

    public func tableView(_ tableView: UITableView,
                          viewForHeaderInSection section: Int) -> UIView? {
      let header = QChatHeaderView()
      switch section {
      case 0:
        header.titleLabel.text = localizable("qchat_group_name")
      case 1:
        if let type = idGroup?.role?.type, type == .everyone {
          return nil
        }
        header.titleLabel.text = localizable("qchat_manager_member")
      case 2:
        header.titleLabel.text = localizable("qchat_common_permission")
      case 3:
        header.titleLabel.text = localizable("qchat_message_permission")
      case 4:
        header.titleLabel.text = localizable("qchat_member_permission")
      default:
        break
      }
      return header
    }

    public func tableView(_ tableView: UITableView,
                          heightForHeaderInSection section: Int) -> CGFloat {
      if let type = idGroup?.role?.type, type == .everyone, section == 1 {
        return 0
      }
      return 40
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      if indexPath.section == 1 {
        let memberManager = QChatMemberManagerController()
        memberManager.serverId = idGroup?.role?.serverId
        memberManager.roleId = idGroup?.role?.roleId
        memberManager.memberCount = idGroup?.role?.memberCount ?? 0
        weak var weakSelf = self
        memberManager.countChangeBlock = { count in
          weakSelf?.idGroup?.role?.memberCount = count
          if let role = weakSelf?.idGroup?.role, let block = weakSelf?.completion {
            block(role)
          }
          tableView.reloadData()
        }
        navigationController?.pushViewController(memberManager, animated: true)
      }
    }
    
    //MAKR: objc 方法
    @objc func savePermission() {
      if serverName.count <= 0 {
        showToast(localizable("qchat_please_input_role_name"))
        return
      }
      var param = UpdateServerRoleParam()
      param.serverId = idGroup?.role?.serverId
      if let rid = idGroup?.role?.roleId {
        param.roleId = UInt64(rid)
      }
      param.name = serverName

      /* 批量逻辑，暂时不用
       let permissions = viewmodel.permission.getChangePermission()
       var commonds = [StatusInfo]()

       permissions.forEach { (type: ChatPermissionType, value: Bool) in
           var info = StatusInfo()
           info.permissionType = type
           if value == true {
               info.status = .Allow
           }else {
               info.status = .Deny
           }
           commonds.append(info)
       }
       if commonds.count > 0 {
           print("commonds : ", commonds)
           print("commonds count :", commonds.count)
           param.commands = commonds
       } */

      weak var weakSelf = self
      viewmodel.repo.updateRole(param) { error, role in
        if let err = error {
          weakSelf?.showToast(err.localizedDescription)
        } else {
          if let block = weakSelf?.completion {
            block(role)
          }
          weakSelf?.showToastInWindow(localizable("update_channel_suscess"))
          weakSelf?.navigationController?.popViewController(animated: true)
        }
      }
    }
}



extension QChatPermissionViewController {
  func updatePermission(_ type: ChatPermissionType, _ open: Bool,
                        _ completion: @escaping (Bool) -> Void) {
    var param = UpdateServerRoleParam()
    param.serverId = idGroup?.role?.serverId
    if let rid = idGroup?.role?.roleId {
      param.roleId = UInt64(rid)
    }

    var commonds = [StatusInfo]()
    var info = StatusInfo()
    info.permissionType = type
    info.status = open == true ? .Allow : .Deny
    commonds.append(info)
    param.commands = commonds

    weak var weakSelf = self
    view.makeToastActivity(.center)
    viewmodel.repo.updateRole(param) { error, role in
      weakSelf?.view.hideToastActivity()
      if let err = error {
        weakSelf?.showToast(err.localizedDescription)
        completion(false)
      } else {
        if let block = weakSelf?.completion {
          completion(true)
          block(role)
        }
      }
    }
  }

 
}
