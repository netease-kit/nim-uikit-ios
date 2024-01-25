// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunChatMessageReplyCell: FunChatMessageTextCell {
  public lazy var replyLabelLeft: UILabel = {
    let replyLabelLeft = UILabel()
    replyLabelLeft.numberOfLines = 2
    replyLabelLeft.textColor = .ne_greyText
    replyLabelLeft.translatesAutoresizingMaskIntoConstraints = false
    replyLabelLeft.font = UIFont.systemFont(ofSize: 13)
    return replyLabelLeft
  }()

  public lazy var replyTextViewLeft: UIView = {
    let replyTextView = UIView()
    replyTextView.translatesAutoresizingMaskIntoConstraints = false
    replyTextView.backgroundColor = .funChatInputReplyBg
    replyTextView.layer.cornerRadius = 4
    replyTextView.accessibilityIdentifier = "id.replyTextView"
    return replyTextView
  }()

  // Right

  public lazy var replyLabelRight: UILabel = {
    let replyLabelRight = UILabel()
    replyLabelRight.numberOfLines = 2
    replyLabelRight.textColor = .ne_greyText
    replyLabelRight.translatesAutoresizingMaskIntoConstraints = false
    replyLabelRight.font = UIFont.systemFont(ofSize: 13)
    return replyLabelRight
  }()

  public lazy var replyTextViewRight: UIView = {
    let replyTextView = UIView()
    replyTextView.translatesAutoresizingMaskIntoConstraints = false
    replyTextView.backgroundColor = .funChatInputReplyBg
    replyTextView.layer.cornerRadius = 4
    replyTextView.accessibilityIdentifier = "id.replyTextView"
    return replyTextView
  }()

  public var funPinLabelLeftTopAnchor: NSLayoutConstraint? // 左侧标记文案顶部布局约束
  public var funPinLabelRightTopAnchor: NSLayoutConstraint? // 右侧标记文案顶部布局约束

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
    addReplyGesture()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func commonUI() {
    super.commonUI()
    commonUIRight()
    commonUILeft()
  }

  open func commonUILeft() {
    contentView.addSubview(replyTextViewLeft)
    NSLayoutConstraint.activate([
      replyTextViewLeft.topAnchor.constraint(equalTo: bubbleImageLeft.bottomAnchor, constant: chat_content_margin),
      replyTextViewLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: funMargin),
      replyTextViewLeft.heightAnchor.constraint(equalToConstant: 44),
      replyTextViewLeft.widthAnchor.constraint(lessThanOrEqualToConstant: chat_content_maxW - funMargin),
    ])

    contentView.updateLayoutConstraint(firstItem: pinLabelLeft, seconedItem: bubbleImageLeft, attribute: .left, constant: 14 + funMargin)
    pinLabelLeftTopAnchor?.isActive = false
    funPinLabelLeftTopAnchor = pinLabelLeft.topAnchor.constraint(equalTo: replyTextViewLeft.bottomAnchor, constant: 4)
    funPinLabelLeftTopAnchor?.isActive = true

    replyTextViewLeft.addSubview(replyLabelLeft)
    NSLayoutConstraint.activate([
      replyLabelLeft.topAnchor.constraint(equalTo: replyTextViewLeft.topAnchor, constant: 4),
      replyLabelLeft.bottomAnchor.constraint(equalTo: replyTextViewLeft.bottomAnchor, constant: -4),
      replyLabelLeft.leftAnchor.constraint(equalTo: replyTextViewLeft.leftAnchor, constant: 12),
      replyLabelLeft.rightAnchor.constraint(equalTo: replyTextViewLeft.rightAnchor, constant: -12),
    ])
  }

  open func commonUIRight() {
    contentView.addSubview(replyTextViewRight)
    NSLayoutConstraint.activate([
      replyTextViewRight.topAnchor.constraint(equalTo: bubbleImageRight.bottomAnchor, constant: chat_content_margin),
      replyTextViewRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: -funMargin),
      replyTextViewRight.heightAnchor.constraint(equalToConstant: 44),
      replyTextViewRight.widthAnchor.constraint(lessThanOrEqualToConstant: chat_content_maxW - funMargin),
    ])

    contentView.updateLayoutConstraint(firstItem: pinLabelRight, seconedItem: bubbleImageRight, attribute: .right, constant: -funMargin)
    pinLabelRightTopAnchor?.isActive = false
    funPinLabelRightTopAnchor = pinLabelRight.topAnchor.constraint(equalTo: replyTextViewRight.bottomAnchor, constant: 4)
    funPinLabelRightTopAnchor?.isActive = true

    replyTextViewRight.addSubview(replyLabelRight)
    NSLayoutConstraint.activate([
      replyLabelRight.topAnchor.constraint(equalTo: replyTextViewRight.topAnchor, constant: 4),
      replyLabelRight.bottomAnchor.constraint(equalTo: replyTextViewRight.bottomAnchor, constant: -4),
      replyLabelRight.leftAnchor.constraint(equalTo: replyTextViewRight.leftAnchor, constant: 12),
      replyLabelRight.rightAnchor.constraint(equalTo: replyTextViewRight.rightAnchor, constant: -12),
    ])
  }

  override open func showLeftOrRight(showRight: Bool) {
    super.showLeftOrRight(showRight: showRight)
    replyTextViewLeft.isHidden = showRight
    replyTextViewRight.isHidden = !showRight
  }

  open func addReplyGesture() {
    let replyViewTapLeft = UITapGestureRecognizer(target: self, action: #selector(tapReplyView(tap:)))
    replyViewTapLeft.cancelsTouchesInView = false
    replyTextViewLeft.addGestureRecognizer(replyViewTapLeft)

    let replyViewTapRight = UITapGestureRecognizer(target: self, action: #selector(tapReplyView(tap:)))
    replyViewTapRight.cancelsTouchesInView = false
    replyTextViewRight.addGestureRecognizer(replyViewTapRight)
  }

  open func tapReplyView(tap: UITapGestureRecognizer) {
    print(#function)
    delegate?.didTapMessageView(self, contentModel)
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    super.setModel(model, isSend)
    let replyLabel = isSend ? replyLabelRight : replyLabelLeft

    if let text = model.replyText,
       let font = replyLabel.font {
      replyLabel.attributedText = NEEmotionTool.getAttWithStr(str: text,
                                                              font: font,
                                                              color: replyLabel.textColor)
    }
  }
}
