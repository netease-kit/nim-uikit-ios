// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import NECoreKit
import UIKit

@objc
public protocol NEBaseContactViewControllerDelegate {
  func onDataLoaded()
}

/// 通讯录页面 - 基类
@objcMembers
open class NEBaseContactViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, TabNavigationViewDelegate, ContactViewModelDelegate {
  public var delegate: NEBaseContactViewControllerDelegate?

  // custom ui cell
  public var cellRegisterDic = [Int: NEBaseContactTableViewCell.Type]()

  public var viewModel = ContactViewModel(contactHeaders: nil)
  private var lastTitleIndex = 0

  public var bodyTopViewHeight: CGFloat = 0 {
    didSet {
      bodyTopViewHeightAnchor?.constant = bodyTopViewHeight
      bodyTopView.isHidden = bodyTopViewHeight <= 0
    }
  }

  public var bodyBottomViewHeight: CGFloat = 0 {
    didSet {
      bodyBottomViewHeightAnchor?.constant = bodyBottomViewHeight
      bodyBottomView.isHidden = bodyBottomViewHeight <= 0
    }
  }

  public var topConstant: CGFloat = 0
  private var bodyTopViewHeightAnchor: NSLayoutConstraint?
  private var bodyBottomViewHeightAnchor: NSLayoutConstraint?

  public lazy var navigationView: TabNavigationView = {
    let nav = TabNavigationView(frame: CGRect.zero)
    nav.translatesAutoresizingMaskIntoConstraints = false
    nav.delegate = self

    if let addImg = NEKitContactConfig.shared.ui.titleBarRightRes {
      nav.addBtn.setImage(addImg, for: .normal)
    }
    if let searchImg = NEKitContactConfig.shared.ui.titleBarRight2Res {
      nav.searchBtn.setImage(searchImg, for: .normal)
    }
    return nav
  }()

