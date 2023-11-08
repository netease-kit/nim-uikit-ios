// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import UIKit

@objcMembers
open class FunTeamSettingHeaderCell: NEBaseTeamSettingHeaderCell {
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    edgeInset = .zero
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  override open func setupUI() {
    super.setupUI()
    headerView.layer.cornerRadius = 3.36
    contentView.updateLayoutConstraint(firstItem: dividerLine, seconedItem: contentView, attribute: .left, constant: 16)
    contentView.updateLayoutConstraint(firstItem: dividerLine, seconedItem: contentView, attribute: .right, constant: 0)

    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
      titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -84),
    ])

    NSLayoutConstraint.activate([
      arrow.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      arrow.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
    ])

    NSLayoutConstraint.activate([
      headerView.centerYAnchor.constraint(equalTo: arrow.centerYAnchor),
      headerView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -44.0),
      headerView.widthAnchor.constraint(equalToConstant: 42.0),
      headerView.heightAnchor.constraint(equalToConstant: 42.0),
    ])
  }
}
