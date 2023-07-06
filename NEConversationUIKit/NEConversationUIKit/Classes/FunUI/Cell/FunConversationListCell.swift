// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK

@objcMembers
open class FunConversationListCell: NEBaseConversationListCell {
  var contentModel: ConversationListModel?

  override open func setupSubviews() {
    super.setupSubviews()
    NSLayoutConstraint.activate([
      headImge.leftAnchor.constraint(
        equalTo: contentView.leftAnchor,
        constant: NEConstant.screenInterval
      ),
      headImge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      headImge.widthAnchor.constraint(equalToConstant: 48),
      headImge.heightAnchor.constraint(equalToConstant: 48),
    ])

    title.font = NEKitConversationConfig.shared.ui.titleFont ?? UIFont.systemFont(ofSize: 17)
    NSLayoutConstraint.activate([
      title.leftAnchor.constraint(equalTo: headImge.rightAnchor, constant: 12),
      title.rightAnchor.constraint(equalTo: timeLabel.leftAnchor, constant: -5),
      title.topAnchor.constraint(equalTo: headImge.topAnchor, constant: 4),
    ])

    let bottomLine = UIView()
    bottomLine.translatesAutoresizingMaskIntoConstraints = false
    bottomLine.backgroundColor = .funConversationListLineBorderColor
    contentView.addSubview(bottomLine)
    NSLayoutConstraint.activate([
      bottomLine.leftAnchor.constraint(equalTo: title.leftAnchor),
      bottomLine.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      bottomLine.heightAnchor.constraint(equalToConstant: 0.5),
      bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    NSLayoutConstraint.activate([
      notifyMsg.rightAnchor.constraint(equalTo: timeLabel.rightAnchor, constant: -2),
      notifyMsg.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 10),
      notifyMsg.widthAnchor.constraint(equalToConstant: 14),
      notifyMsg.heightAnchor.constraint(equalToConstant: 14),
    ])
  }

  override func initSubviewsLayout() {
    if NEKitConversationConfig.shared.ui.avatarType == .rectangle {
      headImge.layer.cornerRadius = NEKitConversationConfig.shared.ui.avatarCornerRadius
    } else if NEKitConversationConfig.shared.ui.avatarType == .cycle {
      headImge.layer.cornerRadius = 24.0
    } else {
      headImge.layer.cornerRadius = 4.0
    }
  }

  override open func configData(sessionModel: ConversationListModel?) {
    super.configData(sessionModel: sessionModel)
    contentModel = sessionModel

    // backgroundColor
    if let session = sessionModel?.recentSession?.session {
      let isTop = topStickInfos[session] != nil
      if isTop {
        contentView.backgroundColor = .funConversationBackgroundColor
      } else {
        contentView.backgroundColor = .white
      }
    }
  }
}
