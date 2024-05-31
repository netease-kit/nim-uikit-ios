// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import UIKit

/// 转发-选择页面-已选 CollectionViewCell -基类
@objcMembers
open class NEBaseSelectedCell: NEBaseContactUnCheckCell {
  /// 重写布局方法
  override func setupUI() {
    super.setupUI()
    avatarImageView.layer.cornerRadius = 16
    avatarImageView.titleLabel.font = UIFont.systemFont(ofSize: 12.0)
    NSLayoutConstraint.activate([
      avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      avatarImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      avatarImageView.widthAnchor.constraint(equalToConstant: 32),
      avatarImageView.heightAnchor.constraint(equalToConstant: 32),
    ])
  }

  /// 重写控件赋值方法
  /// - Parameter model: 数据模型（MultiSelectModel）
  override func configure(_ model: Any) {
    guard let model = model as? MultiSelectModel else { return }

    avatarImageView.configHeadData(
      headUrl: model.avatar,
      name: model.name ?? "",
      uid: V2NIMConversationIdUtil.conversationTargetId(model.conversationId ?? "") ?? ""
    )
  }
}
