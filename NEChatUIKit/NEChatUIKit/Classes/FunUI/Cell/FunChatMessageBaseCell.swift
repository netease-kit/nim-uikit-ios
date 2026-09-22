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
    replyTextView.backgroundColor = .funChatReplyViewBg
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
    replyTextView.backgroundColor = .funChatReplyViewBg
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
      replyViewLeft.topAnchor.constraint(equalTo: reactionBackdropLeft.bottomAnchor, constant: 0),
      replyViewLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: funMargin),
      replyViewLeft.widthAnchor.constraint(lessThanOrEqualToConstant: chat_content_maxW - funMargin),
    ])
  }

  open func commonUIRight() {
    contentView.addSubview(replyViewRight)
    replyViewRightHeightAnchor = replyViewRight.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    replyViewRightHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      replyViewRight.topAnchor.constraint(equalTo: reactionBackdropRight.bottomAnchor, constant: 0),
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
    replyViewTapLeft.cancelsTouchesInView = true
    replyViewLeft.addGestureRecognizer(replyViewTapLeft)

    let replyViewTapRight = UITapGestureRecognizer(target: self, action: #selector(tapReplyView(tap:)))
    replyViewTapRight.cancelsTouchesInView = true
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
    // Revoke rows clear this reusable view's background. Restore it whenever
    // a normal replied message is rendered after that cell is reused.
    replyTextView.backgroundColor = .funChatReplyViewBg
    replyLabel.isHidden = !show
    replyTextView.isHidden = !show
    replyView.isHidden = !show
    replyViewHeightAnchor?.constant = show ? replyHeight : 0
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    super.setModel(model, isSend)
    let replyLabel = isSend ? replyLabelRight : replyLabelLeft

    if model.isRevoked == false,
       !model.inMultiForward,
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

    var image = ChatUIConfig.shared.messageProperties.receiveMessageBgImage ?? UIImage.ne_imageNamed(name: "chat_message_receive_fun")
    if let backgroundImageCapInsets = ChatUIConfig.shared.messageProperties.backgroundImageCapInsets {
      bubbleImageLeft.image = image?.resizableImage(withCapInsets: backgroundImageCapInsets)
    } else {
      bubbleImageLeft.image = image
      bubbleImageLeft.contentMode = .scaleAspectFill
    }

    image = ChatUIConfig.shared.messageProperties.selfMessageBgImage ?? UIImage.ne_imageNamed(name: "chat_message_send_fun")
    if let backgroundImageCapInsets = ChatUIConfig.shared.messageProperties.backgroundImageCapInsets {
      bubbleImageRight.image = image?.resizableImage(withCapInsets: backgroundImageCapInsets)
    } else {
      bubbleImageRight.image = image
      bubbleImageRight.contentMode = .scaleAspectFill
    }

    selectedButton.setImage(coreLoader.loadImage("fun_select"), for: .selected)
  }

  /// Restore the Fun skin whenever a reused cell asks the base class to
  /// recreate its bubble surface. Reaction expansion must never fall back to
  /// the ordinary WeChat bubble assets.
  override open func setBubbleImage() {
    var image = ChatUIConfig.shared.messageProperties.receiveMessageBgImage ?? UIImage.ne_imageNamed(name: "chat_message_receive_fun")
    bubbleImageLeft.backgroundColor = ChatUIConfig.shared.messageProperties.receiveMessageBgColor
    if let insets = ChatUIConfig.shared.messageProperties.backgroundImageCapInsets {
      bubbleImageLeft.image = image?.resizableImage(withCapInsets: insets)
      bubbleImageLeft.contentMode = .scaleToFill
    } else {
      bubbleImageLeft.image = image
      bubbleImageLeft.contentMode = .scaleAspectFill
    }

    image = ChatUIConfig.shared.messageProperties.selfMessageBgImage ?? UIImage.ne_imageNamed(name: "chat_message_send_fun")
    bubbleImageRight.backgroundColor = ChatUIConfig.shared.messageProperties.selfMessageBgColor
    if let insets = ChatUIConfig.shared.messageProperties.backgroundImageCapInsets {
      bubbleImageRight.image = image?.resizableImage(withCapInsets: insets)
      bubbleImageRight.contentMode = .scaleToFill
    } else {
      bubbleImageRight.image = image
      bubbleImageRight.contentMode = .scaleAspectFill
    }
  }

  override open func reactionLeadingInset(for model: MessageContentModel,
                                          isOutgoing: Bool) -> CGFloat {
    if usesFixedReactionSurface(for: model) {
      return 8 + (isOutgoing ? 0 : reactionBackdropTailInset(
        for: model,
        isOutgoing: isOutgoing
      )) + reactionBodyPadding(for: model)
    }
    // Fun text content adds the tail margin to the incoming leading side or
    // outgoing trailing side. Keep the Reaction capsules on the same column.
    return chat_content_margin + (isOutgoing ? 0 : funMargin)
  }

  override open func reactionTrailingInset(for model: MessageContentModel,
                                           isOutgoing: Bool) -> CGFloat {
    if usesFixedReactionSurface(for: model) {
      return 8 + (isOutgoing ? reactionBackdropTailInset(
        for: model,
        isOutgoing: isOutgoing
      ) : 0) + reactionBodyPadding(for: model)
    }
    return chat_content_margin + (isOutgoing ? funMargin : 0)
  }

  override open func reactionBackdropTailInset(for model: MessageContentModel,
                                                isOutgoing: Bool) -> CGFloat {
    usesFixedReactionSurface(for: model) ? funMargin : 0
  }

  override open func reactionTopSpacing(for model: MessageContentModel) -> CGFloat {
    return [.text, .audio, .richText].contains(model.type)
      ? 0
      : super.reactionTopSpacing(for: model)
  }

  override open func reactionBottomSpacing(for model: MessageContentModel) -> CGFloat {
    return [.text, .audio, .image, .video, .file, .richText, .location].contains(model.type)
      ? NEBaseChatMessageCell.reactionBottomPadding
      : super.reactionBottomSpacing(for: model)
  }

  override open func reactionBackdropImage(isOutgoing: Bool) -> UIImage? {
    var image = isOutgoing
      ? ChatUIConfig.shared.messageProperties.selfMessageBgImage
      : ChatUIConfig.shared.messageProperties.receiveMessageBgImage
    image = image ?? UIImage.ne_imageNamed(name: isOutgoing
      ? "chat_message_send_fun"
      : "chat_message_receive_fun")
    if let insets = ChatUIConfig.shared.messageProperties.backgroundImageCapInsets {
      return image?.resizableImage(withCapInsets: insets)
    }
    return image
  }

  override open func baseCommonUI() {
    super.baseCommonUI()

    userHeaderViewLeft.updateLayoutConstraint(firstItem: userHeaderViewLeft,
                                              secondItem: userHeaderViewLeft,
                                              attribute: .width,
                                              constant: fun_chat_min_h)
    userHeaderViewLeft.updateLayoutConstraint(firstItem: userHeaderViewLeft,
                                              secondItem: userHeaderViewLeft,
                                              attribute: .height,
                                              constant: fun_chat_min_h)

    userHeaderViewRight.updateLayoutConstraint(firstItem: userHeaderViewRight,
                                               secondItem: userHeaderViewRight,
                                               attribute: .width,
                                               constant: fun_chat_min_h)
    userHeaderViewRight.updateLayoutConstraint(firstItem: userHeaderViewRight,
                                               secondItem: userHeaderViewRight,
                                               attribute: .height,
                                               constant: fun_chat_min_h)

    contentView.updateLayoutConstraint(firstItem: fullNameLabel,
                                       secondItem: userHeaderViewLeft,
                                       attribute: .left,
                                       constant: 8 + funMargin)
    contentView.updateLayoutConstraint(firstItem: fullNameLabel,
                                       secondItem: userHeaderViewLeft,
                                       attribute: .top,
                                       constant: -4)

    contentView.updateLayoutConstraint(firstItem: pinLabelLeft,
                                       secondItem: bubbleImageLeft,
                                       attribute: .left,
                                       constant: 14 + funMargin)
    contentView.updateLayoutConstraint(firstItem: pinLabelRight,
                                       secondItem: bubbleImageRight,
                                       attribute: .right,
                                       constant: -funMargin)
  }

  override open func initSubviewsLayout() {
    if ChatUIConfig.shared.messageProperties.avatarType == .cycle {
      userHeaderViewRight.layer.cornerRadius = 21.0
      userHeaderViewLeft.layer.cornerRadius = 21.0
    } else if ChatUIConfig.shared.messageProperties.avatarCornerRadius > 0 {
      userHeaderViewRight.layer.cornerRadius = ChatUIConfig.shared.messageProperties.avatarCornerRadius
      userHeaderViewLeft.layer.cornerRadius = ChatUIConfig.shared.messageProperties.avatarCornerRadius
    } else {
      userHeaderViewRight.layer.cornerRadius = 4
      userHeaderViewLeft.layer.cornerRadius = 4
    }
  }
}
