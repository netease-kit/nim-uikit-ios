
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitCoreIM
import NEKitCommon
public class BlackListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,
  TeamTableViewCellDelegate {
  var tableView = UITableView(frame: .zero, style: .plain)
  var viewModel = BlackListViewModel()
  public var blackList: [User]?

  override public func viewDidLoad() {
    super.viewDidLoad()
    commonUI()
    loadData()
  }

  func commonUI() {
    title = "黑名单"
    let image = UIImage.ne_imageNamed(name: "backArrow")?.withRenderingMode(.alwaysOriginal)
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      image: image,
      style: .plain,
      target: self,
      action: #selector(backEvent)
    )
    let addImage = UIImage.ne_imageNamed(name: "add")?.withRenderingMode(.alwaysOriginal)
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      image: addImage,
      style: .plain,
      target: self,
      action: #selector(addBlack)
    )

    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    tableView.register(
      BlackListCell.self,
      forCellReuseIdentifier: "\(NSStringFromClass(TeamTableViewCell.self))"
    )
    tableView.rowHeight = 62
    let headView =
      UIView(frame: CGRect(x: 0, y: 0, width: Int(NEConstant.screenWidth), height: 40))
    let contentLabel =
      UILabel(frame: CGRect(x: 20, y: 0, width: Int(NEConstant.screenWidth) - 20, height: 40))
    contentLabel.text = "   你不会收到列表中任何联系人的消息"
    contentLabel.textColor = UIColor.ne_emptyTitleColor
    contentLabel.font = UIFont.systemFont(ofSize: 14)
    headView.addSubview(contentLabel)
    tableView.tableHeaderView = headView
  }

  func loadData() {
    blackList = viewModel.getBlackList()
    tableView.reloadData()
  }

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    blackList?.count ?? 0
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(NSStringFromClass(TeamTableViewCell.self))",
      for: indexPath
    ) as! BlackListCell
    cell.delegate = self
    cell.index = indexPath.row
    cell.setModel(blackList?[indexPath.row] as Any)
    return cell
  }

  @objc func backEvent() {
    navigationController?.popViewController(animated: true)
  }

  @objc func addBlack() {
    let contactSelectVC = ContactsSelectedViewController()
    navigationController?.pushViewController(contactSelectVC, animated: true)
    contactSelectVC.callBack = { [weak self] selectMemberarray in
      var users = [User]()
      selectMemberarray.forEach { memberInfo in
        if let u = memberInfo.user {
          users.append(u)
        }
      }
      return self?.addBlackUsers(users: users)
    }
  }

  func addBlackUsers(users: [User]) {
    var num = users.count
    var suc = [User]()
    for user in users {
      viewModel.addBlackList(account: user.userId ?? "") { [weak self] error in
        if error == nil {
          suc.append(user)
        }
        num = num - 1
        if num == 0 {
          print("add black finished")
          self?.blackList?.append(contentsOf: suc)
          self?.tableView.reloadData()
        }
      }
    }
  }

  // MARK: TeamTableViewCellDelegate

  func removeUser(account: String?, index: Int) {
    guard let acc = account else {
      return
    }
    viewModel.removeFromBlackList(account: acc) { error in
      // 1.当前页面刷新
      if error == nil {
        self.blackList?.remove(at: index)
        self.tableView.reloadData()
      } else {
        print("removeFromBlackList error:\(error!)")
      }
    }
  }
}
