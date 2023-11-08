// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class ConversationListViewController: NEBaseConversationListViewController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    className = "ConversationListViewController"
    registerCellDic = [0: ConversationListCell.self]
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func setupSubviews() {
    super.setupSubviews()

    tableView.rowHeight = 62
    tableView.backgroundColor = .white
  }
}
