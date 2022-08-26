
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitCoreIM
import NEKitCore
public class MemberListViewController: NEBaseViewController,UITableViewDelegate, UITableViewDataSource {
  public var serverViewModel = CreateServerViewModel()
  public var memberViewModel = MemberListViewModel()

  var dataArray: [ServerMemeber]?
  var serverId: UInt64?

  override public func viewDidLoad() {
    super.viewDidLoad()
    initializeConfig()
    requestData()
    addSubviews()
    // Do any additional setup after loading the view.
  }

  func requestData() {
    guard let id = serverId else {
      print("serverId is nil")
      return
    }
    let param = QChatGetServerMembersByPageParam(timeTag: 0, serverId: id)
    weak var weakSelf = self
    memberViewModel.requestServerMemebersByPage(param: param) { error, serverMemberArray in
      if error == nil {
        weakSelf?.dataArray = serverMemberArray
        weakSelf?.tableView.reloadData()
      } else {}
    }
  }

  func initializeConfig() {
    title = "成员"
    addRightAction(UIImage.ne_imageNamed(name: "sign_add"), #selector(addMemberClick), self)
  }

  func addSubviews() {
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  // MARK: lazy method

  private lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(
      NEGroupIdentityMemberCell.self,
      forCellReuseIdentifier: "\(NSStringFromClass(NEGroupIdentityMemberCell.self))"
    )
    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
    tableView.estimatedRowHeight = 125
    return tableView
  }()
    
    //MAKR: UITableViewDelegate, UITableViewDataSource
    @objc func addMemberClick(sender: UIButton) {
      Router.shared.register(ContactSelectedUsersRouter) { [weak self] param in
        print("param\(param)")
        if let userIds = param["accids"] as? [String] {
          print("userIds:\(userIds)")
          guard let serverId = self?.serverId else { return }
          self?.serverViewModel
            .inviteMembersToServer(serverId: serverId, accids: userIds) { error in
              if error == nil {
                self?.requestData()
              }
            }
        }
      }

      Router.shared
        .use(ContactUserSelectRouter,
             parameters: ["nav": navigationController]) { obj, routerState, str in
          print("obj:\(obj) routerState:\(routerState) str:\(str)")
        }

  //        FIXME: router
  //        let contactCtrl = ContactsSelectedViewController()
  //        self.navigationController?.pushViewController(contactCtrl, animated: true)
  //        weak var weakSelf = self
  //
  //        contactCtrl.callBack = {(selectMemberarray)->Void in
  //
  //            guard let serverId = weakSelf?.serverId else { return  }
  //            var accidArray = [String]()
  //            selectMemberarray.forEach { memberInfo in
  //                accidArray.append(memberInfo.user?.userId ?? "")
  //            }
  //            weakSelf?.serverViewModel.inviteMembersToServer(serverId: serverId, accids: accidArray) { error in
  //                if error == nil{
  //                    weakSelf?.requestData()
  //                }
  //            }
  //        }
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      dataArray?.count ?? 0
    }

    public func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(
        withIdentifier: "\(NSStringFromClass(NEGroupIdentityMemberCell.self))",
        for: indexPath
      ) as! NEGroupIdentityMemberCell
      cell.memberModel = dataArray?[indexPath.row]
      return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
  //        let user = viewModel.limitUsers[indexPath.row]
      if let member = dataArray?[indexPath.row] {
        let editMember = QChatEditMemberViewController()
        editMember.deleteCompletion = {
          self.requestData()
        }
        editMember.changeCompletion = {
          self.requestData()
        }
        let user = UserInfo(member)
        editMember.user = user
        navigationController?.pushViewController(editMember, animated: true)
      }
    }
}


