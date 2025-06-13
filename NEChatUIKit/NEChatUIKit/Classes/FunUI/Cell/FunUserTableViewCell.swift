// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import UIKit

@objcMembers
open class FunUserTableViewCell: UserBaseTableViewCell {
  override open func baseCommonUI() {
    super.baseCommonUI()
    // avatar
    userHeaderView.layer.cornerRadius = 4
    NSLayoutConstraint.activate([
      userHeaderView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
      userHeaderView.widthAnchor.constraint(equalToConstant: 40),
      userHeaderView.heightAnchor.constraint(equalToConstant: 40),
      userHeaderView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
    ])

    titleLabel.textColor = .ne_darkText
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: userHeaderView.rightAnchor, constant: 11),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -29),
      titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])

    let line = UIView()
    line.translatesAutoresizingMaskIntoConstraints = false
    line.backgroundColor = .funChatLineBorderColor
    contentView.addSubview(line)
    NSLayoutConstraint.activate([
      line.leftAnchor.constraint(equalTo: userHeaderView.leftAnchor),
      line.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      line.heightAnchor.constraint(equalToConstant: 0.6),
      line.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }
}
