
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import MJRefresh
import NEKitCoreIM

typealias MemberCountChange = (Int) -> Void

public class QChatMemberManagerController: NEBaseTableViewController,UITableViewDelegate, UITableViewDataSource,ViewModelDelegate,QChatMemberSelectControllerDelegate {
  let viewmodel = MemberManagerViewModel()

  var memberCount = 0

  var serverId: UInt64?

  var roleId: UInt64?

  var countChangeBlock: MemberCountChange?

  override public func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    viewmodel.delegate = self
    loadMoreData()
    setupUI()
  }

  func setupUI() {
    title = localizable("qchat_manager_member")
    view.backgroundColor = .white
    setupTable()
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(
      QChatMemberManagerCell.self,
      forCellReuseIdentifier: "\(QChatMemberManagerCell.self)"
    )
    tableView.register(
      QChatPlainTextArrowCell.self,
      forCellReuseIdentifier: "\(QChatPlainTextArrowCell.self)"
    )

    let mjfooter = MJRefreshBackNormalFooter(
      refreshingTarget: self,
      refreshingAction: #selector(loadMoreData)
    )
    mjfooter.stateLabel?.isHidden = true
    tableView.mj_footer = mjfooter
  }

  @objc func loadMoreData() {
    if let rid = roleId, let sid = serverId {
      viewmodel.getData(sid, rid)
    } else {
      fatalError("serverId or roleId is nil")
    }
  }

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       // Get the new view controller using segue.destination.
       // Pass the selected object to the new view controller.
   }
   */
    //MARK: UITableViewDelegate, UITableViewDataSource,ViewModelDelegate,QChatMemberSelectControllerDelegate
    
    public func filterMembers(accid: [String]?, _ filterMembers: @escaping ([String]?) -> Void) {
      var param = GetExistingServerRoleMembersByAccidsParam()
      param.serverId = serverId
      param.accids = accid
      param.roleId = roleId
      print("param existing accid : ", accid as Any)
      viewmodel.repo.getExistingServerRoleMembersByAccids(param) { error, accids in
        print("getExistingServerRoleMembersByAccids : ", accids)
        var dic = [String: String]()
        var retAccids = [String]()
        accids.forEach { aid in
          dic[aid] = aid
        }
        accid?.forEach { aid in
          if dic[aid] != nil {
            retAccids.append(aid)
          }
        }
        print("filter members : ", retAccids)
        filterMembers(retAccids)
      }
    }

    public func dataDidChange() {
      view.hideToastActivity()
      tableView.mj_footer?.endRefreshing()
      tableView.reloadData()
    }

    public func dataNoMore() {
      view.hideToastActivity()
      tableView.mj_footer?.endRefreshingWithNoMoreData()
      tableView.mj_footer?.isHidden = true
    }

    public func dataDidError(_ error: Error) {
      showToast(error.localizedDescription)
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
      2
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      if section == 0 {
        return 1
      }
      if section == 1 {
        return viewmodel.datas.count
      }
      return 0
    }

    public func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      if indexPath.section == 0 {
        let cell: QChatPlainTextArrowCell = tableView.dequeueReusableCell(
          withIdentifier: "\(QChatPlainTextArrowCell.self)",
          for: indexPath
        ) as! QChatPlainTextArrowCell
        cell.titleLabel.text = localizable("qchat_add_member")
        cell.detailLabel.text = "\(memberCount)"
        return cell
      }

      if indexPath.section == 1 {
        let cell: QChatMemberManagerCell = tableView.dequeueReusableCell(
          withIdentifier: "\(QChatMemberManagerCell.self)",
          for: indexPath
        ) as! QChatMemberManagerCell
        let user = viewmodel.datas[indexPath.row]
        cell.user = user
        return cell
      }

      return UITableViewCell()
    }

    public func tableView(_ tableView: UITableView,
                          heightForRowAt indexPath: IndexPath) -> CGFloat {
      50
    }

    public func tableView(_ tableView: UITableView,
                          heightForHeaderInSection section: Int) -> CGFloat {
      0
    }

    public func tableView(_ tableView: UITableView,
                          heightForFooterInSection section: Int) -> CGFloat {
      0
    }

    public func tableView(_ tableView: UITableView,
                          viewForHeaderInSection section: Int) -> UIView? {
      nil
    }

    public func tableView(_ tableView: UITableView,
                          viewForFooterInSection section: Int) -> UIView? {
      nil
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      weak var weakSelf = self
      if indexPath.section == 0 {
        let memberSelect = QChatMemberSelectController()
        memberSelect.delegate = self
        memberSelect.serverId = serverId
        memberSelect.completion = { users in
          print("member manager select: ", users)
          weakSelf?.view.makeToastActivity(.center)
          weakSelf?.viewmodel
            .addMembers(users, weakSelf?.serverId, weakSelf?.roleId) { successCount in
  //                    weakSelf?.view.hideToastActivity()
              weakSelf?.showToast(localizable("qchat_add_success"))
              if let block = weakSelf?.countChangeBlock, var count = weakSelf?.memberCount {
                count = count + successCount
                weakSelf?.memberCount = count
                block(count)
              }
            }
        }
        navigationController?.pushViewController(memberSelect, animated: true)
      } else {
        let user = viewmodel.datas[indexPath.row]
        showAlert(message: localizable("qchat_sure_delete_user")) {
          if let rid = weakSelf?.roleId, let sid = weakSelf?.serverId {
            weakSelf?.view.makeToastActivity(.center)
            weakSelf?.viewmodel.remove(user, sid, rid) {
              weakSelf?.view.hideToastActivity()
              weakSelf?.viewmodel.datas.remove(at: indexPath.row)
              weakSelf?.tableView.reloadData()
              if var count = weakSelf?.memberCount,
                 let block = weakSelf?.countChangeBlock {
                count = count - 1
                weakSelf?.memberCount = count
                block(count)
              }
            }
          }
        }
      }
    }
}


