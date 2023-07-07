// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK

@objcMembers
open class FunConversationListViewController: NEBaseConversationListViewController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    className = "FunConversationListViewController"
    deleteBottonColor = .funConversationdeleteActionColor
    registerCellDic = [0: FunConversationListCell.self]
    networkToolHeight = 48
    brokenNetworkView.errorIcon.isHidden = false
    brokenNetworkView.backgroundColor = .funConversationNetworkBrokenBackgroundColor
    brokenNetworkView.content.textColor = .funConversationNetworkBrokenTitleColor
    emptyView.setEmptyImage(name: "fun_user_empty")
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func setupSubviews() {
    super.setupSubviews()
    tableView.rowHeight = 72
    tableView.backgroundColor = .funConversationBackgroundColor
  }
}

// MARK: ==========FunConversationListCellDelegate============

extension FunConversationListViewController {
  open func getPopListItems(cell: UITableViewCell, contentModel: ConversationListModel?) -> [PopListItem] {
    weak var weakSelf = self
    var items = [PopListItem]()

    guard let recentSession = contentModel?.recentSession,
          let session = recentSession.session,
          let cellIndex = tableView.indexPath(for: cell) else {
      return [PopListItem]()
    }
    let isTop = viewModel.stickTopInfos[session] != nil

    let stickTopItem = PopListItem()
    stickTopItem.showName = isTop ? NEKitConversationConfig.shared.ui.stickTopBottonCancelTitle :
      NEKitConversationConfig.shared.ui.stickTopBottonTitle
    stickTopItem.showNameColor = .black
    stickTopItem.completion = {
      weakSelf?.topActionHandler(action: nil, indexPath: cellIndex, isTop: isTop)
    }
    items.append(stickTopItem)

    let deleteItem = PopListItem()
    deleteItem.showName = NEKitConversationConfig.shared.ui.deleteBottonTitle
    deleteItem.showNameColor = .black
    deleteItem.completion = {
      weakSelf?.deleteActionHandler(action: nil, indexPath: cellIndex)
    }
    items.append(deleteItem)

    return items
  }

//  public func didLongPressConversationView(_ cell: UITableViewCell, _ longPress: UILongPressGestureRecognizer, _ contentModel: ConversationListModel?) {
//    let popListController = FunPopListViewController()
//    popListController.popView.backgroundColor = .white
//    popListController.itemDatas = getPopListItems(cell: cell, contentModel: contentModel)
//    addChild(popListController)
//    view.addSubview(popListController.view)
//    popListController.view.bounds = UIScreen.main.bounds
//
//    if let cellIndexPath = tableView.indexPath(for: cell) {
//      let y = longPress.location(in: view).y
//      let shadowHeight = popListController.shadowView.frame.size.height
//      if (y + shadowHeight) > (NEConstant.screenHeight - NEConstant.navigationAndStatusHeight - 123) {
//        popListController.shadowViewTopAnchor?.constant = y - shadowHeight
//      } else {
//        popListController.shadowViewTopAnchor?.constant = y
//      }
//    }
//  }
}
