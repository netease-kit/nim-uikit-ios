//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FusionContactSelectedCell: NEBaseFusionContactSelectedCell {
  /// UI 初始化
  override open func setupFusionSelectedCellUI() {
    super.setupFusionSelectedCellUI()

    contentView.addSubview(selectedStateImage)
    selectedStateImage.highlightedImage = coreLoader.loadImage("select")
    NSLayoutConstraint.activate([
      selectedStateImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      selectedStateImage.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
    ])

    contentView.addSubview(userHeaderView)
    NSLayoutConstraint.activate([
      userHeaderView.widthAnchor.constraint(equalToConstant: 36),
      userHeaderView.heightAnchor.constraint(equalToConstant: 36),
      userHeaderView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),
      userHeaderView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 50),
    ])
    userHeaderView.layer.cornerRadius = 18

    contentView.addSubview(nameLabel)
    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: userHeaderView.rightAnchor, constant: 12),
      nameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -35),
      nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
      nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    contentView.addSubview(bottomLine)
    NSLayoutConstraint.activate([
      bottomLine.leftAnchor.constraint(equalTo: userHeaderView.leftAnchor),
      bottomLine.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      bottomLine.heightAnchor.constraint(equalToConstant: 1),
    ])
  }
}
