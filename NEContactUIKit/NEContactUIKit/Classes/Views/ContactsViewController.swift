
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECoreIMKit
import NECoreKit

public protocol ContactsViewControllerDelegate {
  func onDataLoaded()
}

@objcMembers
open class ContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,
  SystemMessageProviderDelegate, FriendProviderDelegate {
  public var delegate: ContactsViewControllerDelegate?

  // custom ui cell
  public var customCells: [Int: ContactTableViewCell.Type] = [
    ContactCellType.ContactPerson.rawValue: ContactTableViewCell.self,
    ContactCellType.ContactOthers.rawValue: ContactTableViewCell.self,
  ]

  public var clickCallBacks = [Int: ConttactClickCallBack]()
  var lastTitleIndex = 0

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
    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
    return tableView
  }()

  public var viewModel = ContactViewModel(contactHeaders: [
    ContactHeadItem(
      name: localizable("validation_message"),
      imageName: "valid",
      router: ValidationMessageRouter,
      color: UIColor(hexString: "#60CFA7")
    ),
    ContactHeadItem(
      name: localizable("blacklist"),
      imageName: "blackName",
      router: ContactBlackListRouter,
      color: UIColor(hexString: "#53C3F3")
    ),
    ContactHeadItem(
      name: localizable("mine_groupchat"),
      imageName: "group",
      router: ContactGroupRouter,
      color: UIColor(hexString: "#BE65D9")
    ),
  ])
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
    weak var weakSelf = self
    viewModel.refresh = {
      weakSelf?.tableView.reloadData()
    }

    // 添加UI
    addNavbarAction()
    commonUI()
  }

  override open func viewWillAppear(_ animated: Bool) {
    // 刷新数据
    viewModel.reLoadData { [weak self] error in
      if error == nil {
        self?.delegate?.onDataLoaded()
        self?.tableView.reloadData()
      }
    }
  }

  open func commonUI() {
    view.addSubview(topView)
    NSLayoutConstraint.activate([
      topView.topAnchor.constraint(equalTo: view.topAnchor),
      topView.leftAnchor.constraint(equalTo: view.leftAnchor),
      topView.rightAnchor.constraint(equalTo: view.rightAnchor),
    ])
    topViewHeightAnchor = topView.heightAnchor.constraint(equalToConstant: topViewHeight)
    topViewHeightAnchor?.isActive = true

    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.topAnchor.constraint(equalTo: topView.bottomAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    tableView.register(
      ContactSectionView.self,
      forHeaderFooterViewReuseIdentifier: "\(NSStringFromClass(ContactSectionView.self))"
    )

    customCells.forEach { (key: Int, value: ContactTableViewCell.Type) in
      tableView.register(value, forCellReuseIdentifier: "\(key)")
    }
  }

  open func loadData() {
    viewModel.loadData { [weak self] error in
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

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let info = viewModel.contacts[indexPath.section].contacts[indexPath.row]
    var reusedId = "\(info.contactCellType)"
    let cell = tableView.dequeueReusableCell(withIdentifier: reusedId, for: indexPath)

    if let c = cell as? ContactTableViewCell {
      c.setModel(info)
      if indexPath.section == 0, indexPath.row == 0, viewModel.unreadCount > 0 {
        c.redAngleView.isHidden = false
        c.redAngleView.text = viewModel.unreadCount > 99 ? "99+" : "\(viewModel.unreadCount)"
      } else {
        c.redAngleView.isHidden = true
      }
    }
    return cell
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

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let info = viewModel.contacts[indexPath.section].contacts[indexPath.row]
    if let callBack = clickCallBacks[info.contactCellType] {
      callBack(indexPath.row, indexPath.section)
      return
    }
    if info.contactCellType == ContactCellType.ContactOthers.rawValue {
      switch info.router {
      case ValidationMessageRouter:
        let validationController = ValidationMessageViewController()
        validationController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(validationController, animated: true)
      case ContactBlackListRouter:
        let blackVC = BlackListViewController()
        blackVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(blackVC, animated: true)

      case ContactGroupRouter:
        // My Team
        let teamVC = TeamListViewController()
        teamVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(teamVC, animated: true)

      case ContactPersonRouter:

        break

      case ContactComputerRouter:
//                let select = ContactsSelectedViewController()
//                select.CallBack = { contacts in
//                    print("select contacs : ", contacts)
//                }
//                select.hidesBottomBarWhenPushed = true
//                self.navigationController?.pushViewController(select, animated: true)
        break
      default:
        break
      }
    } else {
      let userInfoVC = ContactUserViewController(user: info.user)
      userInfoVC.hidesBottomBarWhenPushed = true
      navigationController?.pushViewController(userInfoVC, animated: true)
    }
  }

//    MARK: SystemMessageProviderDelegate

  public func onRecieveNotification(notification: XNotification) {
    print("onRecieveNotification type:\(notification.type)")
    if notification.type == .addFriendDirectly {
      loadData()
    }
  }

  public func onNotificationUnreadCountChanged(count: Int) {
    print("unread count:\(count)")
  }

//    MARK: FriendProviderDelegate

  public func onFriendChanged(user: User) {
    print("onFriendChanged:\(user.userId)")
    loadData()
  }

  public func onBlackListChanged() {
    print("onBlackListChanged")
    loadData()
  }

  public func onUserInfoChanged(user: User) {
    print("onUserInfoChanged:\(user.userId)")
    loadData()
  }

  public func onReceive(_ notification: NIMCustomSystemNotification) {}
}

extension ContactsViewController {
  open func addNavbarAction() {
    edgesForExtendedLayout = []
    let addItem = UIBarButtonItem(
      image: UIImage.ne_imageNamed(name: "add"),
      style: .plain,
      target: self,
      action: #selector(goToFindFriend)
    )
    addItem.tintColor = UIColor(hexString: "333333")
    let searchItem = UIBarButtonItem(
      image: UIImage.ne_imageNamed(name: "contact_search"),
      style: .plain,
      target: self,
      action: #selector(searchContact)
    )
    searchItem.imageInsets = UIEdgeInsets(top: 0, left: 35, bottom: 0, right: 0)
    searchItem.tintColor = UIColor(hexString: "333333")
    if NEKitContactConfig.shared.ui.hiddenRightBtns {
      return
    } else {
      if NEKitContactConfig.shared.ui.hiddenSearchBtn {
        navigationItem.rightBarButtonItems = [addItem]
      } else {
        navigationItem.rightBarButtonItems = [addItem, searchItem]
      }
    }
  }

  @objc private func goToFindFriend() {
    let findFriendController = FindFriendViewController()
    findFriendController.hidesBottomBarWhenPushed = true
    navigationController?.pushViewController(findFriendController, animated: true)
  }

  @objc private func searchContact() {
    Router.shared.use(
      SearchContactPageRouter,
      parameters: ["nav": navigationController as Any],
      closure: nil
    )
  }
}
