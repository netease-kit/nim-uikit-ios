
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreKit
import NIMSDK
import UIKit

/// 转发多选-已选页面-协同版
@objcMembers
open class MultiSelectedViewController: NEBaseMultiSelectedViewController {
  override init(selectedArray: [MultiSelectModel] = [MultiSelectModel]()) {
    super.init(selectedArray: selectedArray)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    commonUI()

    cancelButton.setTitle(nil, for: .normal)
    cancelButton.setImage(UIImage.ne_imageNamed(name: "backArrow"), for: .normal)

    tableView.rowHeight = 62
    tableView.register(SelectedListCell.self, forCellReuseIdentifier: "\(NSStringFromClass(NEBaseSelectedListCell.self))")
  }
}
