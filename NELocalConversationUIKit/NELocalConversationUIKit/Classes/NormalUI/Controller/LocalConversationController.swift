
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECommonUIKit
import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class LocalConversationController: NEBaseLocalConversationController {
  /// 搜索按钮
  public lazy var searchBarButton: UIButton = {
    let searchBarButton = UIButton()
    searchBarButton.accessibilityIdentifier = "id.titleBarSearchImg"
    searchBarButton.setImage(UIImage.ne_imageNamed(name: "chat_search"), for: .normal)
    searchBarButton.addTarget(self, action: #selector(searchAction), for: .touchUpInside)
    return searchBarButton
  }()

  /// 数字人分割线
  public lazy var pinUserDividerLine: UIView = {
    let line = UIView()
    line.backgroundColor = UIColor.ne_navLineColor
    line.translatesAutoresizingMaskIntoConstraints = false
    return line
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
    className = "LocalConversationController"
    cellRegisterDic = [0: LocalConversationListCell.self]
    stickTopCellRegisterDic = [0: StickTopCell.self]
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .ne_navLineColor
    changeLanguage()
    NotificationCenter.default.addObserver(self, selector: #selector(changeLanguage), name: NENotificationName.changeLanguage, object: nil)
  }

  override open func didMove(toParent parent: UIViewController?) {
    super.didMove(toParent: parent)
    if parent == nil {
      NotificationCenter.default.removeObserver(self)
    }
  }

  func changeLanguage() {
    requestData()
    initSystemNav()
    popListView = PopListView()
    brokenNetworkView.contentLabel.text = commonLocalizable("network_error")
  }

  override func initSystemNav() {
    super.initSystemNav()

    let searchBarItem = UIBarButtonItem(customView: searchBarButton)
    let addBarItem = UIBarButtonItem(customView: addBarButton)
    let spaceBarItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
    spaceBarItem.width = NEConstant.screenInterval

    navigationItem.rightBarButtonItems = [addBarItem, spaceBarItem, searchBarItem]
    if !LocalConversationUIConfig.shared.showTitleBarRight2Icon {
      navigationView.searchBtn.isHidden = true
      navigationItem.rightBarButtonItems = [addBarItem]
    }

    if !LocalConversationUIConfig.shared.showTitleBarRightIcon {
      navigationView.addBtn.isHidden = true
      navigationItem.rightBarButtonItems = [searchBarItem]
    }
    navigationView.brandBtn.setTitle(commonLocalizable("appName"), for: .normal)
  }

  override open func setupSubviews() {
    super.setupSubviews()

    tableView.rowHeight = 62
    tableView.backgroundColor = .white

    // 设置置顶列表宽高
    stickTopCollcetionView.frame = CGRect(x: 10, y: 0, width: view.frame.size.width - 20.0, height: 181 - NEConstant.navigationAndStatusHeight)

    stickTopCollcetionView.addSubview(pinUserDividerLine)
    pinUserDividerLine.frame = CGRect(x: -10, y: 180 - NEConstant.navigationAndStatusHeight, width: view.frame.size.width + 20.0, height: 1.0)
  }

  /// 置顶cell大小
  override open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    CGSize(width: 62, height: 181 - NEConstant.navigationAndStatusHeight)
  }

  /// 置顶显示隐藏(根据是否有置顶数据)
  open func setupNormalStickTopView() {
    if viewModel.aiUserListData.count > 0 {
      if let headerView = tableView.tableHeaderView {
        if headerView.isKind(of: UICollectionView.self) == false {
          tableView.tableHeaderView = stickTopCollcetionView
        }
      } else {
        tableView.tableHeaderView = stickTopCollcetionView
      }
      stickTopCollcetionView.reloadData()
      navigationView.titleBarBottomLine.isHidden = true
    } else {
      if tableView.tableHeaderView != nil {
        tableView.tableHeaderView = nil
      }
      navigationView.titleBarBottomLine.isHidden = false
    }
  }

  override open func reloadTableView() {
    super.reloadTableView()
    NEALog.infoLog(className(), desc: #function + " reloadTableView in conversation controller stick top count \(viewModel.stickTopConversations.count)")
    setupNormalStickTopView()
  }
}
