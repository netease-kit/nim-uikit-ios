
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class ChatMessageReplyCell: ChatMessageTextCell {
  public lazy var replyLabelLeft: UILabel = {
    let replyLabel = UILabel()
    replyLabel.font = UIFont.systemFont(ofSize: 13)
    replyLabel.textColor = UIColor(hexString: "#929299")
    replyLabel.translatesAutoresizingMaskIntoConstraints = false
    replyLabel.accessibilityIdentifier = "id.messageReply"
    return replyLabel
  }()

  public lazy var replyLabelRight: UILabel = {
    let replyLabel = UILabel()
    replyLabel.font = UIFont.systemFont(ofSize: 13)
    replyLabel.textColor = UIColor(hexString: "#929299")
    replyLabel.translatesAutoresizingMaskIntoConstraints = false
    replyLabel.accessibilityIdentifier = "id.messageReply"
    return replyLabel
  }()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func commonUI() {
    commonUIRight()
    commonUILeft()
  }

  open func commonUILeft() {
    bubbleImageLeft.addSubview(replyLabelLeft)
    NSLayoutConstraint.activate([
      replyLabelLeft.leadingAnchor.constraint(equalTo: bubbleImageLeft.leadingAnchor, constant: chat_content_margin),
      replyLabelLeft.topAnchor.constraint(equalTo: bubbleImageLeft.topAnchor, constant: chat_content_margin),
      replyLabelLeft.heightAnchor.constraint(equalToConstant: 16.0),
      replyLabelLeft.trailingAnchor.constraint(equalTo: bubbleImageLeft.trailingAnchor, constant: -chat_content_margin),
    ])

    bubbleImageLeft.addSubview(contentLabelLeft)
    NSLayoutConstraint.activate([
      contentLabelLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor, constant: -chat_content_margin),
      contentLabelLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: chat_content_margin),
      contentLabelLeft.topAnchor.constraint(equalTo: replyLabelLeft.bottomAnchor, constant: chat_content_margin),
      contentLabelLeft.bottomAnchor.constraint(equalTo: bubbleImageLeft.bottomAnchor, constant: -chat_content_margin),
    ])
  }

  open func commonUIRight() {
    bubbleImageRight.addSubview(replyLabelRight)
    NSLayoutConstraint.activate([
      replyLabelRight.leadingAnchor.constraint(equalTo: bubbleImageRight.leadingAnchor, constant: chat_content_margin),
      replyLabelRight.topAnchor.constraint(equalTo: bubbleImageRight.topAnchor, constant: chat_content_margin),
      replyLabelRight.heightAnchor.constraint(equalToConstant: 16.0),
      replyLabelRight.trailingAnchor.constraint(equalTo: bubbleImageRight.trailingAnchor, constant: -chat_content_margin),
    ])

    bubbleImageRight.addSubview(contentLabelRight)
    NSLayoutConstraint.activate([
      contentLabelRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: -chat_content_margin),
      contentLabelRight.leftAnchor.constraint(equalTo: bubbleImageRight.leftAnchor, constant: chat_content_margin),
      contentLabelRight.topAnchor.constraint(equalTo: replyLabelRight.bottomAnchor, constant: chat_content_margin),
      contentLabelRight.bottomAnchor.constraint(equalTo: bubbleImageRight.bottomAnchor, constant: -chat_content_margin),
    ])
  }

  override open func showLeftOrRight(showRight: Bool) {
    super.showLeftOrRight(showRight: showRight)
    replyLabelLeft.isHidden = showRight
    replyLabelRight.isHidden = !showRight
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    let replyLabel = isSend ? replyLabelRight : replyLabelLeft

    if let text = model.replyText,
       let font = replyLabel.font {
      replyLabel.attributedText = NEEmotionTool.getAttWithStr(str: "| " + text,
                                                              font: font,
                                                              color: replyLabel.textColor)
      if let attriText = replyLabel.attributedText {
        let textSize = attriText.finalSize(font, CGSize(width: chat_text_maxW, height: CGFloat.greatestFiniteMagnitude))
        model.contentSize.width = max(textSize.width + chat_content_margin * 2, model.contentSize.width)
      }
    }

    super.setModel(model, isSend)
  }
}
