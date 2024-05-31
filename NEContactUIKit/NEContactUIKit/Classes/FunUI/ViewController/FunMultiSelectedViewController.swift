
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreKit
import NIMSDK
import UIKit

/// 转发多选-已选页面-通用版
@objcMembers
open class FunMultiSelectedViewController: NEBaseMultiSelectedViewController {
  override init(selectedArray: [MultiSelectModel] = [MultiSelectModel]()) {
    super.init(selectedArray: selectedArray)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  /// 设置背景圆角、宽高
  override open func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    view.layer.cornerRadius = 8
    view.layer.borderWidth = 0.5
    view.layer.borderColor = UIColor.lightGray.cgColor
    view.frame = CGRect(x: 0, y: NEConstant.screenHeight - 380, width: NEConstant.screenWidth, height: 380)

    // 父视图添加单击手势，点击背景区域 dismiss
    let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
    view.superview?.addGestureRecognizer(tap)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    commonUI()

    tableView.rowHeight = 64
    tableView.register(FunSelectedListCell.self, forCellReuseIdentifier: "\(NSStringFromClass(NEBaseSelectedListCell.self))")
    tableViewTopAnchor?.constant = 50

    emptyView.setEmptyImage(name: "fun_user_empty")
  }

  /// 单击手势点击事件
  /// - Parameter tap: 单击手势
  func tapAction(_ tap: UITapGestureRecognizer) {
    // 判断手势位置位于背景区域
    if tap.location(in: view).y < 0 {
      cancelButtonClick()
    }
  }
}
