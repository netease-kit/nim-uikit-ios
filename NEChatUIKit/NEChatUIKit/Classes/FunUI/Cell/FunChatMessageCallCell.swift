// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunChatMessageCallCell: FunChatMessageBaseCell {
  public lazy var contentLabelLeft: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isEnabled = false
    label.numberOfLines = 0
    label.isUserInteractionEnabled = false
    label.font = messageTextFont
    label.textAlignment = .center
    label.backgroundColor = .clear
    label.accessibilityIdentifier = "id.chatMessageCallText"
    return label
  }()

  public lazy var contentLabelRight: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isEnabled = false
    label.numberOfLines = 0
    label.isUserInteractionEnabled = false
    label.font = messageTextFont
    label.textAlignment = .center
    label.backgroundColor = .clear
    label.accessibilityIdentifier = "id.chatMessageCallText"
    return label
  }()

  override open func commonUILeft() {
    super.commonUILeft()
    bubbleImageLeft.addSubview(contentLabelLeft)
    NSLayoutConstraint.activate([
      contentLabelLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor, constant: -chat_content_margin),
      contentLabelLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: chat_content_margin + funMargin),
      contentLabelLeft.centerYAnchor.constraint(equalTo: bubbleImageLeft.centerYAnchor),
    ])
  }

  override open func commonUIRight() {
    super.commonUIRight()
    bubbleImageRight.addSubview(contentLabelRight)
    NSLayoutConstraint.activate([
      contentLabelRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: -(chat_content_margin + funMargin)),
      contentLabelRight.leftAnchor.constraint(equalTo: bubbleImageRight.leftAnchor, constant: chat_content_margin),
      contentLabelRight.centerYAnchor.constraint(equalTo: bubbleImageRight.centerYAnchor),
    ])

    activityView.removeFromSuperview()
  }

  override open func showLeftOrRight(showRight: Bool) {
    super.showLeftOrRight(showRight: showRight)
    contentLabelLeft.isHidden = showRight
    contentLabelRight.isHidden = !showRight
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    super.setModel(model, isSend)
    let contentLabel = isSend ? contentLabelRight : contentLabelLeft
    if let m = model as? MessageCallRecordModel {
      contentLabel.attributedText = m.attributeStr
    }
  }
}
