// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class ChatMessageCallCell: NormalChatMessageBaseCell {
  public let contentLabelLeft = UILabel()
  public let contentLabelRight = UILabel()
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func commonUI() {
    commonUIRight()
    commonUILeft()
  }

  open func commonUILeft() {
    contentLabelLeft.translatesAutoresizingMaskIntoConstraints = false
    contentLabelLeft.isEnabled = false
    contentLabelLeft.numberOfLines = 0
    contentLabelLeft.isUserInteractionEnabled = false
    contentLabelLeft.font = messageTextFont
    contentLabelLeft.textAlignment = .center
    contentLabelLeft.backgroundColor = .clear
    contentLabelLeft.accessibilityIdentifier = "id.chatMessageCallText"
    bubbleImageLeft.addSubview(contentLabelLeft)
    NSLayoutConstraint.activate([
      contentLabelLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor, constant: -chat_content_margin),
      contentLabelLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: chat_content_margin),
      contentLabelLeft.topAnchor.constraint(equalTo: bubbleImageLeft.topAnchor, constant: 0),
      contentLabelLeft.bottomAnchor.constraint(equalTo: bubbleImageLeft.bottomAnchor, constant: 0),
    ])
  }

  open func commonUIRight() {
    contentLabelRight.translatesAutoresizingMaskIntoConstraints = false
    contentLabelRight.isEnabled = false
    contentLabelRight.numberOfLines = 0
    contentLabelRight.isUserInteractionEnabled = false
    contentLabelRight.font = messageTextFont
    contentLabelRight.textAlignment = .center
    contentLabelRight.backgroundColor = .clear
    contentLabelRight.accessibilityIdentifier = "id.chatMessageCallText"
    bubbleImageRight.addSubview(contentLabelRight)
    NSLayoutConstraint.activate([
      contentLabelRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: -chat_content_margin),
      contentLabelRight.leftAnchor.constraint(equalTo: bubbleImageRight.leftAnchor, constant: chat_content_margin),
      contentLabelRight.topAnchor.constraint(equalTo: bubbleImageRight.topAnchor, constant: 0),
      contentLabelRight.bottomAnchor.constraint(equalTo: bubbleImageRight.bottomAnchor, constant: 0),
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
    if let m = model as? MessageCallRecordModel {
      let contentLabel = isSend ? contentLabelRight : contentLabelLeft
      contentLabel.attributedText = m.attributeStr
    }
  }
}
