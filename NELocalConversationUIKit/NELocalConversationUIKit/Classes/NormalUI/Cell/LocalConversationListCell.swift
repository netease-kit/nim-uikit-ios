
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class LocalConversationListCell: NEBaseLocalConversationListCell {
  override open func setupSubviews() {
    super.setupSubviews()

    NSLayoutConstraint.activate([
      headImageView.leftAnchor.constraint(
        equalTo: contentView.leftAnchor,
        constant: NEConstant.screenInterval
      ),
      headImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      headImageView.widthAnchor.constraint(equalToConstant: 42),
      headImageView.heightAnchor.constraint(equalToConstant: 42),
    ])

    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: headImageView.rightAnchor, constant: 12),
      titleLabel.rightAnchor.constraint(equalTo: timeLabel.leftAnchor, constant: -5),
      titleLabel.topAnchor.constraint(equalTo: headImageView.topAnchor),
    ])

    NSLayoutConstraint.activate([
      notifyMsgView.rightAnchor.constraint(equalTo: timeLabel.rightAnchor),
      notifyMsgView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 5),
      notifyMsgView.widthAnchor.constraint(equalToConstant: 13),
      notifyMsgView.heightAnchor.constraint(equalToConstant: 13),
    ])
  }

  override open func initSubviewsLayout() {
    if LocalConversationUIConfig.shared.conversationProperties.avatarType == .cycle {
      headImageView.layer.cornerRadius = 21.0
    } else if LocalConversationUIConfig.shared.conversationProperties.avatarCornerRadius > 0 {
      headImageView.layer.cornerRadius = LocalConversationUIConfig.shared.conversationProperties.avatarCornerRadius
    } else {
      headImageView.layer.cornerRadius = 21.0
    }
  }

  override open func configureData(_ sessionModel: NELocalConversationListModel?) {
    super.configureData(sessionModel)
    if sessionModel?.conversation?.stickTop == true {
      contentView.backgroundColor = LocalConversationUIConfig.shared.conversationProperties.itemStickTopBackground ?? .normalConversationTopItemBackgroundColor
    } else {
      contentView.backgroundColor = LocalConversationUIConfig.shared.conversationProperties.itemBackground ?? .normalConversationItemBackgroundColor
    }
  }
}
