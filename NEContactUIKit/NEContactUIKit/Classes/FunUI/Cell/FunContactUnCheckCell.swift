// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import UIKit

@objcMembers
open class FunContactUnCheckCell: NEBaseContactUnCheckCell {
  override func setupUI() {
    super.setupUI()
    avatarImageView.layer.cornerRadius = 4
    NSLayoutConstraint.activate([
      avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      avatarImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      avatarImageView.widthAnchor.constraint(equalToConstant: 40),
      avatarImageView.heightAnchor.constraint(equalToConstant: 40),
    ])
  }

  /// 重写控件赋值方法
  /// - Parameter model: 数据模型（ContactInfo）
  override func configure(_ model: Any) {
    guard let model = model as? ContactInfo else { return }

    avatarImageView.configHeadData(
      headUrl: model.user?.user?.avatar,
      name: model.user?.showName() ?? "",
      uid: model.user?.user?.accountId ?? ""
    )
  }
}
