
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreIM2Kit
import NIMSDK
import UIKit

@objcMembers
open class ReadViewController: NEBaseReadViewController {
  override init(message: V2NIMMessage, teamId: String) {
    super.init(message: message, teamId: teamId)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    navigationView.backgroundColor = .white
    navigationController?.navigationBar.backgroundColor = .white
  }

  override open func commonUI() {
    super.commonUI()
    navigationView.titleBarBottomLine.isHidden = false
    readButton.setTitleColor(UIColor.ne_normalTheme, for: .normal)
    bottonBottomLine.backgroundColor = UIColor.ne_normalTheme

    readTableView.register(
      UserTableViewCell.self,
      forCellReuseIdentifier: "\(UserBaseTableViewCell.self)"
    )
    readTableView.rowHeight = 62

    unreadTableView.register(
      UserTableViewCell.self,
      forCellReuseIdentifier: "\(UserBaseTableViewCell.self)"
    )
    unreadTableView.rowHeight = 62
  }

  /// 重写已读按钮点击事件
  /// - Parameter button: 按钮
  override open func readButtonEvent(button: UIButton) {
    super.readButtonEvent(button: button)
    readButton.setTitleColor(UIColor.ne_normalTheme, for: .normal)
    unreadButton.setTitleColor(UIColor.ne_darkText, for: .normal)
  }

  /// 重写未读按钮点击事件
  /// - Parameter button: 按钮
  override open func unreadButtonEvent(button: UIButton) {
    super.unreadButtonEvent(button: button)
    readButton.setTitleColor(UIColor.ne_darkText, for: .normal)
    unreadButton.setTitleColor(UIColor.ne_normalTheme, for: .normal)
  }
}
