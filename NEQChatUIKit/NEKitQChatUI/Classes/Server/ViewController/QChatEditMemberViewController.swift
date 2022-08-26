
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitCore
import NEKitCoreIM

// typealias EditMemberCompletion = (_ member: ServerMemeber) -> Void

typealias EditMemberChange = () -> Void

typealias EditMemberDelete = () -> Void

public class QChatEditMemberViewController: NEBaseTableViewController,UITableViewDataSource, UITableViewDelegate,ViewModelDelegate, QChatTextEditCellDelegate {
  var user: UserInfo?
  var editAble = false
  var showAll = false
  let viewModel = EditMemberViewModel()

//    var completion: EditMemberCompletion?
  var changeCompletion: EditMemberChange?
  var deleteCompletion: EditMemberDelete?
  var nickName = ""

  var didChange = false

  override public func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    if let nick = user?.nickName {
      nickName = nick
    }
//        else if let acid = user?.accid {
//            nickName = acid
//        }
    viewModel.delegate = self
    viewModel.getData(user?.serverId, user?.accid)
    setupUI()
  }

  func setupUI() {
    setupTable()
    if let name = user?.nickName {
      title = name
    }
    addRightAction(localizable("qchat_edit"), #selector(rightBtnClick(_:)), self)
    tableView.register(
      QChatTextEditCell.self,
      forCellReuseIdentifier: "\(QChatTextEditCell.self)"
    )
    tableView.register(QChatHeaderCell.self, forCellReuseIdentifier: "\(QChatHeaderCell.self)")
    tableView.register(
      QChatDestructiveCell.self,
      forCellReuseIdentifier: "\(QChatDestructiveCell.self)"
    )
    tableView.register(
      QChatIdGroupSelectCell.self,
      forCellReuseIdentifier: "\(QChatIdGroupSelectCell.self)"
    )
    tableView.register(QChatUnfoldCell.self, forCellReuseIdentifier: "\(QChatUnfoldCell.self)")
    tableView.dataSource = self
    tableView.delegate = self
    tableView.backgroundColor = .ne_backcolor

//        let image = UIImage.ne_imageNamed(name: "backArrow")?.withRenderingMode(.alwaysOriginal)
//        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(back))
    addLeftAction(UIImage.ne_imageNamed(name: "backArrow"), #selector(back), self)
  }

  @objc func back() {
    didChangeRole()
    navigationController?.popViewController(animated: true)
  }

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       // Get the new view controller using segue.destination.
       // Pass the selected object to the new view controller.
   }
   */
    //MARK: objc 方法
    @objc func rightBtnClick(_ btn: ExpandButton) {
      if btn.isSelected == true {
        print("to save")
        if nickName.count <= 0 {
          showToast("昵称不能为空")
          return
        }

        guard let accid = user?.accid else {
          showToast("accid 不能为空")
          return
        }

        weak var weakSelf = self

        if IMKitLoginManager.instance.isMySelf(accid) == true {
          viewModel.updateMyMember(user?.serverMember?.serverId, nickName) { error, member in
            if let err = error {
              weakSelf?.showToast(err.localizedDescription)
            } else {
              weakSelf?.navigationController?.popViewController(animated: true)
              if let block = weakSelf?.changeCompletion {
                block()
              }
            }
          }
        } else {
          viewModel
            .updateMember(user?.serverMember?.serverId, nickName,
                          user?.accid) { error, member in
              if let err = error {
                weakSelf?.showToast(err.localizedDescription)
              } else {
                weakSelf?.navigationController?.popViewController(animated: true)
                if let block = weakSelf?.changeCompletion {
                  block()
                }
              }
            }
        }

      } else {
        btn.isSelected = true
        editAble = true
        btn.setTitle(localizable("qchat_save"), for: .normal)
        viewModel.showServerData()
      }
    }
    
    //MARK: UITableViewDataSource, UITableViewDelegate,ViewModelDelegate, QChatTextEditCellDelegate
    func textDidChange(_ textField: UITextField) {
      print("edit mebmer name change : ", textField.text as Any)
      if let text = textField.text {
        nickName = text
      }
    }

    public func dataDidChange() {
      tableView.reloadData()
    }

    public func dataDidError(_ error: Error) {
      showToast(error.localizedDescription)
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
      5
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      if section == 0 || section == 1 {
        return 1
      } else if section == 2 {
        return showAll ? viewModel.allIdGroups.count : viewModel.limitIdGroups.count
      } else if section == 3 {
        if viewModel.limitIdGroups.count < viewModel.allIdGroups.count {
          return 1
        }
      } else if section == 4 {
        return 1
      }
      return 0
    }

    public func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      if indexPath.section == 0 {
        let cell: QChatHeaderCell = tableView.dequeueReusableCell(
          withIdentifier: "\(QChatHeaderCell.self)",
          for: indexPath
        ) as! QChatHeaderCell
        cell.cornerType = CornerType.topLeft.union(CornerType.topRight)
          .union(CornerType.bottomLeft).union(CornerType.bottomRight)
        cell.user = user
        return cell
      } else if indexPath.section == 1 {
        let cell: QChatTextEditCell = tableView.dequeueReusableCell(
          withIdentifier: "\(QChatTextEditCell.self)",
          for: indexPath
        ) as! QChatTextEditCell
        cell.cornerType = CornerType.topLeft.union(CornerType.topRight)
          .union(CornerType.bottomLeft).union(CornerType.bottomRight)
        cell.delegate = self
        cell.editTotast = "请点击编辑后修改昵称"
        cell.canEdit = editAble
        if nickName.count > 0 {
          cell.textFied.text = nickName
        } else {
          cell.textFied.text = nil
        }
        cell.textFied.placeholder = localizable("qcaht_edit_nickname")
        return cell
      } else if indexPath.section == 2 {
        let cell: QChatIdGroupSelectCell = tableView.dequeueReusableCell(
          withIdentifier: "\(QChatIdGroupSelectCell.self)",
          for: indexPath
        ) as! QChatIdGroupSelectCell
        let group = showAll ? viewModel.allIdGroups[indexPath.row] : viewModel
          .limitIdGroups[indexPath.row]
        cell.tailImage.isHidden = !editAble
        if let type = group.role?.type, type == .everyone {
          cell.tailImage.isHidden = true
        }
        let exist = viewModel.checkoutCurrentUserRole(group.role?.roleId)
        print("checkoutCurrentUserRole name : \(group.idName ?? "") exist : \(exist)")
        group.isSelect = exist
        cell.group = group
        return cell
      } else if indexPath.section == 3 {
        let cell: QChatUnfoldCell = tableView.dequeueReusableCell(
          withIdentifier: "\(QChatUnfoldCell.self)",
          for: indexPath
        ) as! QChatUnfoldCell
        cell.contentLabel
          .text = showAll ? "收起(共\(viewModel.allIdGroups.count)个)" :
          "更多(共\(viewModel.allIdGroups.count)个)"
        if showAll {
          cell.changeToArrowUp()
        } else {
          cell.changeToArrowDown()
        }
        cell.cornerType = CornerType.bottomLeft.union(CornerType.bottomRight)
        return cell
      } else if indexPath.section == 4 {
        let cell: QChatDestructiveCell = tableView.dequeueReusableCell(
          withIdentifier: "\(QChatDestructiveCell.self)",
          for: indexPath
        ) as! QChatDestructiveCell
        if indexPath.row == 0 {
          cell.cornerType = CornerType.topLeft.union(CornerType.topRight)
            .union(CornerType.bottomLeft).union(CornerType.bottomRight)
          cell.redTextLabel.text = "\(localizable("qchat_kick_out")) \(user?.nickName ?? "")"
          if getKickDisable() {
            cell.changeDisableTextColor()
          }
        } else if indexPath.row == 1 {
          cell.cornerType = CornerType.bottomLeft.union(CornerType.bottomRight)
          cell.redTextLabel.text = "\(localizable("qchat_prohibit")) \(user?.nickName ?? "")"
          cell.changeEnableTextColor()
        }
        return cell
      }

      return UITableViewCell()
    }

    public func tableView(_ tableView: UITableView,
                          heightForRowAt indexPath: IndexPath) -> CGFloat {
      if indexPath.section == 0 {
        return 92
      }
      return 50
    }

    public func tableView(_ tableView: UITableView,
                          viewForHeaderInSection section: Int) -> UIView? {
      let header = QChatHeaderView()
      if section == 1 {
        header.titleLabel.text = localizable("qchat_nickname")
        return header
      }

      if section == 2, viewModel.allIdGroups.count > 0 {
        header.titleLabel.text = localizable("qchat_id_group")
        return header
      }
      return nil
    }

    public func tableView(_ tableView: UITableView,
                          heightForHeaderInSection section: Int) -> CGFloat {
      if section == 0 {
        return 22
      }

      if section == 1 {
        return 38
      }

      if section == 2, viewModel.allIdGroups.count > 0 {
        return 38
      }

      if section == 4 {
        return 20
      }
      return 0
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      if indexPath.section == 1 {
        // showToast("请点击编辑后修改昵称")
      } else if indexPath.section == 2 {
        if editAble == false {
          return
        }

        let group = showAll == true ? viewModel.allIdGroups[indexPath.row] : viewModel
          .limitIdGroups[indexPath.row]

        if let type = group.role?.type, type == .everyone {
          return
        }
        let select = viewModel.checkoutCurrentUserRole(group.role?.roleId)
        weak var weakSelf = self
        if select == false {
          view.makeToastActivity(.center)
          viewModel.addMembers(user?.accid, user?.serverId, group.role?.roleId) {
            weakSelf?.view.hideToastActivity()
            weakSelf?.didChange = true
          }
        } else {
          view.makeToastActivity(.center)
          viewModel.remove(user?.accid, user?.serverId, group.role?.roleId) {
            weakSelf?.view.hideToastActivity()
            weakSelf?.didChange = true
          }
        }
      } else if indexPath.section == 3 {
        showAll = !showAll
        tableView.reloadData()
      } else if indexPath.section == 4 {
        weak var weakSelf = self
        if getKickDisable() == true {
          return
        }
        showAlert(message: "确定踢出当前成员?") {
          weakSelf?.kickOutMember()
        }
      }
    }

    func didChangeRole() {
      if didChange == true {
        if let block = changeCompletion {
          block()
        }
      }
    }

    func getKickDisable() -> Bool {
      if let accid = user?.serverMember?.accid {
  //            if CoreKitEngine.instance.imAccid == accid {
  //                return true
  //            }

        if IMKitLoginManager.instance.imAccid == accid {
          return true
        }
        if let type = user?.serverMember?.type, type == .owner {
          return true
        }
      }
      return false
    }

    func kickOutMember() {
      view.makeToastActivity(.center)
      weak var weakSelf = self
      viewModel.kickoutMember(user?.serverId, user?.accid) { error in
        weakSelf?.view.hideToastActivity()
        if let err = error {
          weakSelf?.showToast(err.localizedDescription)
        } else {
          if let block = weakSelf?.deleteCompletion {
            block()
          }
          weakSelf?.navigationController?.popViewController(animated: true)
        }
      }
    }
    
    
}


