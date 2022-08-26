
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitCoreIM

typealias CreateCompletion = () -> Void

public class QChatCreateGroupViewController: NEBaseTableViewController,
  QChatMemberSelectControllerDelegate,UITableViewDataSource, UITableViewDelegate,ViewModelDelegate, QChatTextEditCellDelegate {
  let viewModel = CreateGroupViewModel()

  var serverId: UInt64?

  var serverName = ""

  var completion: CreateCompletion?

  override public func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    viewModel.delegate = self
    setupUI()
  }

  func setupUI() {
    addRightAction(localizable("create"), #selector(createClick), self)
    title = localizable("qchat_create_new_id_group")
    setupTable()
    tableView.delegate = self
    tableView.backgroundColor = .ne_backcolor

    tableView.dataSource = self
    tableView.register(
      QChatTextArrowCell.self,
      forCellReuseIdentifier: "\(QChatTextArrowCell.self)"
    )
    tableView.register(
      QChatTextEditCell.self,
      forCellReuseIdentifier: "\(QChatTextEditCell.self)"
    )
    tableView.register(QChatUnfoldCell.self, forCellReuseIdentifier: "\(QChatUnfoldCell.self)")
    tableView.register(
      QChatIdGroupMemberCell.self,
      forCellReuseIdentifier: "\(QChatIdGroupMemberCell.self)"
    )
  }

    //MAKR: objc 方法
    @objc func createClick() {
      if serverName.count <= 0 {
        view.makeToast(localizable("qchat_please_input_role_name"))
        return
      }
      var param = ServerRoleParam()
      param.serverId = serverId
      param.type = .custom
      param.name = serverName
      weak var weakSelf = self
      print("create role param : ", param)

      viewModel.repo.createRole(param) { error, role in
        print("create role : ", error as Any, role)
        if let err = error {
          weakSelf?.dataDidError(err)
        } else {
          if let rid = role.roleId, let addMemebers = weakSelf?.viewModel.allUsers,
             addMemebers.count > 0 {
            weakSelf?.addMember(rid)
          } else {
            if let block = weakSelf?.completion {
              block()
            }
            weakSelf?.navigationController?.popViewController(animated: true)
          }
        }
      }
    }

    func addMember(_ roleId: UInt64) {
      weak var weakSelf = self
      if viewModel.allUsers.count > 0 {
        var accids = [String]()
        viewModel.allUsers.forEach { user in
          if let accid = user.serverMember?.accid {
            accids.append(accid)
          }
        }
        var param = AddServerRoleMemberParam()
        param.accountArray = accids
        param.serverId = serverId
        param.roleId = roleId
        viewModel.repo.addRoleMember(param) { error, sAccids, fAccids in
          if let err = error {
            weakSelf?.showToast(err.localizedDescription)
          }
          if let block = weakSelf?.completion {
            block()
          }
          weakSelf?.navigationController?.popViewController(animated: true)
        }
      }
    }
//MARK :
    public func filterMembers(accid: [String]?, _ filterMembers: @escaping ([String]?) -> Void) {
      var dic = [String: String]()
      viewModel.allUsers.forEach { user in
        if let aid = user.accid {
          dic[aid] = aid
        }
      }
      var retArray = [String]()
      accid?.forEach { aid in
        if dic[aid] != nil {
          retArray.append(aid)
        }
      }
      filterMembers(retArray)

  //        filterMembers(accid)
    }


    func textDidChange(_ textField: UITextField) {
      if let text = textField.text {
        serverName = text
      }
      print("text change: ", textField.text as Any)
    }

    public func dataDidError(_ error: Error) {
      UIApplication.shared.keyWindow?.endEditing(true)
      view.makeToast(error.localizedDescription)
    }

    public func dataDidChange() {
      tableView.reloadData()
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
      let count = 3
  //        if viewModel.limitUsers.count < viewModel.allUsers.count {
  //            count = count + 1
  //        }
      return count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      if section == 0 || section == 1 {
        return 1
      } else if section == 2 {
        return viewModel.allUsers.count
      } else if section == 3 {
        return 0
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
        cell.textFied.placeholder = localizable("qchat_please_input_role_name")
        cell.delegate = self
        cell.limit = 20
        cell.cornerType = CornerType.bottomLeft.union(CornerType.bottomRight)
          .union(CornerType.topLeft).union(CornerType.topRight)
        return cell
      } else if indexPath.section == 1 {
        let cell: QChatTextArrowCell = tableView.dequeueReusableCell(
          withIdentifier: "\(QChatTextArrowCell.self)",
          for: indexPath
        ) as! QChatTextArrowCell
        cell.titleLabel.text = localizable("qchat_add_member")
        cell.cornerType = CornerType.bottomLeft.union(CornerType.bottomRight)
          .union(CornerType.topLeft).union(CornerType.topRight)
        return cell
      } else if indexPath.section == 2 {
        let cell: QChatIdGroupMemberCell = tableView.dequeueReusableCell(
          withIdentifier: "\(QChatIdGroupMemberCell.self)",
          for: indexPath
        ) as! QChatIdGroupMemberCell
        let user = viewModel.allUsers[indexPath.row]
        cell.cornerType = user.cornerType
        cell.user = user
        return cell
      } else if indexPath.section == 3 {
        let cell: QChatUnfoldCell = tableView.dequeueReusableCell(
          withIdentifier: "\(QChatUnfoldCell.self)",
          for: indexPath
        ) as! QChatUnfoldCell
        cell.contentLabel.text = "更多(共\(viewModel.allUsers.count))人"
        cell.cornerType = CornerType.bottomLeft.union(CornerType.bottomRight)
        return cell
      }
      return UITableViewCell()
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      if indexPath.section == 1 {
        let memberSelect = QChatMemberSelectController()
        memberSelect.serverId = serverId
        memberSelect.delegate = self
  //            memberSelect.selectType = .ServerMember
        weak var weakSelf = self
        memberSelect.completion = { datas in
          if datas.count > 0 {
            weakSelf?.viewModel.addMembers(datas)
          }
        }
        navigationController?.pushViewController(memberSelect, animated: true)

      } else if indexPath.section == 2 {
        // 编辑成员临时入口

  //            let user = viewModel.limitUsers[indexPath.row]
  //            let editMember = QChatEditMemberViewController()
  //            editMember.user = user
  //            navigationController?.pushViewController(editMember, animated: true)

        viewModel.removeData(indexPath.row)
      } else if indexPath.section == 3 {
        viewModel.loadAllData()
        tableView.reloadData()
      }
    }

    public func tableView(_ tableView: UITableView,
                          heightForRowAt indexPath: IndexPath) -> CGFloat {
      50
    }

    public func tableView(_ tableView: UITableView,
                          heightForHeaderInSection section: Int) -> CGFloat {
      if section == 0 || section == 1 {
        return 40.0
      } else if section == 2 {
        return 16
      }
      return 0
    }

    public func tableView(_ tableView: UITableView,
                          viewForHeaderInSection section: Int) -> UIView? {
      let header = QChatHeaderView()
      if section == 0 {
        header.titleLabel.text = localizable("qchat_group_name")
        return header
      }

      if section == 1 {
        header.titleLabel.text = localizable("qchat_manager_member")
        return header
      }

      if section == 2 {
        let space = UIView()
        space.backgroundColor = .clear
        return space
      }

      return nil
    }
}




