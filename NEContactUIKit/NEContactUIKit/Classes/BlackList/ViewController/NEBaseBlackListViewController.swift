
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECoreIM2Kit
import NECoreKit
import UIKit

@objcMembers
open class NEBaseBlackListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,
  BlackListCellDelegate, UIGestureRecognizerDelegate, BlackListViewModelDelegate {
  public let navigationView = NENavigationView()
  var tableView = UITableView(frame: .zero, style: .plain)
  var viewModel = BlackListViewModel()

  public lazy var headView: UIView = {
    let headView =
      UIView(frame: CGRect(x: 0, y: 0, width: Int(NEConstant.screenWidth), height: 40))
    return headView
  }()

  public lazy var contentLabel: UILabel = {
    let contentLabel =
      UILabel(frame: CGRect(x: 20, y: 0, width: Int(NEConstant.screenWidth) - 20, height: 40))
    contentLabel.text = localizable("black_tip")
    contentLabel.textColor = UIColor.ne_emptyTitleColor
    contentLabel.font = UIFont.systemFont(ofSize: 14)
    contentLabel.accessibilityIdentifier = "id.tips"
    return contentLabel
  }()

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    navigationController?.interactivePopGestureRecognizer?.delegate = self
    if let useSystemNav = NEConfigManager.instance.getParameter(key: useSystemNav) as? Bool, useSystemNav {
      navigationController?.isNavigationBarHidden = false
    } else {
      navigationController?.isNavigationBarHidden = true
    }

    viewModel.delegate = self
    commonUI()
    loadData()
  }

  /// UI 初始化
  func commonUI() {
    title = localizable("blacklist")
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

    let addImage = UIImage.ne_imageNamed(name: "add")?.withRenderingMode(.alwaysOriginal)
    let addItem = UIBarButtonItem(
      image: addImage,
      style: .plain,
      target: self,
      action: #selector(addBlack)
    )
    addItem.accessibilityIdentifier = "id.threePoint"
    navigationItem.rightBarButtonItem = addItem

    navigationView.translatesAutoresizingMaskIntoConstraints = false
    navigationView.addBackButtonTarget(target: self, selector: #selector(backEvent))
    navigationView.setMoreButtonImage(UIImage.ne_imageNamed(name: "add"))
    navigationView.addMoreButtonTarget(target: self, selector: #selector(addBlack))
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

    headView.addSubview(contentLabel)
    tableView.tableHeaderView = headView
  }

  func loadData() {
    viewModel.getBlackList()
    tableView.reloadData()
  }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.blockList.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    UITableViewCell()
  }

  func backEvent() {
    navigationController?.popViewController(animated: true)
  }

  open func getContactSelectVC() -> NEBaseContactsSelectedViewController {
    NEBaseContactsSelectedViewController()
  }

  func addBlack() {
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

  func addBlackUsers(users: [NEUserWithFriend]) {
    viewModel.addBlackList(users: users) { [weak self] error in
      if let err = error {
        self?.showToast(err.localizedDescription)
      }
    }
  }

  // MARK: BlackListCellDelegate

  func removeUser(account: String?, index: Int) {
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
  public func tableViewReload() {
    tableView.reloadData()
  }

  /// 重新加载单元格
  /// - Parameter indexs: 单元格位置
  public func tableViewReload(_ indexs: [IndexPath]) {
    tableView.reloadData(indexs)
  }

  /// 删除单元格
  /// - Parameter indexs: 单元格位置
  public func tableViewDelete(_ indexs: [IndexPath]) {
    tableView.deleteData(indexs)
  }

  /// 插入单元格
  /// - Parameter indexs: 单元格位置
  public func tableViewInsert(_ indexs: [IndexPath]) {
    tableView.insertData(indexs)
  }
}
