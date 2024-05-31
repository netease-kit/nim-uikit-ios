// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunChatMessageRichTextCell: FunChatMessageReplyCell {
  public lazy var titleLabelLeft: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isEnabled = false
    label.numberOfLines = 0
    label.isUserInteractionEnabled = false
    label.font = .systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.messageTextSize, weight: .semibold)
    label.backgroundColor = .clear
    label.accessibilityIdentifier = "id.messageTitle"
    return label
  }()

  public lazy var titleLabelRight: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isEnabled = false
    label.numberOfLines = 0
    label.isUserInteractionEnabled = false
    label.font = .systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.messageTextSize, weight: .semibold)
    label.backgroundColor = .clear
    label.accessibilityIdentifier = "id.messageTitle"
    return label
  }()

  public var titleLabelLeftHeightAnchor: NSLayoutConstraint?
  public var titleLabelRightHeightAnchor: NSLayoutConstraint?
  public var contentLabelLeftHeightAnchor: NSLayoutConstraint?
  public var contentLabelRightHeightAnchor: NSLayoutConstraint?

  override open func commonUI() {
    /// left
    bubbleImageLeft.addSubview(titleLabelLeft)
    titleLabelLeftHeightAnchor = titleLabelLeft.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    titleLabelLeftHeightAnchor?.priority = .fittingSizeLevel
    titleLabelLeftHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      titleLabelLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor, constant: -chat_content_margin),
      titleLabelLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: chat_content_margin + funMargin),
      titleLabelLeft.topAnchor.constraint(equalTo: bubbleImageLeft.topAnchor, constant: chat_content_margin),
    ])

    bubbleImageLeft.addSubview(contentLabelLeft)
    contentLabelLeftHeightAnchor = contentLabelLeft.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    contentLabelLeftHeightAnchor?.priority = .fittingSizeLevel
    contentLabelLeftHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      contentLabelLeft.rightAnchor.constraint(equalTo: titleLabelLeft.rightAnchor, constant: -0),
      contentLabelLeft.leftAnchor.constraint(equalTo: titleLabelLeft.leftAnchor, constant: 0),
      contentLabelLeft.topAnchor.constraint(equalTo: titleLabelLeft.bottomAnchor, constant: chat_content_margin),
    ])

    commonUILeft()

    /// right
    bubbleImageRight.addSubview(titleLabelRight)
    titleLabelRightHeightAnchor = titleLabelRight.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    titleLabelRightHeightAnchor?.priority = .fittingSizeLevel
    titleLabelRightHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      titleLabelRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: -chat_content_margin - funMargin),
      titleLabelRight.leftAnchor.constraint(equalTo: bubbleImageRight.leftAnchor, constant: chat_content_margin),
      titleLabelRight.topAnchor.constraint(equalTo: bubbleImageRight.topAnchor, constant: chat_content_margin),
    ])

    bubbleImageRight.addSubview(contentLabelRight)
    contentLabelRightHeightAnchor = contentLabelRight.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    contentLabelRightHeightAnchor?.priority = .fittingSizeLevel
    contentLabelRightHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      contentLabelRight.rightAnchor.constraint(equalTo: titleLabelRight.rightAnchor, constant: -0),
      contentLabelRight.leftAnchor.constraint(equalTo: titleLabelRight.leftAnchor, constant: 0),
      contentLabelRight.topAnchor.constraint(equalTo: titleLabelRight.bottomAnchor, constant: chat_content_margin),
    ])

    commonUIRight()
  }

  override open func showLeftOrRight(showRight: Bool) {
    super.showLeftOrRight(showRight: showRight)
    titleLabelLeft.isHidden = showRight
    titleLabelRight.isHidden = !showRight
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    super.setModel(model, isSend)
    let replyView = isSend ? replyTextViewRight : replyTextViewLeft
    let titleLabel = isSend ? titleLabelRight : titleLabelLeft
    let titleLabelHeightAnchor = isSend ? titleLabelRightHeightAnchor : titleLabelLeftHeightAnchor
    let contentLabelHeightAnchor = isSend ? contentLabelRightHeightAnchor : contentLabelLeftHeightAnchor

    if model.replyText == nil || model.replyText!.isEmpty {
      replyView.isHidden = true
    } else {
      replyView.isHidden = false
    }

    if let m = model as? MessageTextModel {
      contentLabelHeightAnchor?.constant = m.textHeight
    }

    if let m = model as? MessageRichTextModel {
      titleLabel.attributedText = m.titleAttributeStr
      titleLabelHeightAnchor?.constant = m.titleTextHeight
    }
  }
}
