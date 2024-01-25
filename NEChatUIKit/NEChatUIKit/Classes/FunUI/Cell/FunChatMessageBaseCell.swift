// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunChatMessageBaseCell: NEBaseChatMessageCell {
  public let funMargin: CGFloat = 5.2
  override open func initProperty() {
    super.initProperty()
    timeLabel.backgroundColor = .funChatBackgroundColor

    readView.borderLayer.strokeColor = UIColor.funChatThemeColor.cgColor
    readView.sectorLayer.fillColor = UIColor.funChatThemeColor.cgColor

    var image = NEKitChatConfig.shared.ui.messageProperties.leftBubbleBg ?? UIImage.ne_imageNamed(name: "chat_message_receive_fun")
    bubbleImageLeft.image = image?
      .resizableImage(withCapInsets: NEKitChatConfig.shared.ui.messageProperties.backgroundImageCapInsets)

    image = NEKitChatConfig.shared.ui.messageProperties.rightBubbleBg ?? UIImage.ne_imageNamed(name: "chat_message_send_fun")
    bubbleImageRight.image = image?
      .resizableImage(withCapInsets: NEKitChatConfig.shared.ui.messageProperties.backgroundImageCapInsets)

    seletedBtn.setImage(.ne_imageNamed(name: "fun_select"), for: .selected)
  }

  override open func baseCommonUI() {
    super.baseCommonUI()
    setAvatarImgSize(size: 42)

    contentView.updateLayoutConstraint(firstItem: fullNameLabel, seconedItem: avatarImageLeft, attribute: .left, constant: 8 + funMargin)
    contentView.updateLayoutConstraint(firstItem: fullNameLabel, seconedItem: avatarImageLeft, attribute: .top, constant: -4)
  }

  override open func initSubviewsLayout() {
    if NEKitChatConfig.shared.ui.messageProperties.avatarType == .rectangle,
       NEKitChatConfig.shared.ui.messageProperties.avatarCornerRadius > 0 {
      avatarImageRight.layer.cornerRadius = NEKitChatConfig.shared.ui.messageProperties.avatarCornerRadius
      avatarImageLeft.layer.cornerRadius = NEKitChatConfig.shared.ui.messageProperties.avatarCornerRadius
    } else if NEKitChatConfig.shared.ui.messageProperties.avatarType == .cycle {
      avatarImageRight.layer.cornerRadius = 21.0
      avatarImageLeft.layer.cornerRadius = 21.0
    } else {
      avatarImageRight.layer.cornerRadius = 4
      avatarImageLeft.layer.cornerRadius = 4
    }
  }
}
