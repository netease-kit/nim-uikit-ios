
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NEBaseUIKit
import UIKit

@objcMembers
open class FunChatTeamMemberCell: NEBaseChatTeamMemberCell {
  override open var searchHighlightColor: UIColor { .ne_searchHighlight }
  override open var nameHorizontalSpacing: CGFloat { 11 }
  override open var nameTrailingInset: CGFloat { 29 }

  override open func setupUI() {
    super.setupUI()

    headerView.layer.cornerRadius = 4
    NSLayoutConstraint.activate([
      headerView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
      headerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      headerView.widthAnchor.constraint(equalToConstant: 40),
      headerView.heightAnchor.constraint(equalToConstant: 40),
    ])

    nameStackView.spacing = 1

    let line = UIView()
    line.translatesAutoresizingMaskIntoConstraints = false
    line.backgroundColor = .funChatLineBorderColor
    contentView.addSubview(line)
    NSLayoutConstraint.activate([
      line.leftAnchor.constraint(equalTo: headerView.leftAnchor),
      line.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      line.heightAnchor.constraint(equalToConstant: 0.6),
      line.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }
}
