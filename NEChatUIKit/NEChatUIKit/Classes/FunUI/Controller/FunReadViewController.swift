// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK
import NECoreIMKit
import NECommonUIKit

@objcMembers
open class FunReadViewController: NEBaseReadViewController {
  override public func commonUI() {
    super.commonUI()
    navigationController?.navigationBar.backgroundColor = .white
    customNavigationView.backgroundColor = .white

    readButton.setTitleColor(UIColor.funChatThemeColor, for: .normal)
    line.backgroundColor = UIColor.funChatThemeColor

    readTableView.register(
      FunUserTableViewCell.self,
      forCellReuseIdentifier: "\(FunUserTableViewCell.self)"
    )
    readTableView.rowHeight = 64

    emptyView.setEmptyImage(name: "fun_emptyView")
  }

  override public func readButtonEvent(button: UIButton) {
    super.readButtonEvent(button: button)
    readButton.setTitleColor(UIColor.funChatThemeColor, for: .normal)
    unreadButton.setTitleColor(UIColor.ne_darkText, for: .normal)
  }

  override public func unreadButtonEvent(button: UIButton) {
    super.unreadButtonEvent(button: button)
    readButton.setTitleColor(UIColor.ne_darkText, for: .normal)
    unreadButton.setTitleColor(UIColor.funChatThemeColor, for: .normal)
  }
}