  public lazy var bodyTopView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    return view
  }()

  public lazy var bodyView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    view.addSubview(contentView)

    NSLayoutConstraint.activate([
      contentView.topAnchor.constraint(equalTo: view.topAnchor),
      contentView.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentView.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    return view
  }()

  public lazy var contentView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    view.addSubview(tableView)
    view.addSubview(emptyView)

    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    NSLayoutConstraint.activate([
      emptyView.leftAnchor.constraint(equalTo: view.leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: view.rightAnchor),
      emptyView.topAnchor.constraint(equalTo: view.topAnchor, constant: NEConstant.screenWidth / 2),
      emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    return view
  }()

  public lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .grouped)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = UIColor.ne_backgroundColor
    tableView.sectionFooterHeight = 0
    tableView.sectionIndexColor = .ne_greyText
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

  lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(imageName: "user_empty", content: localizable("no_friend"), frame: .zero)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isUserInteractionEnabled = false
    view.backgroundColor = .clear
    view.isHidden = true
    return view
  }()

  public lazy var bodyBottomView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    return view
  }()

  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if navigationController?.viewControllers.count ?? 0 > 0 {
      if let root = navigationController?.viewControllers[0] as? UIViewController {
        if root.isKind(of: NEBaseContactViewController.self) {
          navigationController?.interactivePopGestureRecognizer?.delegate = self
        }
      }
    }

    if let useSystemNav = NEConfigManager.instance.getParameter(key: useSystemNav) as? Bool, useSystemNav {
      navigationController?.isNavigationBarHidden = false
    } else {
      navigationController?.isNavigationBarHidden = true
    }

    loadData()
    viewModel.getAddApplicationUnreadCount(nil)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    showTitleBar()
    commonUI()

    weak var weakSelf = self
    viewModel.delegate = self
    viewModel.refresh = {
      weakSelf?.didRefreshTable()
    }

    NotificationCenter.default.addObserver(self, selector: #selector(clearValidationUnreadCount), name: NENotificationName.clearValidationUnreadCount, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(clearValidationUnreadCount), name: UIApplication.didEnterBackgroundNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NENotificationName.friendCacheInit, object: nil)
  }

  /// 清除未读数
  func clearValidationUnreadCount() {
    viewModel.unreadCount = 0
  }

  open func showTitleBar() {
    if let useSystemNav = NEConfigManager.instance.getParameter(key: useSystemNav) as? Bool, useSystemNav {
      navigationView.isHidden = true
      topConstant = 0
      if NEKitContactConfig.shared.ui.showTitleBar {
        navigationController?.isNavigationBarHidden = false
      } else {
        navigationController?.isNavigationBarHidden = true
        if #available(iOS 10, *) {
          topConstant += NEConstant.statusBarHeight
        }
      }
    } else {
      navigationController?.isNavigationBarHidden = true
      if NEKitContactConfig.shared.ui.showTitleBar {
        navigationView.isHidden = false
        topConstant = NEConstant.navigationHeight
      } else {
        navigationView.isHidden = true
        topConstant = 0
      }
      if #available(iOS 10, *) {
        topConstant += NEConstant.statusBarHeight
      }
    }
  }

  /// UI初始化
  open func commonUI() {
    initSystemNav()
    view.addSubview(navigationView)
    view.addSubview(bodyTopView)
    view.addSubview(bodyView)
    view.addSubview(bodyBottomView)

    NSLayoutConstraint.activate([
      navigationView.topAnchor.constraint(equalTo: view.topAnchor),
      navigationView.leftAnchor.constraint(equalTo: view.leftAnchor),
      navigationView.rightAnchor.constraint(equalTo: view.rightAnchor),
      navigationView.heightAnchor
        .constraint(equalToConstant: NEConstant.navigationAndStatusHeight),
    ])

    NSLayoutConstraint.activate([
      bodyTopView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      bodyTopView.leftAnchor.constraint(equalTo: view.leftAnchor),
      bodyTopView.rightAnchor.constraint(equalTo: view.rightAnchor),
    ])
    bodyTopViewHeightAnchor = bodyTopView.heightAnchor.constraint(equalToConstant: bodyTopViewHeight)
    bodyTopViewHeightAnchor?.isActive = true

    NSLayoutConstraint.activate([
      bodyView.topAnchor.constraint(equalTo: bodyTopView.bottomAnchor),
      bodyView.leftAnchor.constraint(equalTo: view.leftAnchor),
      bodyView.rightAnchor.constraint(equalTo: view.rightAnchor),
      bodyView.bottomAnchor.constraint(equalTo: bodyBottomView.topAnchor),
    ])

    NSLayoutConstraint.activate([
      bodyBottomView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      bodyBottomView.leftAnchor.constraint(equalTo: view.leftAnchor),
      bodyBottomView.rightAnchor.constraint(equalTo: view.rightAnchor),
    ])
    bodyBottomViewHeightAnchor = bodyBottomView.heightAnchor.constraint(equalToConstant: bodyBottomViewHeight)
    bodyBottomViewHeightAnchor?.isActive = true

    if let customController = NEKitContactConfig.shared.ui.customController {
      customController(self)
    }
  }

  open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if let navigationController = navigationController,
       navigationController.responds(to: #selector(getter: UINavigationController.interactivePopGestureRecognizer)),
       gestureRecognizer == navigationController.interactivePopGestureRecognizer,
       navigationController.visibleViewController == navigationController.viewControllers.first {
      return false
    }
    return true
  }

  open func loadData() {
    viewModel.loadData { [weak self] error, userSectionCount in
      if error == nil {
        self?.delegate?.onDataLoaded()
        self?.didRefreshTable()
      }
    }
  }

  /// 重新加载数据
  func reloadData() {
    // 从缓存中取
    if !NEFriendUserCache.shared.isEmpty() {
      loadData()
    }
  }

  // UITableViewDataSource
  open func numberOfSections(in tableView: UITableView) -> Int {
    viewModel.contacts.count
  }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    NEALog.infoLog(ModuleName + " " + className(), desc: "contact section: \(section), count:\(viewModel.contacts[section].contacts.count)")

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

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let info = viewModel.contacts[indexPath.section].contacts[indexPath.row]

    if info.contactCellType == ContactCellType.ContactOthers.rawValue {
      if let headerItemClick = NEKitContactConfig.shared.ui.headerItemClick {
        headerItemClick(info, indexPath)
        return
      }

      switch info.router {
      case ValidationMessageRouter:
        Router.shared.use(ValidationMessageRouter,
                          parameters: ["nav": navigationController as Any],
                          closure: nil)

      case ContactBlackListRouter:
        Router.shared.use(ContactBlackListRouter,
                          parameters: ["nav": navigationController as Any],
                          closure: nil)

      case ContactTeamListRouter:
        // My Team
        Router.shared.use(ContactTeamListRouter,
                          parameters: ["nav": navigationController as Any],
                          closure: nil)

      case ContactPersonRouter:
        break

      case ContactComputerRouter:
        break

      default:
        if info.router.count > 0 {
          Router.shared.use(info.router,
                            parameters: ["nav": navigationController as Any],
                            closure: nil)
        }
      }
    } else {
      if let friendItemClick = NEKitContactConfig.shared.ui.friendItemClick {
        friendItemClick(info, indexPath)
        return
      }

      Router.shared.use(
        ContactUserInfoPageRouter,
        parameters: ["nav": navigationController as Any, "user": info.user as Any],
        closure: nil
      )
    }
  }

  func didRefreshTable() {
    tableView.reloadData()
    emptyView.isHidden = viewModel.getFriendSections().count > 0
  }

  public func reloadTableView() {
    didRefreshTable()
  }

  public func reloadTableView(_ index: IndexPath) {
    tableView.reloadData([index])
  }
}

extension NEBaseContactViewController {
  open func initSystemNav() {
    edgesForExtendedLayout = []
  }

  open func getFindFriendViewController() -> NEBaseFindFriendViewController {
    NEBaseFindFriendViewController()
  }

  @objc open func goToFindFriend() {
    let findFriendController = getFindFriendViewController()
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

  open func searchAction() {
    if let searchBlock = NEKitContactConfig.shared.ui.titleBarRight2Click {
      searchBlock()
      return
    }
    searchContact()
  }

  open func didClickAddBtn() {
    if let addBlock = NEKitContactConfig.shared.ui.titleBarRightClick {
      addBlock()
      return
    }
    goToFindFriend()
  }
}
