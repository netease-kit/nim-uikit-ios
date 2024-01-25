//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class TeamMemberSelectCell: NEBaseTeamMemberSelectCell {
  override open func setupUI() {
    super.setupUI()
    headerView.layer.cornerRadius = 18
    checkImageView.highlightedImage = coreLoader.loadImage("select")
    NSLayoutConstraint.activate([
      checkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      checkImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 18),
      checkImageView.widthAnchor.constraint(equalToConstant: 18),
      checkImageView.heightAnchor.constraint(equalToConstant: 18),
    ])

    NSLayoutConstraint.activate([
      headerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      headerView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 52),
      headerView.widthAnchor.constraint(equalToConstant: 36),
      headerView.heightAnchor.constraint(equalToConstant: 36),
    ])

    NSLayoutConstraint.activate([
      nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      nameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 102),
      nameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -18),
    ])
  }
}
