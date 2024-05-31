// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// 转发-选择页面-最近转发 CollectionViewCell -协同版
@objcMembers
open class RecentSelectCell: NEBaseRecentSelectCell {
  /// 重写布局方法
  override func setupUI() {
    super.setupUI()
    setAvatarWH(36)
  }

  /// 重写控件赋值方法
  /// - Parameter model: 数据模型（MultiSelectModel）
  override func configure(_ model: Any) {
    guard let model = model as? MultiSelectModel else { return }

    super.configure(model)
    selectImageView.image = model.isSelected ? UIImage.ne_imageNamed(name: "select") : UIImage.ne_imageNamed(name: "unselect")
  }
}
