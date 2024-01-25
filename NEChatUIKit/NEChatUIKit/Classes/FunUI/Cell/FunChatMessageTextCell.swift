// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunChatMessageTextCell: FunChatMessageBaseCell {
  public lazy var contentLabelLeft: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isEnabled = false
    label.numberOfLines = 0
    label.isUserInteractionEnabled = false
    label.font = .systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.messageTextSize)
    label.backgroundColor = .clear
    return label
  }()

  public lazy var contentLabelRight: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isEnabled = false
    label.numberOfLines = 0
    label.isUserInteractionEnabled = false
    label.font = .systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.messageTextSize)
    label.backgroundColor = .clear
    return label
  }()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open func commonUI() {
    bubbleImageLeft.addSubview(contentLabelLeft)
    NSLayoutConstraint.activate([
      contentLabelLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor, constant: -chat_content_margin),
      contentLabelLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: chat_content_margin + funMargin),
      contentLabelLeft.topAnchor.constraint(equalTo: bubbleImageLeft.topAnchor, constant: chat_content_margin),
      contentLabelLeft.bottomAnchor.constraint(equalTo: bubbleImageLeft.bottomAnchor, constant: -chat_content_margin),
    ])
    contentView.updateLayoutConstraint(firstItem: pinLabelLeft, seconedItem: bubbleImageLeft, attribute: .left, constant: 14 + funMargin)

    bubbleImageRight.addSubview(contentLabelRight)
    NSLayoutConstraint.activate([
      contentLabelRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: -chat_content_margin - funMargin),
      contentLabelRight.leftAnchor.constraint(equalTo: bubbleImageRight.leftAnchor, constant: chat_content_margin),
      contentLabelRight.topAnchor.constraint(equalTo: bubbleImageRight.topAnchor, constant: chat_content_margin),
      contentLabelRight.bottomAnchor.constraint(equalTo: bubbleImageRight.bottomAnchor, constant: -chat_content_margin),
    ])
    contentView.updateLayoutConstraint(firstItem: pinLabelRight, seconedItem: bubbleImageRight, attribute: .right, constant: -funMargin)
  }

  override open func showLeftOrRight(showRight: Bool) {
    super.showLeftOrRight(showRight: showRight)
    contentLabelLeft.isHidden = showRight
    contentLabelRight.isHidden = !showRight
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    super.setModel(model, isSend)
    let contentLabel = isSend ? contentLabelRight : contentLabelLeft
    let bubbleW = isSend ? bubbleWRight : bubbleWLeft

    if let m = model as? MessageTextModel {
      contentLabel.attributedText = m.attributeStr
    }
    bubbleW?.constant += funMargin
  }
}
