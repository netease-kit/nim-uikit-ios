// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import UIKit

/// 转发-多选-已选详情页面 TableViewCell -协同版
@objcMembers
open class SelectedListCell: NEBaseSelectedListCell {
  /// 重写设置头像方法
  override open func setupCommonCircleHeader() {
    super.setupCommonCircleHeader()
    userHeaderView.layer.cornerRadius = 21
    NSLayoutConstraint.activate([
      userHeaderView.widthAnchor.constraint(equalToConstant: 42),
      userHeaderView.heightAnchor.constraint(equalToConstant: 42),
      userHeaderView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),
    ])
  }

  /// 重写布局方法
  override open func commonUI() {
    super.commonUI()
    bottomLineLeftConstraint?.constant = 74
  }
}
