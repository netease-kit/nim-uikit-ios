// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

@objcMembers
open class ChatMessageRevokeCell: NormalChatMessageBaseCell {
  public lazy var revokeLabelLeft: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = chatLocalizable("message_recalled")
    label.textAlignment = .left
    label.lineBreakMode = .byTruncatingTail
    label.accessibilityIdentifier = "id.messageText"
    return label
  }()

  public lazy var revokeLabelRight: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = chatLocalizable("message_recalled")
    label.textAlignment = .left
    label.lineBreakMode = .byTruncatingTail
    label.accessibilityIdentifier = "id.messageText"
    return label
  }()

  public var reeditButton = UIButton(type: .custom)
  public var reeditButtonW: NSLayoutConstraint?

  override open func layoutSubviews() {
    super.layoutSubviews()
    guard contentModel != nil else { return }
    showLeftOrRight(showRight: IMKitClient.instance.isMe(contentModel?.message?.senderId))
  }

  override open func commonUILeft() {
    super.commonUILeft()
    bubbleImageLeft.addSubview(revokeLabelLeft)
    NSLayoutConstraint.activate([
      revokeLabelLeft.leadingAnchor.constraint(equalTo: bubbleImageLeft.leadingAnchor, constant: 16),
      revokeLabelLeft.trailingAnchor.constraint(equalTo: bubbleImageLeft.trailingAnchor, constant: -16),
      revokeLabelLeft.topAnchor.constraint(equalTo: bubbleImageLeft.topAnchor),
      revokeLabelLeft.bottomAnchor.constraint(equalTo: bubbleImageLeft.bottomAnchor),
    ])
  }

  override open func commonUIRight() {
    super.commonUIRight()
    bubbleImageRight.addSubview(revokeLabelRight)

    reeditButton.translatesAutoresizingMaskIntoConstraints = false
    reeditButton.accessibilityIdentifier = "id.reeditButton"
    reeditButton.setImage(UIImage.ne_imageNamed(name: "right_arrow"), for: .normal)
    reeditButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    reeditButton.setTitleColor(UIColor.ne_normalTheme, for: .normal)
    reeditButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -30, bottom: 0, right: 0)
    reeditButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 70, bottom: 0, right: 0)
    bubbleImageRight.addSubview(reeditButton)

    reeditButtonW = reeditButton.widthAnchor.constraint(equalToConstant: 86)
    reeditButtonW?.isActive = true
    NSLayoutConstraint.activate([
      revokeLabelRight.leadingAnchor.constraint(equalTo: bubbleImageRight.leadingAnchor, constant: 16),
      revokeLabelRight.centerYAnchor.constraint(equalTo: bubbleImageRight.centerYAnchor),
      reeditButton.leadingAnchor.constraint(equalTo: revokeLabelRight.trailingAnchor, constant: 8),
      reeditButton.trailingAnchor.constraint(equalTo: bubbleImageRight.trailingAnchor, constant: -8),
      reeditButton.centerYAnchor.constraint(equalTo: bubbleImageRight.centerYAnchor),
    ])
    reeditButton.addTarget(self, action: #selector(reeditEvent), for: .touchUpInside)
  }

  override open func showLeftOrRight(showRight: Bool) {
    super.showLeftOrRight(showRight: showRight)

    // Feishu revoke rows retain the ordinary directional message surface.
    replyViewLeftHeightAnchor?.constant = 0
    replyViewRightHeightAnchor?.constant = 0
    replyViewLeft.isHidden = true
    replyViewRight.isHidden = true
    replyLabelLeft.isHidden = true
    replyLabelRight.isHidden = true
    reactionViewLeft.isHidden = true
    reactionViewRight.isHidden = true
    reactionBackdropLeft.isHidden = true
    reactionBackdropRight.isHidden = true

    revokeLabelLeft.isHidden = showRight
    revokeLabelRight.isHidden = !showRight
    fullNameLabel.isHidden = showRight || (contentModel?.fullNameHeight ?? 0) <= 0
    activityView.isHidden = true
    readView.isHidden = true
    selectedButton.isHidden = true
    pinLabelLeft.isHidden = true
    pinImageLeft.isHidden = true
    pinLabelRight.isHidden = true
    pinImageRight.isHidden = true
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    let isMyMessage = IMKitClient.instance.isMe(model.message?.senderId)
    revokeLabelLeft.font = UIFont.systemFont(ofSize: ChatUIConfig.shared.messageProperties.receiveMessageTextSize)
    revokeLabelRight.font = UIFont.systemFont(ofSize: ChatUIConfig.shared.messageProperties.selfMessageTextSize)
    revokeLabelLeft.textColor = ChatUIConfig.shared.messageProperties.receiveMessageTextColor
    revokeLabelRight.textColor = ChatUIConfig.shared.messageProperties.selfMessageTextColor

    let currentTime = Date().timeIntervalSince1970
    if Int(currentTime - model.revokeTime) >= ChatUIConfig.shared.revokeEditTimeGap * 60 {
      model.timeOut = true
    }

    let showsReedit = isMyMessage && model.isReedit && !model.timeOut
    reeditButtonW?.constant = showsReedit ? 86 : 0
    reeditButton.isHidden = !showsReedit
    if showsReedit {
      reeditButton.setTitle(chatLocalizable("message_reedit"), for: .normal)
    }
    let isEnglish = NEAppLanguageUtil.getCurrentLanguage() == .english
    model.contentSize = CGSize(width: isEnglish ? (showsReedit ? 248 : 160) : (showsReedit ? 218 : 130),
                               height: chat_min_h)

    super.setModel(model, isMyMessage)
    resetReactionSurfaceForReuse()
    showLeftOrRight(showRight: isMyMessage)
  }

  func reeditEvent(button: UIButton) {
    delegate?.didTapReeditButton(self, contentModel)
  }
}
