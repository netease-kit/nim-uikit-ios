
import NIMSDK

// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.
import UIKit

@objcMembers
open class FunHistoryMessageCell: NEBaseHistoryMessageCell {
  override open func setupSubviews() {
    super.setupSubviews()
    rangeTextColor = .funTeamThemeColor

    headView.layer.cornerRadius = 4
    NSLayoutConstraint.activate([
      headView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
      headView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
      headView.widthAnchor.constraint(equalToConstant: 32),
      headView.heightAnchor.constraint(equalToConstant: 32),
    ])

    titleLabel.font = .systemFont(ofSize: 12)
    titleLabel.textColor = .funTeamHistoryCellTitleTextColor
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: headView.rightAnchor, constant: 12),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -50),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
    ])

    subTitleLabel.font = .systemFont(ofSize: 15)
    subTitleLabel.textColor = .ne_darkText
    NSLayoutConstraint.activate([
      subTitleLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
      subTitleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -50),
      subTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
    ])

    NSLayoutConstraint.activate([
      bottomLine.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      bottomLine.leftAnchor.constraint(equalTo: headView.leftAnchor),
      bottomLine.bottomAnchor.constraint(equalTo: bottomAnchor),
      bottomLine.heightAnchor.constraint(equalToConstant: 0.5),
    ])

    NSLayoutConstraint.activate([
      timeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
      timeLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
    ])
  }

  override open func configData(message: HistoryMessageModel?) {
    super.configData(message: message)
    guard let searchStr = searchText, let fullText = message?.imMessage?.text else { return }
    let windowWidth = UIScreen.main.bounds.width
    let maxWidth = windowWidth - 16 - 32 - 12 - 50
    truncateTextForLabel(subTitleLabel, maxWidth, searchStr, fullText)
  }
}
