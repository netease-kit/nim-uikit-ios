// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEConversationUIKit

open class CustomConversationListViewController: ConversationListViewController, ConversationListViewControllerDelegate {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    delegate = self

    // 自定义cell, [ConversationListModel.customType: 需要注册的自定义cell]
    registerCellDic[1] = CustomConversationListCell.self
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
  }

  override open func deleteActionHandler(action: UITableViewRowAction?, indexPath: IndexPath) {
    showSingleAlert(message: "override deleteActionHandler") {}
  }

  override open func topActionHandler(action: UITableViewRowAction?, indexPath: IndexPath, isTop: Bool) {
    showSingleAlert(message: "override topActionHandler") {
      super.topActionHandler(action: action, indexPath: indexPath, isTop: isTop)
    }
  }

  //  可自行处理数据
  public func onDataLoaded() {
    guard let conversationList = viewModel.conversationListArray else { return
    }
    for model in conversationList {
      model.customType = 1
    }
    tableView.reloadData()
  }
}
