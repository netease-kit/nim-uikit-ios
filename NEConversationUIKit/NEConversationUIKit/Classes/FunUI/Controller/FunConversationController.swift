// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class FunConversationController: NEBaseConversationController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    listCtrl = FunConversationListViewController()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public lazy var searchView: FunSearchView = {
    let view = FunSearchView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.searchBotton.setImage(UIImage.ne_imageNamed(name: "funSearch"), for: .normal)
    view.searchBotton.setTitle(localizable("search"), for: .normal)
    return view
  }()

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .funConversationBackgroundColor
    navView.backgroundColor = .funConversationBackgroundColor
    navView.bottomLine.isHidden = true
  }

  deinit {
    if let searchViewGestures = searchView.gestureRecognizers {
      searchViewGestures.forEach { gesture in
        searchView.removeGestureRecognizer(gesture)
      }
    }
  }

  override func initSystemNav() {
    super.initSystemNav()
    let addBarButton = UIButton()
    addBarButton.setImage(UIImage.ne_imageNamed(name: "chat_add"), for: .normal)
    addBarButton.addTarget(self, action: #selector(didClickAddBtn), for: .touchUpInside)
    let addBarItem = UIBarButtonItem(customView: addBarButton)

    navigationItem.rightBarButtonItems = [addBarItem]

    navView.searchBtn.isHidden = true
    if NEKitConversationConfig.shared.ui.hiddenRightBtns {
      navigationItem.rightBarButtonItems = []
      navView.addBtn.isHidden = true
    }
  }

  override open func setupSubviews() {
    super.setupSubviews()
    let tap = UITapGestureRecognizer(target: self, action: #selector(searchAction))
    tap.cancelsTouchesInView = false
    searchView.addGestureRecognizer(tap)
    view.addSubview(searchView)
    NSLayoutConstraint.activate([
      searchView.topAnchor.constraint(equalTo: navView.bottomAnchor, constant: 12),
      searchView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8),
      searchView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8),
      searchView.heightAnchor.constraint(equalToConstant: 36),
    ])

    NSLayoutConstraint.activate([
      listCtrl.view.topAnchor.constraint(equalTo: searchView.bottomAnchor, constant: 12),
      listCtrl.view.leftAnchor.constraint(equalTo: view.leftAnchor),
      listCtrl.view.rightAnchor.constraint(equalTo: view.rightAnchor),
      listCtrl.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  // MARK: lazyMethod

  public lazy var popListController: FunPopListViewController = {
    let popController = FunPopListViewController()
    popController.popView.backgroundColor = UIColor.funConversationPopViewBg
    return popController
  }()
}

extension FunConversationController {
  override open func searchAction() {
    let searchVC = FunConversationSearchController()
    navigationController?.pushViewController(searchVC, animated: true)
  }

  override open func didClickAddBtn() {
    print("add click")

    if children.contains(popListController) == false {
      popListController.itemDatas = getPopListItems()
      addChild(popListController)
      popListController.view.frame = view.frame
    }
    if popListController.view.superview != nil {
      popListController.removeSelf()
    } else {
      view.addSubview(popListController.view)
    }
  }

  open func getPopListItems() -> [PopListItem] {
    weak var weakSelf = self
    var items = [PopListItem]()
    let addFriend = PopListItem()
    addFriend.showName = localizable("add_friend")
    addFriend.showNameColor = .white
    addFriend.image = UIImage.ne_imageNamed(name: "funAddFriend")
    addFriend.completion = {
      Router.shared.use(
        ContactAddFriendRouter,
        parameters: ["nav": self.navigationController as Any]
      ) { obj, routerState, str in
      }
    }
    items.append(addFriend)

    let createGroup = PopListItem()
    createGroup.showName = localizable("create_discussion_group")
    createGroup.showNameColor = .white
    createGroup.image = UIImage.ne_imageNamed(name: "funCreateTeam")
    createGroup.completion = {
      weakSelf?.createDiscussGroup()
    }
    items.append(createGroup)

    let createDicuss = PopListItem()
    createDicuss.showName = localizable("create_senior_group")
    createDicuss.showNameColor = .white
    createDicuss.image = UIImage.ne_imageNamed(name: "funCreateTeam")
    createDicuss.completion = {
      weakSelf?.createSeniorGroup()
    }
    items.append(createDicuss)

    return items
  }
}
