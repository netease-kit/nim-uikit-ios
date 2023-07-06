
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK

@objcMembers
open class ConversationListCell: NEBaseConversationListCell {
  override open func setupSubviews() {
    super.setupSubviews()

    NSLayoutConstraint.activate([
      headImge.leftAnchor.constraint(
        equalTo: contentView.leftAnchor,
        constant: NEConstant.screenInterval
      ),
      headImge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      headImge.widthAnchor.constraint(equalToConstant: 42),
      headImge.heightAnchor.constraint(equalToConstant: 42),
    ])

    NSLayoutConstraint.activate([
      title.leftAnchor.constraint(equalTo: headImge.rightAnchor, constant: 12),
      title.rightAnchor.constraint(equalTo: timeLabel.leftAnchor, constant: -5),
      title.topAnchor.constraint(equalTo: headImge.topAnchor),
    ])

    NSLayoutConstraint.activate([
      notifyMsg.rightAnchor.constraint(equalTo: timeLabel.rightAnchor),
      notifyMsg.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 5),
      notifyMsg.widthAnchor.constraint(equalToConstant: 13),
      notifyMsg.heightAnchor.constraint(equalToConstant: 13),
    ])
  }

  override func initSubviewsLayout() {
    if NEKitConversationConfig.shared.ui.avatarType == .rectangle {
      headImge.layer.cornerRadius = NEKitConversationConfig.shared.ui.avatarCornerRadius
    } else if NEKitConversationConfig.shared.ui.avatarType == .cycle {
      headImge.layer.cornerRadius = 21.0
    } else {
      headImge.layer.cornerRadius = 21.0
    }
  }

  override open func configData(sessionModel: ConversationListModel?) {
    super.configData(sessionModel: sessionModel)

    // backgroundColor
    if let session = sessionModel?.recentSession?.session {
      let isTop = topStickInfos[session] != nil
      if isTop {
        contentView.backgroundColor = UIColor(hexString: "0xF3F5F7")
      } else {
        contentView.backgroundColor = .white
      }
    }
  }
}
