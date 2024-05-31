// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import UIKit

/// 转发-选择页面-已选 CollectionViewCell -协同版
@objcMembers
open class SelectedCell: NEBaseSelectedCell {
  /// 重写布局方法
  override func setupUI() {
    super.setupUI()
    avatarImageView.layer.cornerRadius = 16
  }
}
