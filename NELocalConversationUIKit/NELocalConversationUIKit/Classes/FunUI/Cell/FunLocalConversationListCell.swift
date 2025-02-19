// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class FunLocalConversationListCell: NEBaseLocalConversationListCell {
  var contentModel: NELocalConversationListModel?

  /// 分隔线视图
  public lazy var bottomLine: UIView = {
    let bottomLine = UIView()
    bottomLine.translatesAutoresizingMaskIntoConstraints = false
    bottomLine.backgroundColor = .funConversationListLineBorderColor
    return bottomLine
  }()

  /// UI 初始化
  override open func setupSubviews() {
    super.setupSubviews()
    NSLayoutConstraint.activate([
      headImageView.leftAnchor.constraint(
        equalTo: contentView.leftAnchor,
        constant: NEConstant.screenInterval
      ),
      headImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      headImageView.widthAnchor.constraint(equalToConstant: 48),
      headImageView.heightAnchor.constraint(equalToConstant: 48),
    ])

    titleLabel.font = .systemFont(ofSize: LocalConversationUIConfig.shared.conversationProperties.itemTitleSize > 0 ? LocalConversationUIConfig.shared.conversationProperties.itemTitleSize : 17)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: headImageView.rightAnchor, constant: 12),
      titleLabel.rightAnchor.constraint(equalTo: timeLabel.leftAnchor, constant: -5),
      titleLabel.topAnchor.constraint(equalTo: headImageView.topAnchor, constant: 4),
    ])

    contentView.addSubview(bottomLine)
    NSLayoutConstraint.activate([
      bottomLine.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
      bottomLine.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      bottomLine.heightAnchor.constraint(equalToConstant: 0.5),
      bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    NSLayoutConstraint.activate([
      notifyMsgView.rightAnchor.constraint(equalTo: timeLabel.rightAnchor, constant: -2),
      notifyMsgView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 10),
      notifyMsgView.widthAnchor.constraint(equalToConstant: 14),
      notifyMsgView.heightAnchor.constraint(equalToConstant: 14),
    ])
  }

  override func initSubviewsLayout() {
    if LocalConversationUIConfig.shared.conversationProperties.avatarType == .cycle {
      headImageView.layer.cornerRadius = 24.0
    } else if LocalConversationUIConfig.shared.conversationProperties.avatarCornerRadius > 0 {
      headImageView.layer.cornerRadius = LocalConversationUIConfig.shared.conversationProperties.avatarCornerRadius
    } else {
      headImageView.layer.cornerRadius = 4.0
    }
  }

  override open func configureData(_ sessionModel: NELocalConversationListModel?) {
    super.configureData(sessionModel)
    contentModel = sessionModel

    if sessionModel?.conversation?.stickTop == true {
      contentView.backgroundColor = LocalConversationUIConfig.shared.conversationProperties.itemStickTopBackground ?? .funConversationBackgroundColor
    } else {
      contentView.backgroundColor = LocalConversationUIConfig.shared.conversationProperties.itemBackground ?? .white
    }
  }
}
