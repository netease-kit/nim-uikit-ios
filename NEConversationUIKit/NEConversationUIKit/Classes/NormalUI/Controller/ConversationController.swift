
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class ConversationController: NEBaseConversationController {
  /// 搜索按钮
  public lazy var searchBarButton: UIButton = {
    let searchBarButton = UIButton()
    searchBarButton.accessibilityIdentifier = "id.titleBarSearchImg"
    searchBarButton.setImage(UIImage.ne_imageNamed(name: "chat_search"), for: .normal)
    searchBarButton.addTarget(self, action: #selector(searchAction), for: .touchUpInside)
    return searchBarButton
  }()

  /// 添加按钮
  public lazy var addBarButton: UIButton = {
    let addBarButton = UIButton()
    addBarButton.accessibilityIdentifier = "id.titleBarMoreImg"
    addBarButton.setImage(UIImage.ne_imageNamed(name: "chat_add"), for: .normal)
    addBarButton.addTarget(self, action: #selector(didClickAddBtn), for: .touchUpInside)
    return addBarButton
  }()

  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nil, bundle: nil)
    className = "ConversationController"
    cellRegisterDic = [0: ConversationListCell.self]
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .ne_navLineColor
  }

  override func initSystemNav() {
    super.initSystemNav()

    let searchBarItem = UIBarButtonItem(customView: searchBarButton)
    let addBarItem = UIBarButtonItem(customView: addBarButton)
    let spaceBarItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
    spaceBarItem.width = NEConstant.screenInterval

    navigationItem.rightBarButtonItems = [addBarItem, spaceBarItem, searchBarItem]
    if !NEKitConversationConfig.shared.ui.showTitleBarRight2Icon {
      navigationView.searchBtn.isHidden = true
      navigationItem.rightBarButtonItems = [addBarItem]
    }
    if !NEKitConversationConfig.shared.ui.showTitleBarRightIcon {
      navigationView.addBtn.isHidden = true
      navigationItem.rightBarButtonItems = [searchBarItem]
    }
  }

  override open func setupSubviews() {
    super.setupSubviews()

    popListView = PopListView()

    tableView.rowHeight = 62
    tableView.backgroundColor = .white
  }
}
