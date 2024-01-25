// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class TeamMemberCell: NEBaseTeamMemberCell {
  override open func setupUI() {
    super.setupUI()
    contentView.addSubview(removeLabel)
    NSLayoutConstraint.activate([
      removeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      removeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      removeLabel.heightAnchor.constraint(equalToConstant: 22),
      removeLabel.widthAnchor.constraint(equalToConstant: 40),
    ])
    removeLabel.textColor = .ne_redText
    removeLabel.clipsToBounds = true
    removeLabel.layer.cornerRadius = 4.0
    removeLabel.layer.borderColor = UIColor.ne_redColor.cgColor
    removeLabel.layer.borderWidth = 1.0
    removeLabel.font = UIFont.systemFont(ofSize: 12.0)

    ownerLabel.backgroundColor = .normalTeamOwnerBgColor
    ownerLabel.textColor = .normalTeamOwnerColor
    ownerLabel.layer.borderColor = UIColor.normalTeamOwnerBorderColor.cgColor
    ownerLabel.layer.cornerRadius = 11.0

    setupRemoveButton()
  }
}
