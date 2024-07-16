//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunFusionContactSelectedCell: NEBaseFusionContactSelectedCell {
  /// UI 初始化
  override open func setupFusionSelectedCellUI() {
    super.setupFusionSelectedCellUI()

    contentView.addSubview(selectedStateImage)
    selectedStateImage.highlightedImage = UIImage.ne_imageNamed(name: "fun_select")
    NSLayoutConstraint.activate([
      selectedStateImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      selectedStateImage.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
    ])

    contentView.addSubview(avatarImageView)
    NSLayoutConstraint.activate([
      avatarImageView.widthAnchor.constraint(equalToConstant: 40),
      avatarImageView.heightAnchor.constraint(equalToConstant: 40),
      avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),
      avatarImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 50),
    ])
    avatarImageView.layer.cornerRadius = 4

    contentView.addSubview(nameLabel)
    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 12),
      nameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -35),
      nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
      nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    avatarImageView.addSubview(avatarNameLabel)
    NSLayoutConstraint.activate([
      avatarNameLabel.leftAnchor.constraint(equalTo: avatarImageView.leftAnchor, constant: 1),
      avatarNameLabel.rightAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: -1),
      avatarNameLabel.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
      avatarNameLabel.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
    ])

    contentView.addSubview(bottomLine)
    NSLayoutConstraint.activate([
      bottomLine.leftAnchor.constraint(equalTo: avatarImageView.leftAnchor),
      bottomLine.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      bottomLine.heightAnchor.constraint(equalToConstant: 1),
    ])
  }
}
