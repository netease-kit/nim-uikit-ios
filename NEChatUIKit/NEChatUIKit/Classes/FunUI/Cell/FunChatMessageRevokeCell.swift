// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

@objcMembers
open class FunChatMessageRevokeCell: FunChatMessageBaseCell {
  public lazy var revokeLabelLeft: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textAlignment = .center
    label.lineBreakMode = .byTruncatingMiddle
    label.accessibilityIdentifier = "id.messageText"
    return label
  }()

  public lazy var revokeLabelRight: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textAlignment = .center
    label.lineBreakMode = .byTruncatingMiddle
    label.accessibilityIdentifier = "id.messageText"
    return label
  }()

  public lazy var reeditButton: UIButton = {
    let button = UIButton(type: .custom)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
    button.setTitleColor(UIColor.ne_normalTheme, for: .normal)
    button.addTarget(self, action: #selector(reeditEvent), for: .touchUpInside)
    button.accessibilityIdentifier = "id.reeditButton"
    return button
  }()

  var revokeLabelRightXAnchor: NSLayoutConstraint?
  private var revokeLabelLeftCenterY: NSLayoutConstraint?
  private var revokeLabelRightCenterY: NSLayoutConstraint?

  override open func commonUILeft() {
    super.commonUILeft()
    contentView.addSubview(revokeLabelLeft)
    revokeLabelLeftCenterY = revokeLabelLeft.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
    NSLayoutConstraint.activate([
      revokeLabelLeft.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      revokeLabelLeftCenterY!,
      revokeLabelLeft.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 16),
      revokeLabelLeft.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
    ])
  }

  override open func commonUIRight() {
    super.commonUIRight()
    contentView.addSubview(revokeLabelRight)
    revokeLabelRightXAnchor = revokeLabelRight.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
    revokeLabelRightXAnchor?.isActive = true
    revokeLabelRightCenterY = revokeLabelRight.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
    NSLayoutConstraint.activate([
      revokeLabelRightCenterY!,
      revokeLabelRight.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 16),
      revokeLabelRight.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
    ])

    contentView.addSubview(reeditButton)
    NSLayoutConstraint.activate([
      reeditButton.leftAnchor.constraint(equalTo: revokeLabelRight.rightAnchor, constant: 8),
      reeditButton.widthAnchor.constraint(equalToConstant: 58),
      reeditButton.centerYAnchor.constraint(equalTo: revokeLabelRight.centerYAnchor),
    ])
  }

  override open func layoutSubviews() {
    super.layoutSubviews()
    guard contentModel != nil else { return }
    showLeftOrRight(showRight: IMKitClient.instance.isMe(contentModel?.message?.senderId))
  }

  override open func showLeftOrRight(showRight: Bool) {
    super.showLeftOrRight(showRight: showRight)

    // WeChat renders revoke rows like system tips: only centered text remains.
    replyViewLeftHeightAnchor?.constant = 0
    replyViewRightHeightAnchor?.constant = 0
    replyViewLeft.isHidden = true
    replyTextViewLeft.isHidden = true
    replyLabelLeft.isHidden = true
    replyViewRight.isHidden = true
    replyTextViewRight.isHidden = true
    replyLabelRight.isHidden = true
    reactionViewLeft.isHidden = true
    reactionViewRight.isHidden = true
    reactionBackdropLeft.isHidden = true
    reactionBackdropRight.isHidden = true
    reactionBackdropLeft.alpha = 0
    reactionBackdropRight.alpha = 0

    revokeLabelLeft.isHidden = showRight
    revokeLabelRight.isHidden = !showRight
    bubbleImageLeft.isHidden = true
    bubbleImageRight.isHidden = true
    userHeaderViewLeft.isHidden = true
    userHeaderViewRight.isHidden = true
    fullNameLabel.isHidden = true
    pinImageLeft.isHidden = true
    pinLabelLeft.isHidden = true
    pinImageRight.isHidden = true
    pinLabelRight.isHidden = true
    activityView.isHidden = true
    readView.isHidden = true
    selectedButton.isHidden = true
    contentView.backgroundColor = .clear
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    let isSend = IMKitClient.instance.isMe(model.message?.senderId)
    let revokeLabel = isSend ? revokeLabelRight : revokeLabelLeft
    let tipFont = UIFont.systemFont(ofSize: ChatUIConfig.shared.messageProperties.timeTextSize)
    revokeLabelLeft.font = tipFont
    revokeLabelRight.font = tipFont
    revokeLabelLeft.textColor = ChatUIConfig.shared.messageProperties.timeTextColor
    revokeLabelRight.textColor = ChatUIConfig.shared.messageProperties.timeTextColor

    let currentTime = Date().timeIntervalSince1970
    if Int(currentTime - model.revokeTime) >= ChatUIConfig.shared.revokeEditTimeGap * 60 {
      model.timeOut = true
    }

    let text = isSend
      ? chatLocalizable("You") + chatLocalizable("withdrew_message")
      : (model.fullName ?? "") + " " + chatLocalizable("withdrew_message")
    let textWidth = ceil((text as NSString).size(withAttributes: [.font: tipFont]).width)
    model.contentSize = CGSize(width: min(chat_content_maxW, max(90, textWidth)),
                               height: fun_chat_min_h)

    let showsReedit = isSend && model.isReedit && !model.timeOut
    reeditButton.isHidden = !showsReedit
    if showsReedit {
      reeditButton.setTitle(chatLocalizable("message_reedit"), for: .normal)
    }
    revokeLabelRightXAnchor?.constant = showsReedit ? -33 : 0

    super.setModel(model, isSend)
    resetReactionSurfaceForReuse()
    revokeLabel.text = text
    showLeftOrRight(showRight: isSend)

    let timeOffset = (model.timeContent?.isEmpty == false) ? chat_timeCellH / 2 : 0
    revokeLabelLeftCenterY?.constant = timeOffset
    revokeLabelRightCenterY?.constant = timeOffset
  }

  func reeditEvent(button: UIButton) {
    delegate?.didTapReeditButton(self, contentModel)
  }
}
