
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit
import NEBaseUIKit

@objcMembers
open class NEBaseBlackListViewController: NEContactBaseViewController, UITableViewDelegate, UITableViewDataSource,
  BlackListCellDelegate, BlackListViewModelDelegate {
  var viewModel = BlackListViewModel()
  public var tableViewTopAnchor: NSLayoutConstraint?

  public lazy var headView: UIView = {
    let headView = UIView(frame: CGRect(x: 0, y: 0, width: NEAdaptiveDeviceGate.isFoldableDevice ? 0 : NEConstant.screenWidth, height: 40))
    if NEAdaptiveDeviceGate.isFoldableDevice { headView.autoresizingMask = [.flexibleWidth] }
    headView.addSubview(contentLabel)
    if NEAdaptiveDeviceGate.isFoldableDevice {
      contentLabel.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      contentLabel.leadingAnchor.constraint(equalTo: headView.leadingAnchor, constant: 20),
      contentLabel.trailingAnchor.constraint(equalTo: headView.trailingAnchor),
      contentLabel.topAnchor.constraint(equalTo: headView.topAnchor),
      contentLabel.bottomAnchor.constraint(equalTo: headView.bottomAnchor),
      ])
    }
    return headView
  }()

  public lazy var contentLabel: UILabel = {
    let contentLabel = UILabel(frame: NEAdaptiveDeviceGate.isFoldableDevice
      ? .zero : CGRect(x: 20, y: 0, width: NEConstant.screenWidth - 20, height: 40))
    contentLabel.text = localizable("black_tip")
    contentLabel.textColor = UIColor.ne_emptyTitleColor
    contentLabel.font = UIFont.systemFont(ofSize: 14)
    contentLabel.accessibilityIdentifier = "id.tips"
    return contentLabel
  }()

  lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.tableHeaderView = headView
    tableView.keyboardDismissMode = .onDrag

    tableView.estimatedRowHeight = 0
    tableView.estimatedSectionHeaderHeight = 0
    tableView.estimatedSectionFooterHeight = 0

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
    if let useSystemNav = NEConfigManager.instance.getParameter(key: useSystemNav) as? Bool, useSystemNav {
      navigationController?.isNavigationBarHidden = false
    } else {
      navigationController?.isNavigationBarHidden = true
    }

    viewModel.delegate = self
    commonUI()
    loadData()
  }

  open func initNav() {
    let image = CommonUIConfig.shared.backArrowImage?.withRenderingMode(.alwaysOriginal)
    let backItem = UIBarButtonItem(
      image: image,
      style: .plain,
      target: self,
      action: #selector(backEvent)
    )
    backItem.accessibilityIdentifier = "id.backArrow"
    navigationItem.leftBarButtonItem = backItem

    let addImage = UIImage.ne_imageNamed(name: "add_black")?.withRenderingMode(.alwaysOriginal)
    let addItem = UIBarButtonItem(
      image: addImage,
      style: .plain,
      target: self,
      action: #selector(toSetting)
    )
    addItem.accessibilityIdentifier = "id.threePoint"
    navigationItem.rightBarButtonItem = addItem

    navigationView.setMoreButtonImage(UIImage.ne_imageNamed(name: "add_black"))
  }

  /// UI 初始化
  open func commonUI() {
    title = localizable("blacklist")
    initNav()

    view.addSubview(tableView)
    tableViewTopAnchor = tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: NEConstant.navigationAndStatusHeight)
    tableViewTopAnchor?.isActive = true
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    emptyView.setText(localizable("no_blacklist"))
    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.topAnchor.constraint(equalTo: tableView.topAnchor),
      emptyView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
      emptyView.leftAnchor.constraint(equalTo: tableView.leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: tableView.rightAnchor),
    ])
  }

  open func loadData() {
    viewModel.getBlackList()
    tableView.reloadData()
    emptyView.isHidden = !viewModel.blockList.isEmpty
  }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.blockList.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    UITableViewCell()
  }

  open func getContactSelectVC() -> NEBaseContactSelectedViewController {
    NEBaseContactSelectedViewController()
  }

  override open func toSetting() {
    let contactSelectVC = getContactSelectVC()
    navigationController?.pushViewController(contactSelectVC, animated: true)
    contactSelectVC.callBack = { [weak self] selectMemberarray in
      var users = [NEUserWithFriend]()
      for memberInfo in selectMemberarray {
        if let u = memberInfo.user {
          users.append(u)
        }
      }
      self?.addBlackUsers(users: users)
    }
  }

  open func addBlackUsers(users: [NEUserWithFriend]) {
    viewModel.addBlackList(users: users) { [weak self] error in
      if let err = error {
        self?.showToast(err.localizedDescription)
      }
    }
  }

  // MARK: BlackListCellDelegate

  open func removeUser(account: String?, index: Int) {
    weak var weakSelf = self
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      weakSelf?.showToast(commonLocalizable("network_error"))
      return
    }

    guard let acc = account else {
      return
    }

    viewModel.removeFromBlackList(account: acc) { [weak self] error in
      if let err = error {
        self?.showToast(err.localizedDescription)
      }
    }
  }

  // MARK: BlackListViewModelDelegate

  /// 重新加载表格
  open func tableViewReload() {
    tableView.reloadData()
    emptyView.isHidden = !viewModel.blockList.isEmpty
  }
}
