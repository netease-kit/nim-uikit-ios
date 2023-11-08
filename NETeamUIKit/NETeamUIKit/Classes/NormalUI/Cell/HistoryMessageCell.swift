
import NIMSDK
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.
import UIKit

@objcMembers
open class HistoryMessageCell: NEBaseHistoryMessageCell {
  override func setupSubviews() {
    super.setupSubviews()
    NSLayoutConstraint.activate([
      headImge.leftAnchor.constraint(
        equalTo: contentView.leftAnchor,
        constant: NEConstant.screenInterval
      ),
      headImge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -5),
      headImge.widthAnchor.constraint(equalToConstant: 36),
      headImge.heightAnchor.constraint(equalToConstant: 36),
    ])

    NSLayoutConstraint.activate([
      title.leftAnchor.constraint(equalTo: headImge.rightAnchor, constant: 12),
      title.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      title.topAnchor.constraint(equalTo: headImge.topAnchor),
    ])

    NSLayoutConstraint.activate([
      subTitle.leftAnchor.constraint(equalTo: headImge.rightAnchor, constant: 12),
      subTitle.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -50),
      subTitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6),
    ])

    NSLayoutConstraint.activate([
      bottomLine.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      bottomLine.leftAnchor.constraint(equalTo: headImge.leftAnchor),
      bottomLine.bottomAnchor.constraint(equalTo: bottomAnchor),
      bottomLine.heightAnchor.constraint(equalToConstant: 0.5),
    ])

    NSLayoutConstraint.activate([
      timeLabel.rightAnchor.constraint(
        equalTo: contentView.rightAnchor,
        constant: -NEConstant.screenInterval
      ),
      timeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])
  }
}
