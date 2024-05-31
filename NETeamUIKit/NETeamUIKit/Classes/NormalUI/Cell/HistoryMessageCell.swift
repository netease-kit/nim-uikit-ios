
import NIMSDK

// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.
import UIKit

@objcMembers
open class HistoryMessageCell: NEBaseHistoryMessageCell {
  override open func setupSubviews() {
    super.setupSubviews()
    NSLayoutConstraint.activate([
      headView.leftAnchor.constraint(
        equalTo: contentView.leftAnchor,
        constant: NEConstant.screenInterval
      ),
      headView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -5),
      headView.widthAnchor.constraint(equalToConstant: 36),
      headView.heightAnchor.constraint(equalToConstant: 36),
    ])

    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: headView.rightAnchor, constant: 12),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      titleLabel.topAnchor.constraint(equalTo: headView.topAnchor),
    ])

    NSLayoutConstraint.activate([
      subTitleLabel.leftAnchor.constraint(equalTo: headView.rightAnchor, constant: 12),
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
      timeLabel.rightAnchor.constraint(
        equalTo: contentView.rightAnchor,
        constant: -NEConstant.screenInterval
      ),
      timeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])
  }

  override open func configData(message: HistoryMessageModel?) {
    super.configData(message: message)
    guard let searchStr = searchText, let fullText = message?.imMessage?.text else { return }
    let windowWidth = UIScreen.main.bounds.width
    let maxWidth = windowWidth - NEConstant.screenInterval - 36 - 12 - 50
    truncateTextForLabel(subTitleLabel, maxWidth, searchStr, fullText)
  }
}
