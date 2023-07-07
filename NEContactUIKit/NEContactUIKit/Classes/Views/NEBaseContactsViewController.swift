// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECoreIMKit
import NECoreKit

@objc
public protocol ContactsViewControllerDelegate {
  func onDataLoaded()
}

@objcMembers
open class NEBaseContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,
  SystemMessageProviderDelegate, FriendProviderDelegate, TabNavigationViewDelegate {
  public var delegate: ContactsViewControllerDelegate?

  // custom ui cell
  public var customCells = [Int: NEBaseContactTableViewCell.Type]()

  public var clickCallBacks = [Int: ContactClickCallBack]()
  var lastTitleIndex = 0

  public lazy var navView: TabNavigationView = {
    let nav = TabNavigationView(frame: CGRect.zero)
    nav.translatesAutoresizingMaskIntoConstraints = false
    nav.delegate = self
    return nav
  }()

  public var topConstant: CGFloat = 0

  public var topViewHeight: CGFloat = 0 {
    didSet {
      topViewHeightAnchor?.constant = topViewHeight
      topView.isHidden = topViewHeight <= 0
    }
  }

  public var topViewHeightAnchor: NSLayoutConstraint?
  public lazy var topView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    return view
  }()

  public lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .grouped)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = UIColor.ne_backgroundColor
    tableView.rowHeight = 52
    tableView.sectionHeaderHeight = 40
    tableView.sectionFooterHeight = 0
    tableView.sectionIndexColor = .ne_greyText

    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
    return tableView
  }()

  lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(imageName: "user_empty", content: localizable("no_friend"), frame: .zero)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    view.isHidden = true
    return view
  }()

  public var viewModel = ContactViewModel(contactHeaders: nil)
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nil, bundle: nil)
    viewModel.contactRepo.addNotificationDelegate(delegate: self)
    viewModel.contactRepo.addContactDelegate(delegate: self)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    if let useSystemNav = NEConfigManager.instance.getParameter(key: useSystemNav) as? Bool, useSystemNav {
      navigationController?.isNavigationBarHidden = false
      topConstant = 0
    } else {
      navigationController?.isNavigationBarHidden = true
      topConstant = NEConstant.navigationAndStatusHeight
      view.addSubview(navView)
      NSLayoutConstraint.activate([
        navView.topAnchor.constraint(equalTo: view.topAnchor),
        navView.leftAnchor.constraint(equalTo: view.leftAnchor),
        navView.rightAnchor.constraint(equalTo: view.rightAnchor),
        navView.heightAnchor
          .constraint(equalToConstant: NEConstant.navigationAndStatusHeight),
      ])
    }
    commonUI()
    viewModel.refresh = { [weak self] in
      self?.tableView.reloadData()
    }
  }

  override open func viewWillAppear(_ animated: Bool) {
    // 刷新数据
    viewModel.reLoadData { [weak self] error, userSectionCount in
      self?.emptyView.isHidden = userSectionCount > 0
      if error == nil {
        self?.delegate?.onDataLoaded()
        self?.tableView.reloadData()
      }
    }
  }

  open func commonUI() {
    initSystemNav()

    view.addSubview(topView)
    topViewHeightAnchor = topView.heightAnchor.constraint(equalToConstant: topViewHeight)
    topViewHeightAnchor?.isActive = true

    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.topAnchor.constraint(equalTo: topView.bottomAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.leftAnchor.constraint(equalTo: view.leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: view.rightAnchor),
      emptyView.topAnchor.constraint(equalTo: view.topAnchor, constant: NEConstant.screenHeight / 2),
      emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  open func loadData() {
    viewModel.loadData { [weak self] error, userSectionCount in
      self?.emptyView.isHidden = userSectionCount > 0
      if error == nil {
        self?.delegate?.onDataLoaded()
        self?.tableView.reloadData()
      }
    }
  }

  // UITableViewDataSource
  open func numberOfSections(in tableView: UITableView) -> Int {
    viewModel.contacts.count
  }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    NELog.infoLog(ModuleName + " " + className(), desc: "contact section: \(section), count:\(viewModel.contacts[section].contacts.count)")

    return viewModel.contacts[section].contacts.count
  }

  open func configCell(info: ContactInfo, _ cell: NEBaseContactTableViewCell, _ indexPath: IndexPath) -> UITableViewCell {
    cell.setModel(info)
    if indexPath.section == 0, indexPath.row == 0, viewModel.unreadCount > 0 {
      cell.redAngleView.isHidden = false
      cell.redAngleView.text = viewModel.unreadCount > 99 ? "99+" : "\(viewModel.unreadCount)"
    } else {
      cell.redAngleView.isHidden = true
    }
    return cell
  }

  // 具体逻辑在子类实现
  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    UITableViewCell()
  }

  open func tableView(_ tableView: UITableView,
                      viewForHeaderInSection section: Int) -> UIView? {
    let sectionView: ContactSectionView = tableView
      .dequeueReusableHeaderFooterView(
        withIdentifier: "\(NSStringFromClass(ContactSectionView.self))"
      ) as! ContactSectionView
    sectionView.titleLabel.text = viewModel.contacts[section].initial
    return sectionView
  }

  open func tableView(_ tableView: UITableView,
                      heightForHeaderInSection section: Int) -> CGFloat {
    if viewModel.contacts[section].initial.count > 0 {
      return 40
    }
    return 0
  }

  open func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    viewModel.indexs
  }

  open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String,
                      at index: Int) -> Int {
    for (i, t) in viewModel.contacts.enumerated() {
      if t.initial == title {
        lastTitleIndex = i
        return i
      }
    }
    return lastTitleIndex
  }

  open func tableView(_ tableView: UITableView,
                      heightForRowAt indexPath: IndexPath) -> CGFloat {
    52
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}

//    MARK: SystemMessageProviderDelegate

  open func onRecieveNotification(notification: XNotification) {
    print("onRecieveNotification type:\(notification.type)")
    if notification.type == .addFriendDirectly {
      loadData()
    }
  }

  open func onNotificationUnreadCountChanged(count: Int) {
    print("unread count:\(count)")
  }

//    MARK: FriendProviderDelegate

  open func onFriendChanged(user: User) {
    print("onFriendChanged:\(user.userId)")
    loadData()
  }

  open func onBlackListChanged() {
    print("onBlackListChanged")
    loadData()
  }

  open func onUserInfoChanged(user: User) {
    print("onUserInfoChanged:\(user.userId)")
    loadData()
  }

  open func onReceive(_ notification: NIMCustomSystemNotification) {}
}

extension NEBaseContactsViewController {
  open func initSystemNav() {
    edgesForExtendedLayout = []
  }

  open func getFindFriendViewController() -> NEBaseFindFriendViewController {
    NEBaseFindFriendViewController()
  }

  @objc open func goToFindFriend() {
    let findFriendController = getFindFriendViewController()
    findFriendController.hidesBottomBarWhenPushed = true
    navigationController?.pushViewController(findFriendController, animated: true)
  }

  @objc open func searchContact() {
    Router.shared.use(
      SearchContactPageRouter,
      parameters: ["nav": navigationController as Any],
      closure: nil
    )
  }

  // MARK: TabNavigationViewDelegate

  public func searchAction() {
    searchContact()
  }

  public func didClickAddBtn() {
    goToFindFriend()
  }
}
