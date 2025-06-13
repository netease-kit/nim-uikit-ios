
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import UIKit

@objcMembers
open class UserTableViewCell: UserBaseTableViewCell {
  override open func baseCommonUI() {
    super.baseCommonUI()
    // avatar
    userHeaderView.layer.cornerRadius = 21
    NSLayoutConstraint.activate([
      userHeaderView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
      userHeaderView.widthAnchor.constraint(equalToConstant: 42),
      userHeaderView.heightAnchor.constraint(equalToConstant: 42),
      userHeaderView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
    ])

    titleLabel.font = UIFont.systemFont(ofSize: 16)
    titleLabel.textColor = UIColor(
      red: 51 / 255.0,
      green: 51 / 255.0,
      blue: 51 / 255.0,
      alpha: 1.0
    )
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: userHeaderView.rightAnchor, constant: 12),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -35),
      titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),
      titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }
}
