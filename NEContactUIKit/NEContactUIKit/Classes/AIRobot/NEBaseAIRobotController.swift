// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonUIKit
import NECoreKit
import UIKit

@objcMembers
open class NEBaseAIRobotController: NEContactBaseViewController, UITableViewDelegate, UITableViewDataSource {
  let viewModel = AIRobotViewModel()

  /// 机器人列表
  public lazy var robotTableView: UITableView = {
    let tableView = UITableView()
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .clear
    tableView.separatorColor = .clear
    tableView.separatorStyle = .none
    tableView.sectionHeaderHeight = 12.0
    tableView.dataSource = self
    tableView.delegate = self
    tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 12))
    tableView.keyboardDismissMode = .onDrag
    tableView.estimatedRowHeight = 0
    tableView.estimatedSectionHeaderHeight = 0
    tableView.estimatedSectionFooterHeight = 0
    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }
    return tableView
  }()

  /// 无机器人空占位图
  public lazy var robotEmptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(imageName: "user_empty", content: localizable("no_ai_robot"), frame: .zero)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    return view
  }()

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
    }
    viewModel.getRobots { [weak self] error in
      self?.refreshTableView()
    }
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupRobotListUI()
    navigationView.moreButton.isHidden = true
    navigationView.setMoreButtonImage(UIImage.ne_imageNamed(name: "add_black"))
    navigationView.addMoreButtonTarget(target: self, selector: #selector(didTapCreateRobot))
  }

  /// 点击创建按钮 — 子类可 override 跳转到对应皮肤的创建页
  open func didTapCreateRobot() {
    let maxCount = AIRobotViewModel.maxRobotCount
    if viewModel.datas.count >= maxCount {
      showToast(localizable("ai_robot_exceed_limit"))
      return
    }
    let defaultName = "Bot_Claw"
    Router.shared.use(ContactCreateAIRobotRouter,
                      parameters: ["nav": navigationController as Any,
                                   "animated": true,
                                   "defaultName": defaultName],
                      closure: nil)
  }

  /// UI 初始化
  open func setupRobotListUI() {
    title = localizable("my_ai_robot")

    view.addSubview(robotTableView)
    NSLayoutConstraint.activate([
      robotTableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      robotTableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      robotTableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      robotTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    robotTableView.register(NEBaseAIRobotListCell.self, forCellReuseIdentifier: "\(NEBaseAIRobotListCell.self)")

    view.addSubview(robotEmptyView)
    NSLayoutConstraint.activate([
      robotEmptyView.leftAnchor.constraint(equalTo: robotTableView.leftAnchor),
      robotEmptyView.rightAnchor.constraint(equalTo: robotTableView.rightAnchor),
      robotEmptyView.topAnchor.constraint(equalTo: robotTableView.topAnchor, constant: 50),
      robotEmptyView.bottomAnchor.constraint(equalTo: robotTableView.bottomAnchor),
    ])
  }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.datas.count
  }

  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    UITableViewCell()
  }

  open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    0
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    guard indexPath.row < viewModel.datas.count,
          let bot = viewModel.datas[indexPath.row].bot else { return }
    Router.shared.use(ContactAIRobotDetailRouter,
                      parameters: ["nav": navigationController as Any,
                                   "bot": bot,
                                   "animated": true],
                      closure: nil)
  }

  /// 判断是否为最后一条
  open func isLastRobot(_ index: Int) -> Bool {
    viewModel.datas.count - 1 == index
  }

  /// 刷新数据列表
  open func refreshTableView() {
    robotTableView.reloadData()
    robotEmptyView.isHidden = !viewModel.datas.isEmpty
  }
}
