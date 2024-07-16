// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class FunConversationController: NEBaseConversationController {
  /// 搜索视图
  public lazy var searchView: FunSearchView = {
    let view = FunSearchView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.searchButton.setImage(UIImage.ne_imageNamed(name: "funSearch"), for: .normal)
    view.searchButton.setTitle(commonLocalizable("search"), for: .normal)
    view.searchButton.accessibilityIdentifier = "id.titleBarSearchImg"
    return view
  }()

  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    className = "FunConversationController"
    deleteButtonBackgroundColor = .funConversationdeleteActionColor
    cellRegisterDic = [0: FunConversationListCell.self]
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
    navigationView.backgroundColor = .funConversationBackgroundColor
    navigationView.titleBarBottomLine.isHidden = true
  }

  deinit {
    if let searchViewGestures = searchView.gestureRecognizers {
      for gesture in searchViewGestures {
        searchView.removeGestureRecognizer(gesture)
      }
    }
  }

  override func initSystemNav() {
    super.initSystemNav()
    let addBarButton = UIButton()
    addBarButton.accessibilityIdentifier = "id.titleBarMoreImg"
    addBarButton.setImage(UIImage.ne_imageNamed(name: "chat_add"), for: .normal)
    addBarButton.addTarget(self, action: #selector(didClickAddBtn), for: .touchUpInside)
    let addBarItem = UIBarButtonItem(customView: addBarButton)

    navigationItem.rightBarButtonItems = [addBarItem]

    navigationView.searchBtn.isHidden = true
    if !NEKitConversationConfig.shared.ui.showTitleBarRightIcon {
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

    popListView = FunPopListView()

    tableView.rowHeight = 72
    tableView.backgroundColor = .funConversationBackgroundColor

    stickTopCollcetionView.frame = CGRect(x: 4, y: 0, width: view.frame.size.width - 8.0, height: 104)
  }

  override open func getPopListItems() -> [PopListItem] {
    let items = super.getPopListItems()
    let addFriend = items[0]
    addFriend.showNameColor = .white
    addFriend.image = UIImage.ne_imageNamed(name: "funAddFriend")

    let createGroup = items[1]
    createGroup.showNameColor = .white
    createGroup.image = UIImage.ne_imageNamed(name: "funCreateTeam")

    let createDicuss = items[2]
    createDicuss.showNameColor = .white
    createDicuss.image = UIImage.ne_imageNamed(name: "funCreateTeam")

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
