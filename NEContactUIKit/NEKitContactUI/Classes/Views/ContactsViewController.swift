
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitCoreIM
import NEKitCore

open class ContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,
  SystemMessageProviderDelegate, FriendProviderDelegate {
  public var customCells: [Int: ContactTableViewCell.Type] = [
    ContactCellType.ContactPerson.rawValue: ContactTableViewCell.self,
    ContactCellType.ContactOthers.rawValue: ContactTableViewCell.self,
  ] // custom ui cell

  public var clickCallBacks = [Int: ConttactClickCallBack]()

  var tableView = UITableView(frame: .zero, style: .grouped)
  var viewModel = ContactViewModel(contactHeaders: [
    ContactHeadItem(
      name: "验证消息",
      imageName: "valid",
      router: ValidationMessageRouter,
      color: UIColor(hexString: "#60CFA7")
    ),
    ContactHeadItem(
      name: "黑名单",
      imageName: "blackName",
      router: ContactBlackListRouter,
      color: UIColor(hexString: "#53C3F3")
    ),
    ContactHeadItem(
      name: "我的群聊",
      imageName: "group",
      router: ContactGroupRouter,
      color: UIColor(hexString: "#BE65D9")
    ),
  ])

  @objc
  public init() {
    super.init(nibName: nil, bundle: nil)
    viewModel.contactRepo.addNotificationDelegate(delegate: self)
    viewModel.contactRepo.addContactDelegate(delegate: self)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  @objc
  override public func viewDidLoad() {
    super.viewDidLoad()
    weak var weakSelf = self
    viewModel.refresh = {
      weakSelf?.tableView.reloadData()
    }
    addNavbarAction()
    commonUI()
  }

  override public func viewWillAppear(_ animated: Bool) {
    loadData()
  }

  @objc
  func commonUI() {
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
      ContactTableViewCell.self,
      forCellReuseIdentifier: "\(ContactTableViewCell.self)"
    )
    tableView.register(
      ContactSectionView.self,
      forHeaderFooterViewReuseIdentifier: "\(NSStringFromClass(ContactSectionView.self))"
    )
    tableView.rowHeight = 52
    tableView.sectionHeaderHeight = 40
    tableView.sectionFooterHeight = 0
    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
  }

  func loadData() {
    viewModel.loadData()
    tableView.reloadData()
  }

  // UITableViewDataSource
  public func numberOfSections(in tableView: UITableView) -> Int {
    viewModel.contacts.count
  }

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.contacts[section].contacts.count
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let info = viewModel.contacts[indexPath.section].contacts[indexPath.row]
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(ContactTableViewCell.self)",
      for: indexPath
    ) as! ContactTableViewCell
    cell.setModel(info)
    if indexPath.section == 0, indexPath.row == 0, viewModel.unreadCount > 0 {
      cell.redAngleView.isHidden = false
      cell.redAngleView.text = "\(viewModel.unreadCount)"
    } else {
      cell.redAngleView.isHidden = true
    }
    return cell
  }

  public func tableView(_ tableView: UITableView,
                        viewForHeaderInSection section: Int) -> UIView? {
    let sectionView: ContactSectionView = tableView
      .dequeueReusableHeaderFooterView(
        withIdentifier: "\(NSStringFromClass(ContactSectionView.self))"
      ) as! ContactSectionView
    sectionView.titleLabel.text = viewModel.contacts[section].initial
    return sectionView
  }

  public func tableView(_ tableView: UITableView,
                        heightForHeaderInSection section: Int) -> CGFloat {
    if viewModel.contacts[section].initial.count > 0 {
      return 40
    }
    return 0
  }

  public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    viewModel.indexs
  }

  public func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String,
                        at index: Int) -> Int {
    index
  }

  public func tableView(_ tableView: UITableView,
                        heightForRowAt indexPath: IndexPath) -> CGFloat {
    52
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let info = viewModel.contacts[indexPath.section].contacts[indexPath.row]
    if let callBack = clickCallBacks[info.contactCellType] {
      callBack(indexPath.row, indexPath.section)
      return
    }
    if info.contactCellType == ContactCellType.ContactOthers.rawValue {
      switch info.router {
      case ValidationMessageRouter:
        viewModel.contactRepo.clearNotificationUnreadCount()
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
//                select.callBack = { contacts in
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
  }

  public func onUserInfoChanged(user: User) {
    print("onUserInfoChanged:\(user.userId)")
    loadData()
  }

  public func onReceive(_ notification: NIMCustomSystemNotification) {}
}

extension ContactsViewController {
  private func addNavbarAction() {
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
