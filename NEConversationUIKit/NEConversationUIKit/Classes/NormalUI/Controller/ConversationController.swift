
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class ConversationController: NEBaseConversationController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    listCtrl = ConversationListViewController()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor(hexString: "#e9eff5")
  }

  override func initSystemNav() {
    super.initSystemNav()
    let searchBarButton = UIButton()
    searchBarButton.accessibilityIdentifier = "id.titleBarSearchImg"
    searchBarButton.setImage(UIImage.ne_imageNamed(name: "chat_search"), for: .normal)
    searchBarButton.addTarget(self, action: #selector(searchAction), for: .touchUpInside)
    let searchBarItem = UIBarButtonItem(customView: searchBarButton)

    let addBarButton = UIButton()
    addBarButton.accessibilityIdentifier = "id.titleBarMoreImg"
    addBarButton.setImage(UIImage.ne_imageNamed(name: "chat_add"), for: .normal)
    addBarButton.addTarget(self, action: #selector(didClickAddBtn), for: .touchUpInside)
    let addBarItem = UIBarButtonItem(customView: addBarButton)

    let spaceBarItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
    spaceBarItem.width = NEConstant.screenInterval

    navigationItem.rightBarButtonItems = [addBarItem, spaceBarItem, searchBarItem]
    if NEKitConversationConfig.shared.ui.hiddenSearchBtn {
      navView.searchBtn.isHidden = true
      navigationItem.rightBarButtonItems = [addBarItem]
    }
    if NEKitConversationConfig.shared.ui.hiddenRightBtns {
      navigationItem.rightBarButtonItems = []
      navView.searchBtn.isHidden = true
      navView.addBtn.isHidden = true
    }
  }

  override open func setupSubviews() {
    super.setupSubviews()
    NSLayoutConstraint.activate([
      listCtrl.view.topAnchor.constraint(equalTo: navView.bottomAnchor),
      listCtrl.view.leftAnchor.constraint(equalTo: view.leftAnchor),
      listCtrl.view.rightAnchor.constraint(equalTo: view.rightAnchor),
      listCtrl.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  deinit {}

  // MARK: lazyMethod

  public lazy var popListController: PopListViewController = {
    let popController = PopListViewController()
    return popController
  }()
}

extension ConversationController {
  override open func searchAction() {
    Router.shared.use(
      SearchContactPageRouter,
      parameters: ["nav": navigationController as Any],
      closure: nil
    )
  }

  override open func didClickAddBtn() {
    print("add click")

    if children.contains(popListController) == false {
      popListController.itemDatas = getPopListItems()
      addChild(popListController)
      popListController.view.frame = listCtrl.view.frame
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
    addFriend.image = UIImage.ne_imageNamed(name: "add_friend")
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
    createGroup.image = UIImage.ne_imageNamed(name: "create_discussion")
    createGroup.completion = {
      weakSelf?.createDiscussGroup()
    }
    items.append(createGroup)

    let createDicuss = PopListItem()
    createDicuss.showName = localizable("create_senior_group")
    createDicuss.image = UIImage.ne_imageNamed(name: "create_group")
    createDicuss.completion = {
      weakSelf?.createSeniorGroup()
    }
    items.append(createDicuss)

    return items
  }
}
