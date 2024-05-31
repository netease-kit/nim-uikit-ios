// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreIM2Kit
import NIMSDK
import UIKit

@objcMembers
open class FunReadViewController: NEBaseReadViewController {
  override open func commonUI() {
    super.commonUI()
    navigationController?.navigationBar.backgroundColor = .white
    navigationView.backgroundColor = .white

    readButton.setTitleColor(UIColor.funChatThemeColor, for: .normal)
    bottonBottomLine.backgroundColor = UIColor.funChatThemeColor

    readTableView.register(
      FunUserTableViewCell.self,
      forCellReuseIdentifier: "\(UserBaseTableViewCell.self)"
    )
    readTableView.rowHeight = 64

    unreadTableView.register(
      FunUserTableViewCell.self,
      forCellReuseIdentifier: "\(UserBaseTableViewCell.self)"
    )
    unreadTableView.rowHeight = 64

    emptyView.setEmptyImage(name: "fun_emptyView")
  }

  /// 重写已读按钮点击事件
  /// - Parameter button: 按钮
  override open func readButtonEvent(button: UIButton) {
    super.readButtonEvent(button: button)
    readButton.setTitleColor(UIColor.funChatThemeColor, for: .normal)
    unreadButton.setTitleColor(UIColor.ne_darkText, for: .normal)
  }

  /// 重写未读按钮点击事件
  /// - Parameter button: 按钮
  override open func unreadButtonEvent(button: UIButton) {
    super.unreadButtonEvent(button: button)
    readButton.setTitleColor(UIColor.ne_darkText, for: .normal)
    unreadButton.setTitleColor(UIColor.funChatThemeColor, for: .normal)
  }
}
