// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import UIKit

@objcMembers
open class ContactUnCheckCell: NEBaseContactUnCheckCell {
  override func setupUI() {
    super.setupUI()
    avatarImageView.layer.cornerRadius = 18
    NSLayoutConstraint.activate([
      avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      avatarImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      avatarImageView.widthAnchor.constraint(equalToConstant: 36),
      avatarImageView.heightAnchor.constraint(equalToConstant: 36),
    ])
  }

  func setAvatarWH(_ height: CGFloat) {
    avatarImageView.layer.cornerRadius = height / 2
    avatarImageView.updateLayoutConstraint(firstItem: avatarImageView, seconedItem: nil, attribute: .width, constant: height)
    avatarImageView.updateLayoutConstraint(firstItem: avatarImageView, seconedItem: nil, attribute: .height, constant: height)
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
