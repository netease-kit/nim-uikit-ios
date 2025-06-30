// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class FunLocalConversationController: NEBaseLocalConversationController {
  /// 搜索视图
  public lazy var searchView: FunSearchView = {
    let view = FunSearchView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.searchButton.setImage(coreLoader.loadImage("fun_search"), for: .normal)
    view.searchButton.setTitle(commonLocalizable("search"), for: .normal)
    view.searchButton.accessibilityIdentifier = "id.titleBarSearchImg"
    return view
  }()

  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    className = "FunLocalConversationController"
    deleteButtonBackgroundColor = .funConversationDeleteActionColor
    topButtonBackgroundColor = .funConversationTopActionColor
    cellRegisterDic = [0: FunLocalConversationListCell.self]
    stickTopCellRegisterDic = [0: FunStickTopCell.self]
    brokenNetworkViewHeight = 48
    brokenNetworkView.errorIconView.isHidden = false
    brokenNetworkView.backgroundColor = .funConversationNetworkBrokenBackgroundColor
    brokenNetworkView.contentLabel.textColor = .funConversationNetworkBrokenTitleColor
    emptyView.setEmptyImage(name: "fun_user_empty")
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .funConversationBackgroundColor
    navigationView.backgroundColor = .funConversationNavigationBg
    navigationView.titleBarBottomLine.isHidden = true
    changeLanguage()
    NotificationCenter.default.addObserver(self, selector: #selector(changeLanguage), name: NENotificationName.changeLanguage, object: nil)
  }

  override open func didMove(toParent parent: UIViewController?) {
    super.didMove(toParent: parent)
    if parent == nil {
      if let searchViewGestures = searchView.gestureRecognizers {
        for gesture in searchViewGestures {
          searchView.removeGestureRecognizer(gesture)
        }
      }
      NotificationCenter.default.removeObserver(self)
    }
  }

  func changeLanguage() {
    requestData()
    initSystemNav()
    popListView = FunPopListView()
    searchView.searchButton.setTitle(commonLocalizable("search"), for: .normal)
    brokenNetworkView.contentLabel.text = commonLocalizable("network_error")
  }

  override func initSystemNav() {
    super.initSystemNav()
    let addBarButton = UIButton()
    addBarButton.accessibilityIdentifier = "id.titleBarMoreImg"
    addBarButton.setImage(coreLoader.loadImage("nav_add"), for: .normal)
    addBarButton.addTarget(self, action: #selector(didClickAddBtn), for: .touchUpInside)
    let addBarItem = UIBarButtonItem(customView: addBarButton)

    navigationItem.rightBarButtonItems = [addBarItem]

    navigationView.brandBtn.setTitle(commonLocalizable("appName"), for: .normal)
    navigationView.searchBtn.isHidden = true
    if !LocalConversationUIConfig.shared.showTitleBarRightIcon {
      navigationItem.rightBarButtonItems = []
      navigationView.addBtn.isHidden = true
    }
  }

  override open func setupSubviews() {
    super.setupSubviews()

    let tap = UITapGestureRecognizer(target: self, action: #selector(searchAction))
    tap.cancelsTouchesInView = false
    searchView.addGestureRecognizer(tap)
    bodyTopView.addSubview(searchView)
    bodyTopViewHeight = 60
    NSLayoutConstraint.activate([
      searchView.topAnchor.constraint(equalTo: bodyTopView.topAnchor, constant: 12),
      searchView.leftAnchor.constraint(equalTo: bodyTopView.leftAnchor, constant: 8),
      searchView.rightAnchor.constraint(equalTo: bodyTopView.rightAnchor, constant: -8),
      searchView.heightAnchor.constraint(equalToConstant: 36),
    ])

    tableView.rowHeight = 72

    stickTopCollcetionView.frame = CGRect(x: 4, y: 0, width: view.frame.size.width - 8.0, height: 104)
  }

  override open func getPopListItems() -> [PopListItem] {
    weak var weakSelf = self
    var items = [PopListItem]()
    let addFriend = PopListItem()
    addFriend.showName = localizable("add_friend")
    addFriend.showNameColor = .white
    addFriend.image = .ne_imageNamed(name: "fun_add_friend")
    addFriend.completion = {
      Router.shared.use(
        ContactAddFriendRouter,
        parameters: ["nav": self.navigationController as Any],
        closure: nil
      )
    }
    items.append(addFriend)

    let joinTeam = PopListItem()
    joinTeam.showName = commonLocalizable("join_team")
    joinTeam.showNameColor = .white
    joinTeam.image = .ne_imageNamed(name: "fun_join_team")
    joinTeam.completion = {
      Router.shared.use(
        TeamJoinTeamRouter,
        parameters: ["nav": self.navigationController as Any],
        closure: nil
      )
    }
    items.append(joinTeam)

    let createDicuss = PopListItem()
    createDicuss.showName = localizable("create_discussion_group")
    createDicuss.showNameColor = .white
    createDicuss.image = .ne_imageNamed(name: "fun_create_discussion")
    createDicuss.completion = {
      weakSelf?.createDiscussGroup()
    }
    items.append(createDicuss)

    let createGroup = PopListItem()
    createGroup.showName = localizable("create_senior_group")
    createGroup.showNameColor = .white
    createGroup.image = .ne_imageNamed(name: "fun_create_team")
    createGroup.completion = {
      weakSelf?.createSeniorGroup()
    }
    items.append(createGroup)

    return items
  }

  /// 置顶cell大小
  override open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    CGSize(width: 72, height: 104)
  }

  /// 置顶显示隐藏(根据是否有置顶数据)
  open func setupFunStickTopView() {
    if viewModel.aiUserListData.count > 0 {
      if let headerView = tableView.tableHeaderView {
        if headerView.isKind(of: UICollectionView.self) == false {
          NEALog.infoLog(className(), desc: #function + " set top conversation header \(stickTopCollcetionView)")
          tableView.tableHeaderView = stickTopCollcetionView
        }
      } else {
        NEALog.infoLog(className(), desc: #function + " set top conversation header \(stickTopCollcetionView)")
        tableView.tableHeaderView = stickTopCollcetionView
      }
      stickTopCollcetionView.reloadData()
    } else {
      if tableView.tableHeaderView != nil {
        tableView.tableHeaderView = nil
      }
    }
  }

  override open func reloadTableView() {
    super.reloadTableView()
    NEALog.infoLog(className(), desc: #function + " reloadTableView in fun conversation controller stick top count \(viewModel.stickTopConversations.count)")
    setupFunStickTopView()
  }
}
