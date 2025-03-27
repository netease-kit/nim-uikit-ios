// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import UIKit

/// 转发-选择页面-已选 CollectionViewCell -通用版
@objcMembers
open class FunSelectedCell: NEBaseSelectedCell {
  /// 重写布局方法
  override open func setupUI() {
    super.setupUI()
    avatarImageView.layer.cornerRadius = 4
  }
}
