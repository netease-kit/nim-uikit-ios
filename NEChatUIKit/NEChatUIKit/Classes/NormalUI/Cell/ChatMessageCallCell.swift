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
    contentLabelLeft.font = NEKitChatConfig.shared.ui.messageTextSize
    contentLabelLeft.textAlignment = .center
    contentLabelLeft.backgroundColor = .clear
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
    contentLabelRight.font = NEKitChatConfig.shared.ui.messageTextSize
    contentLabelRight.textAlignment = .center
    contentLabelRight.backgroundColor = .clear
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

  override open func setModel(_ model: MessageContentModel) {
    super.setModel(model)
    if let m = model as? MessageCallRecordModel {
      if let isSend = model.message?.isOutgoingMsg, isSend {
        contentLabelRight.attributedText = m.attributeStr
        return
      }
      contentLabelLeft.attributedText = m.attributeStr
    }
  }
}
