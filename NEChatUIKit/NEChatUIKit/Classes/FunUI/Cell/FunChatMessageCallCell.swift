// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunChatMessageCallCell: FunChatMessageBaseCell {
  public let contentLabelLeft = UILabel()
  public let contentLabelRight = UILabel()
  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func commonUILeft() {
    super.commonUILeft()
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
      contentLabelLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: chat_content_margin + funMargin),
      contentLabelLeft.centerYAnchor.constraint(equalTo: bubbleImageLeft.centerYAnchor),
    ])
  }

  override open func commonUIRight() {
    super.commonUIRight()
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
