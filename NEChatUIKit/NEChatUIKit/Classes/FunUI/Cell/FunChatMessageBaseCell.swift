// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunChatMessageBaseCell: NEBaseChatMessageCell {
  public let funMargin: CGFloat = 5.2
  public let replyHeight: CGFloat = 52

  public lazy var replyLabelLeft: UILabel = {
    let replyLabelLeft = UILabel()
    replyLabelLeft.numberOfLines = 2
    replyLabelLeft.textColor = .ne_greyText
    replyLabelLeft.translatesAutoresizingMaskIntoConstraints = false
    replyLabelLeft.font = UIFont.systemFont(ofSize: 13)
    replyLabelLeft.accessibilityIdentifier = "id.messageReply"
    return replyLabelLeft
  }()

  public lazy var replyTextViewLeft: UIView = {
    let replyTextView = UIView()
    replyTextView.translatesAutoresizingMaskIntoConstraints = false
    replyTextView.backgroundColor = .funChatInputReplyBg
    replyTextView.layer.cornerRadius = 4
    replyTextView.accessibilityIdentifier = "id.replyTextView"

    replyTextView.addSubview(replyLabelLeft)
    NSLayoutConstraint.activate([
      replyLabelLeft.topAnchor.constraint(equalTo: replyTextView.topAnchor, constant: 4),
      replyLabelLeft.bottomAnchor.constraint(equalTo: replyTextView.bottomAnchor, constant: -4),
      replyLabelLeft.leftAnchor.constraint(equalTo: replyTextView.leftAnchor, constant: 12),
      replyLabelLeft.rightAnchor.constraint(equalTo: replyTextView.rightAnchor, constant: -12),
    ])
    return replyTextView
  }()

  public lazy var replyViewLeft: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear

    view.addSubview(replyTextViewLeft)
    NSLayoutConstraint.activate([
      replyTextViewLeft.topAnchor.constraint(equalTo: view.topAnchor, constant: chat_content_margin),
      replyTextViewLeft.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
      replyTextViewLeft.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
      replyTextViewLeft.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -0),
    ])
    return view
  }()

  public var replyViewLeftHeightAnchor: NSLayoutConstraint?
  public var replyViewLeftHeight: CGFloat = 0 {
    didSet {
      replyTextViewLeft.isHidden = replyViewLeftHeight == 0
      replyViewLeftHeightAnchor?.constant = replyViewLeftHeight
    }
  }

  // Right

  public lazy var replyLabelRight: UILabel = {
    let replyLabelRight = UILabel()
    replyLabelRight.numberOfLines = 2
    replyLabelRight.textColor = .ne_greyText
    replyLabelRight.translatesAutoresizingMaskIntoConstraints = false
    replyLabelRight.font = UIFont.systemFont(ofSize: 13)
    replyLabelRight.accessibilityIdentifier = "id.messageReply"
    return replyLabelRight
  }()

  public lazy var replyTextViewRight: UIView = {
    let replyTextView = UIView()
    replyTextView.translatesAutoresizingMaskIntoConstraints = false
    replyTextView.backgroundColor = .funChatInputReplyBg
    replyTextView.layer.cornerRadius = 4
    replyTextView.accessibilityIdentifier = "id.replyTextView"

    replyTextView.addSubview(replyLabelRight)
    NSLayoutConstraint.activate([
      replyLabelRight.topAnchor.constraint(equalTo: replyTextView.topAnchor, constant: 4),
      replyLabelRight.bottomAnchor.constraint(equalTo: replyTextView.bottomAnchor, constant: -4),
      replyLabelRight.leftAnchor.constraint(equalTo: replyTextView.leftAnchor, constant: 12),
      replyLabelRight.rightAnchor.constraint(equalTo: replyTextView.rightAnchor, constant: -12),
    ])
    return replyTextView
  }()

  public lazy var replyViewRight: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear

    view.addSubview(replyTextViewRight)
    NSLayoutConstraint.activate([
      replyTextViewRight.topAnchor.constraint(equalTo: view.topAnchor, constant: chat_content_margin),
      replyTextViewRight.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
      replyTextViewRight.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
      replyTextViewRight.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -0),
    ])
    return view
  }()

  public var replyViewRightHeightAnchor: NSLayoutConstraint?

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
    addReplyGesture()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func commonUI() {
    commonUIRight()
    commonUILeft()
  }

  open func commonUILeft() {
    contentView.addSubview(replyViewLeft)
    replyViewLeftHeightAnchor = replyViewLeft.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    replyViewLeftHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      replyViewLeft.topAnchor.constraint(equalTo: bubbleImageLeft.bottomAnchor, constant: 0),
      replyViewLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: funMargin),
      replyViewLeft.widthAnchor.constraint(lessThanOrEqualToConstant: chat_content_maxW - funMargin),
    ])
  }

  open func commonUIRight() {
    contentView.addSubview(replyViewRight)
    replyViewRightHeightAnchor = replyViewRight.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    replyViewRightHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      replyViewRight.topAnchor.constraint(equalTo: bubbleImageRight.bottomAnchor, constant: 0),
      replyViewRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: -funMargin),
      replyViewRight.widthAnchor.constraint(lessThanOrEqualToConstant: chat_content_maxW - funMargin),
    ])
  }

  override open func showLeftOrRight(showRight: Bool) {
    super.showLeftOrRight(showRight: showRight)
    replyViewLeft.isHidden = showRight
    replyTextViewLeft.isHidden = showRight
    replyLabelLeft.isHidden = showRight
    replyViewRight.isHidden = !showRight
    replyTextViewRight.isHidden = !showRight
    replyLabelRight.isHidden = !showRight
  }

  open func addReplyGesture() {
    let replyViewTapLeft = UITapGestureRecognizer(target: self, action: #selector(tapReplyView(tap:)))
    replyViewTapLeft.cancelsTouchesInView = false
    replyViewLeft.addGestureRecognizer(replyViewTapLeft)

    let replyViewTapRight = UITapGestureRecognizer(target: self, action: #selector(tapReplyView(tap:)))
    replyViewTapRight.cancelsTouchesInView = false
    replyViewRight.addGestureRecognizer(replyViewTapRight)
  }

  open func tapReplyView(tap: UITapGestureRecognizer) {
    delegate?.didTapMessageView(self, contentModel, contentModel?.replyedModel)
  }

  func showReplyView(_ isSend: Bool, _ show: Bool) {
    let replyLabel = isSend ? replyLabelRight : replyLabelLeft
    let replyTextView = isSend ? replyTextViewRight : replyTextViewLeft
    let replyView = isSend ? replyViewRight : replyViewLeft
    let replyViewHeightAnchor = isSend ? replyViewRightHeightAnchor : replyViewLeftHeightAnchor
    replyLabel.isHidden = !show
    replyTextView.isHidden = !show
    replyView.isHidden = !show
    replyViewHeightAnchor?.constant = replyHeight
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    super.setModel(model, isSend)
    let replyLabel = isSend ? replyLabelRight : replyLabelLeft

    if model.isRevoked == false,
       let text = model.replyText,
       let font = replyLabel.font {
      replyLabel.attributedText = NEEmotionTool.getAttWithStr(str: text,
                                                              font: font,
                                                              color: replyLabel.textColor)
      replyLabel.accessibilityValue = text
      showReplyView(isSend, true)
    } else {
      replyLabel.text = nil
      showReplyView(isSend, false)
    }
  }

  override open func initProperty() {
    super.initProperty()

    readView.borderLayer.strokeColor = UIColor.funChatThemeColor.cgColor
    readView.sectorLayer.fillColor = UIColor.funChatThemeColor.cgColor

    var image = ChatUIConfig.shared.messageProperties.leftBubbleBg ?? UIImage.ne_imageNamed(name: "chat_message_receive_fun")
    bubbleImageLeft.image = image?
      .resizableImage(withCapInsets: ChatUIConfig.shared.messageProperties.backgroundImageCapInsets)

    image = ChatUIConfig.shared.messageProperties.rightBubbleBg ?? UIImage.ne_imageNamed(name: "chat_message_send_fun")
    bubbleImageRight.image = image?
      .resizableImage(withCapInsets: ChatUIConfig.shared.messageProperties.backgroundImageCapInsets)

    selectedButton.setImage(.ne_imageNamed(name: "fun_select"), for: .selected)
  }

  override open func baseCommonUI() {
    super.baseCommonUI()
    setAvatarImgSize(size: fun_chat_min_h)

    contentView.updateLayoutConstraint(firstItem: fullNameLabel, seconedItem: avatarImageLeft, attribute: .left, constant: 8 + funMargin)
    contentView.updateLayoutConstraint(firstItem: fullNameLabel, seconedItem: avatarImageLeft, attribute: .top, constant: -4)

    contentView.updateLayoutConstraint(firstItem: pinLabelLeft, seconedItem: bubbleImageLeft, attribute: .left, constant: 14 + funMargin)
    contentView.updateLayoutConstraint(firstItem: pinLabelRight, seconedItem: bubbleImageRight, attribute: .right, constant: -funMargin)
  }

  override open func initSubviewsLayout() {
    if ChatUIConfig.shared.messageProperties.avatarType == .cycle {
      avatarImageRight.layer.cornerRadius = 21.0
      avatarImageLeft.layer.cornerRadius = 21.0
    } else if ChatUIConfig.shared.messageProperties.avatarCornerRadius > 0 {
      avatarImageRight.layer.cornerRadius = ChatUIConfig.shared.messageProperties.avatarCornerRadius
      avatarImageLeft.layer.cornerRadius = ChatUIConfig.shared.messageProperties.avatarCornerRadius
    } else {
      avatarImageRight.layer.cornerRadius = 4
      avatarImageLeft.layer.cornerRadius = 4
    }
  }
}
