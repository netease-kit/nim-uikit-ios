// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NormalChatMessageBaseCell: NEBaseChatMessageCell {
  public var replyViewHeight: CGFloat = 24

  public var replyViewLeftHeightAnchor: NSLayoutConstraint?
  public lazy var replyViewLeft: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    view.addSubview(replyLabelLeft)
    NSLayoutConstraint.activate([
      replyLabelLeft.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
      replyLabelLeft.topAnchor.constraint(equalTo: view.topAnchor, constant: chat_content_margin),
      replyLabelLeft.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -0),
      replyLabelLeft.heightAnchor.constraint(equalToConstant: 16.0),
    ])
    return view
  }()

  public lazy var replyLabelLeft: UILabel = {
    let replyLabel = UILabel()
    replyLabel.font = UIFont.systemFont(ofSize: 13)
    replyLabel.textColor = UIColor(hexString: "#929299")
    replyLabel.translatesAutoresizingMaskIntoConstraints = false
    replyLabel.accessibilityIdentifier = "id.messageReply"
    return replyLabel
  }()

  public var replyViewRightHeightAnchor: NSLayoutConstraint?
  public lazy var replyViewRight: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    view.addSubview(replyLabelRight)
    NSLayoutConstraint.activate([
      replyLabelRight.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
      replyLabelRight.topAnchor.constraint(equalTo: view.topAnchor, constant: chat_content_margin),
      replyLabelRight.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -0),
      replyLabelRight.heightAnchor.constraint(equalToConstant: 16.0),
    ])
    return view
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
    super.init(coder: coder)
  }

  open func commonUI() {
    commonUIRight()
    commonUILeft()
  }

  open func commonUILeft() {
    bubbleImageLeft.addSubview(replyViewLeft)
    replyViewLeftHeightAnchor = replyViewLeft.heightAnchor.constraint(equalToConstant: replyViewHeight)
    replyViewLeftHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      replyViewLeft.leadingAnchor.constraint(equalTo: bubbleImageLeft.leadingAnchor, constant: chat_content_margin),
      replyViewLeft.topAnchor.constraint(equalTo: bubbleImageLeft.topAnchor, constant: 0),
      replyViewLeft.trailingAnchor.constraint(equalTo: bubbleImageLeft.trailingAnchor, constant: -chat_content_margin),
    ])
  }

  open func commonUIRight() {
    bubbleImageRight.addSubview(replyViewRight)
    replyViewRightHeightAnchor = replyViewRight.heightAnchor.constraint(equalToConstant: replyViewHeight)
    replyViewRightHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      replyViewRight.leadingAnchor.constraint(equalTo: bubbleImageRight.leadingAnchor, constant: chat_content_margin),
      replyViewRight.topAnchor.constraint(equalTo: bubbleImageRight.topAnchor, constant: 0),
      replyViewRight.trailingAnchor.constraint(equalTo: bubbleImageRight.trailingAnchor, constant: -chat_content_margin),
    ])
  }

  override open func showLeftOrRight(showRight: Bool) {
    super.showLeftOrRight(showRight: showRight)
    replyViewLeft.isHidden = showRight
    replyLabelLeft.isHidden = showRight
    replyViewRight.isHidden = !showRight
    replyLabelRight.isHidden = !showRight
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    let replyLabel = isSend ? replyLabelRight : replyLabelLeft
    let replyView = isSend ? replyViewRight : replyViewLeft
    let replyViewHeightAnchor = isSend ? replyViewRightHeightAnchor : replyViewLeftHeightAnchor

    if model.isRevoked == false,
       var text = model.replyText,
       let font = replyLabel.font {
      // 如果有回复的消息，需要在回复的消息前加上“| ”
      if text != chatLocalizable("message_not_found") {
        text = "| " + text
      }

      replyLabel.attributedText = NEEmotionTool.getAttWithStr(str: text,
                                                              font: font,
                                                              color: replyLabel.textColor)
      replyLabel.accessibilityValue = text

      if let attriText = replyLabel.attributedText {
        let textSize = NSAttributedString.getRealSize(attriText, font, CGSize(width: chat_text_maxW, height: CGFloat.greatestFiniteMagnitude))

        if let _ = model as? MessageTextModel {
          model.contentSize.width = max(textSize.width, model.textWidth) + chat_content_margin * 2
        } else {
          model.contentSize.width = max(textSize.width + chat_content_margin * 2, model.contentSize.width)
        }

        replyViewHeightAnchor?.constant = replyViewHeight
        replyLabel.isHidden = false
        replyView.isHidden = false
      }
    } else {
      replyLabel.text = nil
      replyViewHeightAnchor?.constant = 0
      replyLabel.isHidden = true
      replyView.isHidden = true
    }

    super.setModel(model, isSend)
  }
}
