
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK
import NEKitCore

public class TeamListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  var tableView = UITableView(frame: .zero, style: .plain)
  var viewModel = TeamListViewModel()
  var isClickCallBack = false

  override public func viewDidLoad() {
    super.viewDidLoad()
    commonUI()
    loadData()
  }

  func commonUI() {
    title = "我的群聊"
    let image = UIImage.ne_imageNamed(name: "backArrow")?.withRenderingMode(.alwaysOriginal)
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      image: image,
      style: .plain,
      target: self,
      action: #selector(backEvent)
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
      TeamTableViewCell.self,
      forCellReuseIdentifier: "\(NSStringFromClass(TeamTableViewCell.self))"
    )
    tableView.rowHeight = 62
    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
  }

  func loadData() {
    viewModel.getTeamList()
    tableView.reloadData()
  }

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.teamList.count
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(NSStringFromClass(TeamTableViewCell.self))",
      for: indexPath
    ) as! TeamTableViewCell
    cell.setModel(viewModel.teamList[indexPath.row])
    return cell
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let model = viewModel.teamList[indexPath.row]
    if isClickCallBack == true {
      Router.shared.use(
        ContactTeamDataRouter,
        parameters: ["team": model.nimTeam as Any],
        closure: nil
      )
      navigationController?.popViewController(animated: true)
      return
    }
    if let teamid = model.teamId {
      let session = NIMSession(teamid, type: .team)
      Router.shared.use(
        PushTeamChatVCRouter,
        parameters: ["nav": navigationController as Any, "session": session as Any],
        closure: nil
      )
    }
  }

  @objc func backEvent() {
    navigationController?.popViewController(animated: true)
  }
}
