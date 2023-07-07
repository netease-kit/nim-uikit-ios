//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunChatMessageBaseCell: NEBaseChatMessageCell {
  public let funMargin: CGFloat = 5.2
  override open func initProperty() {
    super.initProperty()
    readView.borderLayer.strokeColor = UIColor.funChatThemeColor.cgColor
    readView.sectorLayer.fillColor = UIColor.funChatThemeColor.cgColor

    var image = NEKitChatConfig.shared.ui.leftBubbleBg ?? UIImage.ne_imageNamed(name: "chat_message_receive_fun")
    bubbleImageLeft.image = image?
      .resizableImage(withCapInsets: UIEdgeInsets(top: 35, left: 25, bottom: 10, right: 25))

    image = NEKitChatConfig.shared.ui.rightBubbleBg ?? UIImage.ne_imageNamed(name: "chat_message_send_fun")
    bubbleImageRight.image = image?
      .resizableImage(withCapInsets: UIEdgeInsets(top: 35, left: 25, bottom: 10, right: 25))
  }

  override open func baseCommonUI() {
    super.baseCommonUI()
    setAvatarImgSize(size: 42)

    contentView.updateLayoutConstraint(firstItem: fullNameLabel, seconedItem: avatarImageLeft, attribute: .left, constant: 8 + funMargin)
    contentView.removeLayoutConstraint(firstItem: fullNameLabel, seconedItem: avatarImageLeft, attribute: .top)
    fullNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0).isActive = true
  }

  override open func initSubviewsLayout() {
    if NEKitChatConfig.shared.ui.avatarType == .rectangle,
       let radius = NEKitChatConfig.shared.ui.avatarCornerRadius {
      avatarImageRight.layer.cornerRadius = radius
      avatarImageLeft.layer.cornerRadius = radius
    } else if NEKitChatConfig.shared.ui.avatarType == .cycle {
      avatarImageRight.layer.cornerRadius = 21.0
      avatarImageLeft.layer.cornerRadius = 21.0
    } else {
      avatarImageRight.layer.cornerRadius = 4
      avatarImageLeft.layer.cornerRadius = 4
    }
  }
}
