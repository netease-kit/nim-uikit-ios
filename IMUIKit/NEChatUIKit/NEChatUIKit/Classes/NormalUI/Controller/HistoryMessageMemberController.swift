
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class HistoryMessageMemberController: HistoryMessageController {
  override public init(conversationId: String) {
    super.init(conversationId: conversationId)
    tag = "HistoryMessageMemberController"
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func setupSubviews() {
    super.setupSubviews()
    searchTextField.isHidden = true
    tipLable.isHidden = true
    collectionView.isHidden = true
    tableViewTopAnchor?.constant = 0
    tableView.isHidden = false
  }

  override open func initialConfig() {
    title = chatLocalizable("search_message_by_member")
  }
}
