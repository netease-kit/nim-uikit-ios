
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseTeamListViewController: NEContactBaseViewController, UITableViewDelegate, UITableViewDataSource {
  var isClickCallBack = false
  var viewModel = TeamListViewModel()
  public var tableViewTopAnchor: NSLayoutConstraint?

  lazy var tableView: UITableView = {
    var tableView = UITableView(frame: .zero, style: .plain)
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
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

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    tableViewTopAnchor?.constant = topConstant
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white

    commonUI()
    loadData()
    weak var weakSelf = self
    viewModel.refresh = {
      weakSelf?.emptyView.isHidden = (weakSelf?.viewModel.teamList.count ?? 0) > 0
      weakSelf?.tableView.reloadData()
    }
    navigationView.moreButton.isHidden = true
  }

  func initNav() {
    let image = UIImage.ne_imageNamed(name: "backArrow")?.withRenderingMode(.alwaysOriginal)
    let backItem = UIBarButtonItem(
      image: image,
      style: .plain,
      target: self,
      action: #selector(backEvent)
    )
    backItem.accessibilityIdentifier = "id.backArrow"

    navigationItem.leftBarButtonItem = backItem
    navigationView.moreButton.isHidden = true
  }

  func commonUI() {
    title = localizable("my_teams")
    initNav()

    view.addSubview(tableView)
    tableViewTopAnchor = tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant)
    tableViewTopAnchor?.isActive = true
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    emptyView.setText(localizable("team_empty"))
    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.leftAnchor.constraint(equalTo: tableView.leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: tableView.rightAnchor),
      emptyView.topAnchor.constraint(equalTo: tableView.topAnchor),
      emptyView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
    ])
  }

  func loadData() {
    viewModel.getTeamList { [weak self] teams, error in
      if let err = error {
        print("getTeamList error: \(err)")
      } else {
        self?.tableView.reloadData()
        self?.emptyView.isHidden = (teams?.count ?? 0) > 0
      }
    }
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
        parameters: ["team": model.v2Team as Any],
        closure: nil
      )
      navigationController?.popViewController(animated: true)
      return
    }
    if let teamid = model.teamId {
      let conversationId = V2NIMConversationIdUtil.teamConversationId(teamid)
      Router.shared.use(
        PushTeamChatVCRouter,
        parameters: ["nav": navigationController as Any, "conversationId": conversationId as Any],
        closure: nil
      )
    }
  }
}
