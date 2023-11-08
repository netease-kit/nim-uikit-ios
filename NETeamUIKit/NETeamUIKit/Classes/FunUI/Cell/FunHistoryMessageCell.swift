
import NIMSDK
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.
import UIKit

@objcMembers
open class FunHistoryMessageCell: NEBaseHistoryMessageCell {
  override func setupSubviews() {
    super.setupSubviews()
    rangeTextColor = .funTeamThemeColor

    headImge.layer.cornerRadius = 4
    NSLayoutConstraint.activate([
      headImge.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
      headImge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
      headImge.widthAnchor.constraint(equalToConstant: 32),
      headImge.heightAnchor.constraint(equalToConstant: 32),
    ])

    title.font = .systemFont(ofSize: 12)
    title.textColor = .funTeamHistoryCellTitleTextColor
    NSLayoutConstraint.activate([
      title.leftAnchor.constraint(equalTo: headImge.rightAnchor, constant: 12),
      title.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -50),
      title.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
    ])

    subTitle.font = .systemFont(ofSize: 15)
    subTitle.textColor = .ne_darkText
    NSLayoutConstraint.activate([
      subTitle.leftAnchor.constraint(equalTo: title.leftAnchor),
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
      timeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
      timeLabel.centerYAnchor.constraint(equalTo: title.centerYAnchor),
    ])
  }
}
