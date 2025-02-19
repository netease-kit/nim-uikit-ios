//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class StickTopCell: NEBaseStickTopCell {
  override open func setupStickTopCellUI() {
    super.setupStickTopCellUI()
    NSLayoutConstraint.activate([
      stickTopHeadImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      stickTopHeadImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
      stickTopHeadImageView.widthAnchor.constraint(equalToConstant: 42),
      stickTopHeadImageView.heightAnchor.constraint(equalToConstant: 42),
    ])
    NSLayoutConstraint.activate([
      stickTopNameLabel.topAnchor.constraint(equalTo: stickTopHeadImageView.bottomAnchor, constant: 6),
      stickTopNameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      stickTopNameLabel.leftAnchor.constraint(equalTo: stickTopHeadImageView.leftAnchor),
      stickTopNameLabel.rightAnchor.constraint(equalTo: stickTopHeadImageView.rightAnchor),
    ])
  }
}
