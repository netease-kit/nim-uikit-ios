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

    var image = ChatUIConfig.shared.messageProperties.leftBubbleBg ?? UIImage.ne_imageNamed(name: "chat_message_receive_fun")
    bubbleImageLeft.image = image?
      .resizableImage(withCapInsets: ChatUIConfig.shared.messageProperties.backgroundImageCapInsets)

    image = ChatUIConfig.shared.messageProperties.rightBubbleBg ?? UIImage.ne_imageNamed(name: "chat_message_send_fun")
    bubbleImageRight.image = image?
      .resizableImage(withCapInsets: ChatUIConfig.shared.messageProperties.backgroundImageCapInsets)

    selectedButton.setImage(.ne_imageNamed(name: "fun_select"), for: .selected)
  }

  override open func baseCommonUI() {
    super.baseCommonUI()
    setAvatarImgSize(size: fun_chat_min_h)

    contentView.updateLayoutConstraint(firstItem: fullNameLabel, seconedItem: avatarImageLeft, attribute: .left, constant: 8 + funMargin)
    contentView.updateLayoutConstraint(firstItem: fullNameLabel, seconedItem: avatarImageLeft, attribute: .top, constant: -4)

    contentView.updateLayoutConstraint(firstItem: pinLabelLeft, seconedItem: bubbleImageLeft, attribute: .left, constant: 14 + funMargin)
    contentView.updateLayoutConstraint(firstItem: pinLabelRight, seconedItem: bubbleImageRight, attribute: .right, constant: -funMargin)
  }

  override open func initSubviewsLayout() {
    if ChatUIConfig.shared.messageProperties.avatarType == .cycle {
      avatarImageRight.layer.cornerRadius = 21.0
      avatarImageLeft.layer.cornerRadius = 21.0
    } else if ChatUIConfig.shared.messageProperties.avatarCornerRadius > 0 {
      avatarImageRight.layer.cornerRadius = ChatUIConfig.shared.messageProperties.avatarCornerRadius
      avatarImageLeft.layer.cornerRadius = ChatUIConfig.shared.messageProperties.avatarCornerRadius
    } else {
      avatarImageRight.layer.cornerRadius = 4
      avatarImageLeft.layer.cornerRadius = 4
    }
  }
}
