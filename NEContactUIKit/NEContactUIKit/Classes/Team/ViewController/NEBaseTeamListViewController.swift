
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseTeamListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
  public let navigationView = NENavigationView()
  var tableView = UITableView(frame: .zero, style: .plain)
  var viewModel = TeamListViewModel()
  var isClickCallBack = false

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    navigationController?.interactivePopGestureRecognizer?.delegate = self
    if let useSystemNav = NEConfigManager.instance.getParameter(key: useSystemNav) as? Bool, useSystemNav {
      navigationController?.isNavigationBarHidden = false
    } else {
      navigationController?.isNavigationBarHidden = true
    }

    commonUI()
    loadData()
    weak var weakSelf = self
    viewModel.refresh = {
      weakSelf?.tableView.reloadData()
    }
  }

  func commonUI() {
    title = localizable("mine_groupchat")
    navigationView.navTitle.text = title
    let image = UIImage.ne_imageNamed(name: "backArrow")?.withRenderingMode(.alwaysOriginal)
    let backItem = UIBarButtonItem(
      image: image,
      style: .plain,
      target: self,
      action: #selector(backEvent)
    )
    backItem.accessibilityIdentifier = "id.backArrow"

    navigationItem.leftBarButtonItem = backItem

    navigationView.translatesAutoresizingMaskIntoConstraints = false
    navigationView.addBackButtonTarget(target: self, selector: #selector(backEvent))
    navigationView.moreButton.isHidden = true
    view.addSubview(navigationView)
    NSLayoutConstraint.activate([
      navigationView.leftAnchor.constraint(equalTo: view.leftAnchor),
      navigationView.rightAnchor.constraint(equalTo: view.rightAnchor),
      navigationView.topAnchor.constraint(equalTo: view.topAnchor),
      navigationView.heightAnchor.constraint(equalToConstant: NEConstant.navigationAndStatusHeight),
    ])

    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: NEConstant.navigationAndStatusHeight),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
  }

  func loadData() {
    viewModel.getTeamList()
    tableView.reloadData()
  }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.teamList.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    UITableViewCell()
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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

  func backEvent() {
    navigationController?.popViewController(animated: true)
  }
}
