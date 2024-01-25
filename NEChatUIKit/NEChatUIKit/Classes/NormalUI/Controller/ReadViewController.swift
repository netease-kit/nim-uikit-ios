
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreIMKit
import NIMSDK
import UIKit

@objcMembers
open class ReadViewController: NEBaseReadViewController {
  override init(message: NIMMessage) {
    super.init(message: message)
    navigationView.backgroundColor = .white
    navigationController?.navigationBar.backgroundColor = .white
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func commonUI() {
    super.commonUI()
    navigationView.titleBarBottomLine.isHidden = false
    readButton.setTitleColor(UIColor.ne_darkText, for: .normal)
    line.backgroundColor = UIColor.ne_blueText

    readTableView.register(
      UserTableViewCell.self,
      forCellReuseIdentifier: "\(UserBaseTableViewCell.self)"
    )
    readTableView.rowHeight = 62
  }
}
