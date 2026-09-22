// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

@objcMembers
open class FunChatMessageTextCell: FunChatMessageBaseCell {
  var isLongPress: Bool = false
  private var adjustsReplyReaction = false

  // MARK: - 译文气泡（Fun 皮肤：独立白色圆角气泡，浮于原文气泡下方）

  public lazy var translationBubbleLeft: UIView = makeTranslationBubble(isSend: false)
  public lazy var translationBubbleRight: UIView = makeTranslationBubble(isSend: true)

  public lazy var translationTextLeft: UILabel = .init()
  public lazy var translationTextRight: UILabel = .init()

  // 同时存在回复和译文时，布局顺序为：原文 -> 译文 -> 回复。
  private var replyViewLeftTopToBubble: NSLayoutConstraint?
  private var replyViewLeftTopToTranslation: NSLayoutConstraint?
  private var replyViewRightTopToBubble: NSLayoutConstraint?
  private var replyViewRightTopToTranslation: NSLayoutConstraint?
  private var translationBubbleWidthLeft: NSLayoutConstraint?
  private var translationBubbleWidthRight: NSLayoutConstraint?

  private func makeTranslationBubble(isSend: Bool) -> UIView {
    let bubble = UIView()
    bubble.translatesAutoresizingMaskIntoConstraints = false
    bubble.backgroundColor = .funChatTranslationBubbleBg
    bubble.layer.cornerRadius = 4 // 圆角调小（原 8 → 4）
    bubble.layer.masksToBounds = true
    bubble.isHidden = true

    let backgroundView = UIImageView()
    backgroundView.translatesAutoresizingMaskIntoConstraints = false
    backgroundView.contentMode = .scaleToFill
    backgroundView.image = translationBubbleImage(isSend: isSend)
    bubble.addSubview(backgroundView)
    bubble.sendSubviewToBack(backgroundView)
    NSLayoutConstraint.activate([
      backgroundView.leftAnchor.constraint(equalTo: bubble.leftAnchor),
      backgroundView.rightAnchor.constraint(equalTo: bubble.rightAnchor),
      backgroundView.topAnchor.constraint(equalTo: bubble.topAnchor),
      backgroundView.bottomAnchor.constraint(equalTo: bubble.bottomAnchor),
    ])

    // 1. 译文正文
    let textLabel = UILabel()
    textLabel.translatesAutoresizingMaskIntoConstraints = false
    textLabel.numberOfLines = 0
    textLabel.font = messageTextFont
    textLabel.textColor = .funChatTranslationTextColor
    textLabel.accessibilityIdentifier = "id.translationText"
    let longPress = UILongPressGestureRecognizer(target: self, action: #selector(onTranslationLongPress(_:)))
    textLabel.isUserInteractionEnabled = true
    textLabel.addGestureRecognizer(longPress)
    let retryTap = UITapGestureRecognizer(target: self, action: #selector(onTranslationRetryTap(_:)))
    textLabel.addGestureRecognizer(retryTap)

    // 2. 底部「图标 + 译文」footer（取代顶部 tagLabel）
    let footerView = UIView()
    footerView.translatesAutoresizingMaskIntoConstraints = false

    let iconView = UIImageView(image: chatUIKitLoader.loadImage("chat_translation"))
    iconView.translatesAutoresizingMaskIntoConstraints = false
    iconView.contentMode = .scaleAspectFit

    let footerLabel = UILabel()
    footerLabel.translatesAutoresizingMaskIntoConstraints = false
    footerLabel.text = chatLocalizable("chat_translate_tag")
    footerLabel.font = .systemFont(ofSize: 12)
    footerLabel.textColor = UIColor(white: 0, alpha: 0.4)

    footerView.addSubview(iconView)
    footerView.addSubview(footerLabel)
    NSLayoutConstraint.activate([
      iconView.leftAnchor.constraint(equalTo: footerView.leftAnchor),
      iconView.centerYAnchor.constraint(equalTo: footerView.centerYAnchor),
      iconView.widthAnchor.constraint(equalToConstant: 14),
      iconView.heightAnchor.constraint(equalToConstant: 14),

      footerLabel.leftAnchor.constraint(equalTo: iconView.rightAnchor, constant: 4),
      footerLabel.centerYAnchor.constraint(equalTo: footerView.centerYAnchor),
      footerLabel.rightAnchor.constraint(equalTo: footerView.rightAnchor),
      footerView.heightAnchor.constraint(equalToConstant: 20),
    ])
    // 气泡宽度不足时保证 footerView 不被裁切
    footerView.clipsToBounds = false
    footerLabel.setContentHuggingPriority(.required, for: .horizontal)
    footerLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

    bubble.addSubview(textLabel)
    bubble.addSubview(footerView)

    NSLayoutConstraint.activate([
      textLabel.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 8),
      textLabel.leftAnchor.constraint(equalTo: bubble.leftAnchor, constant: chat_content_margin + funMargin),
      textLabel.rightAnchor.constraint(equalTo: bubble.rightAnchor, constant: -chat_content_margin - funMargin),

      footerView.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 6),
      footerView.leftAnchor.constraint(equalTo: bubble.leftAnchor, constant: chat_content_margin + funMargin),
      footerView.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -8),
    ])

    if isSend {
      translationTextRight = textLabel
    } else {
      translationTextLeft = textLabel
    }
    return bubble
  }

  @objc private func onTranslationLongPress(_ gesture: UILongPressGestureRecognizer) {
    guard gesture.state == .began else { return }
    delegate?.didLongPressTranslationView?(self, contentModel)
  }

  @objc private func onTranslationRetryTap(_ gesture: UITapGestureRecognizer) {
    guard gesture.state == .ended,
          let model = contentModel as? MessageTextModel,
          model.translationFailed else { return }
    delegate?.didTapTranslationRetryView?(self, model)
  }

  public lazy var contentLabelLeft: NEChatTextView = {
    let label = NEChatTextView()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isEditable = false
    label.isSelectable = true
    label.isScrollEnabled = false
    label.showsVerticalScrollIndicator = false
    label.showsHorizontalScrollIndicator = false
    label.delegate = self
    label.textContainerInset = .zero
    label.contentInset = .zero
    label.textContainer.lineFragmentPadding = 0.0
    label.isUserInteractionEnabled = true
    label.font = messageTextFont
    label.backgroundColor = .clear
    label.dataDetectorTypes = [.link, .phoneNumber]
    label.accessibilityIdentifier = "id.messageText"
    let doubleTap = UITapGestureRecognizer(target: self, action: #selector(tapFunc))
    doubleTap.numberOfTapsRequired = 2
    label.addGestureRecognizer(doubleTap)
    let longTap = UILongPressGestureRecognizer(target: self, action: #selector(selectAllRange))
    label.addGestureRecognizer(longTap)
    return label
  }()

  public lazy var contentLabelRight: NEChatTextView = {
    let label = NEChatTextView()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isEditable = false
    label.isSelectable = true
    label.isScrollEnabled = false
    label.showsVerticalScrollIndicator = false
    label.showsHorizontalScrollIndicator = false
    label.delegate = self
    label.textContainerInset = .zero
    label.contentInset = .zero
    label.textContainer.lineFragmentPadding = 0.0
    label.isUserInteractionEnabled = true
    label.font = messageTextFont
    label.backgroundColor = .clear
    label.dataDetectorTypes = [.link, .phoneNumber]
    label.accessibilityIdentifier = "id.messageText"
    let doubleTap = UITapGestureRecognizer(target: self, action: #selector(tapFunc))
    doubleTap.numberOfTapsRequired = 2
    label.addGestureRecognizer(doubleTap)
    let longTap = UILongPressGestureRecognizer(target: self, action: #selector(selectAllRange))
    label.addGestureRecognizer(longTap)
    return label
  }()

  func tapFunc() {}

  /// Match SwiftUI's Fun translation bubble: footer plus the same 13.2pt
  /// horizontal content inset used by the message bubble.
  private var translationBubbleMinWidth: CGFloat {
    let tag = chatLocalizable("chat_translate_tag") as NSString
    let tagW = tag.size(withAttributes: [.font: UIFont.systemFont(ofSize: 12)]).width
    let horizontalInset = chat_content_margin + funMargin
    return horizontalInset * 2 + 14 + 4 + ceil(tagW)
  }

  override open func commonUILeft() {
    super.commonUILeft()
    bubbleImageLeft.addSubview(contentLabelLeft)
    NSLayoutConstraint.activate([
      contentLabelLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor, constant: -chat_content_margin),
      contentLabelLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: chat_content_margin + funMargin),
      contentLabelLeft.topAnchor.constraint(equalTo: bubbleImageLeft.topAnchor, constant: chat_content_margin),
      contentLabelLeft.bottomAnchor.constraint(equalTo: bubbleImageLeft.bottomAnchor, constant: -chat_content_margin),
    ])
    // 回复视图默认挂在原文气泡下方；有译文时切换到译文气泡下方。
    deactivateTopConstraints(for: replyViewLeft)
    replyViewLeftTopToBubble = replyViewLeft.topAnchor.constraint(
      equalTo: reactionBackdropLeft.bottomAnchor, constant: 0
    )
    replyViewLeftTopToTranslation = replyViewLeft.topAnchor.constraint(
      equalTo: translationBubbleLeft.bottomAnchor, constant: 0
    )

    // 译文气泡始终展示在原文气泡下方。
    contentView.addSubview(translationBubbleLeft)
    NSLayoutConstraint.activate([
      replyViewLeftTopToBubble!,
      translationBubbleLeft.topAnchor.constraint(equalTo: reactionBackdropLeft.bottomAnchor, constant: 4),
      translationBubbleLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: funMargin),
      translationBubbleLeft.widthAnchor.constraint(lessThanOrEqualToConstant: chat_content_maxW - funMargin),
      translationBubbleLeft.widthAnchor.constraint(greaterThanOrEqualToConstant: translationBubbleMinWidth),
    ])
    translationBubbleWidthLeft = translationBubbleLeft.widthAnchor.constraint(equalToConstant: translationBubbleMinWidth)
    translationBubbleWidthLeft?.priority = .defaultHigh
    translationBubbleWidthLeft?.isActive = true
  }

  override open func commonUIRight() {
    super.commonUIRight()
    bubbleImageRight.addSubview(contentLabelRight)
    NSLayoutConstraint.activate([
      contentLabelRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: -chat_content_margin - funMargin),
      contentLabelRight.leftAnchor.constraint(equalTo: bubbleImageRight.leftAnchor, constant: chat_content_margin),
      contentLabelRight.topAnchor.constraint(equalTo: bubbleImageRight.topAnchor, constant: chat_content_margin),
      contentLabelRight.bottomAnchor.constraint(equalTo: bubbleImageRight.bottomAnchor, constant: -chat_content_margin),
    ])
    // 回复视图默认挂在原文气泡下方；有译文时切换到译文气泡下方。
    deactivateTopConstraints(for: replyViewRight)
    replyViewRightTopToBubble = replyViewRight.topAnchor.constraint(
      equalTo: reactionBackdropRight.bottomAnchor, constant: 0
    )
    replyViewRightTopToTranslation = replyViewRight.topAnchor.constraint(
      equalTo: translationBubbleRight.bottomAnchor, constant: 0
    )

    // 译文气泡始终展示在原文气泡下方。
    contentView.addSubview(translationBubbleRight)
    NSLayoutConstraint.activate([
      replyViewRightTopToBubble!,
      translationBubbleRight.topAnchor.constraint(equalTo: reactionBackdropRight.bottomAnchor, constant: 4),
      translationBubbleRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: -funMargin),
      translationBubbleRight.widthAnchor.constraint(lessThanOrEqualToConstant: chat_content_maxW - funMargin),
      translationBubbleRight.widthAnchor.constraint(greaterThanOrEqualToConstant: translationBubbleMinWidth),
    ])
    translationBubbleWidthRight = translationBubbleRight.widthAnchor.constraint(equalToConstant: translationBubbleMinWidth)
    translationBubbleWidthRight?.priority = .defaultHigh
    translationBubbleWidthRight?.isActive = true
  }

  override open func prepareForReuse() {
    adjustsReplyReaction = false
    super.prepareForReuse()
  }

  private func hasVisibleReply(_ model: MessageContentModel) -> Bool {
    // The reply target can be resolved after the cell is first bound. The
    // model's reply state is authoritative in that interval; relying only on
    // replyText leaves the Reaction row at the old bottom spacing.
    [MessageType.text, .aiStreamText].contains(model.type) &&
      (model.isReply || !(model.replyText?.isEmpty ?? true)) &&
      !model.inMultiForward
  }

  private func shouldLiftReplyReaction(_ model: MessageContentModel) -> Bool {
    hasVisibleReply(model) && model.contentSize.height > fun_chat_min_h
  }

  override open func layoutSubviews() {
    if let model = contentModel {
      adjustsReplyReaction = shouldLiftReplyReaction(model)
    }
    super.layoutSubviews()
  }

  /// Keep the reaction row clear of the bottom edge for Fun text replies.
  /// The spacing is redistributed so the combined bubble height is unchanged.
  override open func reactionTopSpacing(for model: MessageContentModel) -> CGFloat {
    guard adjustsReplyReaction, shouldLiftReplyReaction(model) else {
      return super.reactionTopSpacing(for: model)
    }
    return super.reactionTopSpacing(for: model) - NEBaseChatMessageCell.reactionBottomPadding
  }

  override open func reactionBottomSpacing(for model: MessageContentModel) -> CGFloat {
    guard adjustsReplyReaction, shouldLiftReplyReaction(model) else {
      return super.reactionBottomSpacing(for: model)
    }
    return super.reactionBottomSpacing(for: model) + NEBaseChatMessageCell.reactionBottomPadding
  }

  private func deactivateTopConstraints(for view: UIView) {
    contentView.constraints
      .filter { ($0.firstItem as AnyObject?) === view && $0.firstAttribute == .top }
      .forEach { $0.isActive = false }
  }

  override open func showLeftOrRight(showRight: Bool) {
    super.showLeftOrRight(showRight: showRight)
    contentLabelLeft.isHidden = showRight
    contentLabelRight.isHidden = !showRight
    if showRight {
      translationBubbleLeft.isHidden = true
    }
  }

  override open func resetSelectRange() {
    contentLabelLeft.selectedRange = .init()
    contentLabelRight.selectedRange = .init()
  }

  override open func selectAllRange() {
    if contentModel?.message?.aiConfig?.aiStreamStatus == .MESSAGE_AI_STREAM_STATUS_STREAMING {
      return
    }
    let contentLabel = contentLabelLeft.isHidden ? contentLabelRight : contentLabelLeft
    let length = contentLabel.text.utf16.count
    let range = NSRange(location: 0, length: length)
    contentLabel.selectedRange = range
    contentModel?.selectRange = range
    delegate?.didLongPressMessageView(self, contentModel)
    contentLabel.becomeFirstResponder()
  }

  override open func setSelect(_ model: MessageContentModel, _ enableSelect: Bool = false) {
    super.setSelect(model, enableSelect)
    contentLabelLeft.isUserInteractionEnabled = !enableSelect
    contentLabelRight.isUserInteractionEnabled = !enableSelect
    bubbleImageLeft.isUserInteractionEnabled = !enableSelect
    bubbleImageRight.isUserInteractionEnabled = !enableSelect
  }

  override open func longPress(longPress: UILongPressGestureRecognizer) {
    isLongPress = true
    selectAllRange()
  }

  // MARK: - 译文绑定

  open func bindTranslation(_ model: MessageTextModel, isSend: Bool) {
    let bubble = isSend ? translationBubbleRight : translationBubbleLeft
    let textLabel = isSend ? translationTextRight : translationTextLeft
    let hasTranslation = model.translationInfo != nil &&
      !(model.translationInfo?.translatedText.isEmpty ?? true) &&
      model.translationVisible &&
      !model.inMultiForward
    let shouldShowFailure = model.translationFailed && model.translationVisible && !model.inMultiForward
    if hasTranslation || shouldShowFailure {
      textLabel.text = shouldShowFailure
        ? chatLocalizable("chat_translate_failed_retry")
        : model.translationInfo?.translatedText
      textLabel.textColor = shouldShowFailure ? UIColor.ne_normalTheme : .funChatTranslationTextColor
      bubble.isHidden = false
      let maxWidth = max(translationBubbleMinWidth, chat_content_maxW - funMargin)
      let horizontalInset = chat_content_margin + funMargin
      let measuredWidth = model.estimateTranslationTextWidth() + horizontalInset * 2
      let width = min(maxWidth, max(translationBubbleMinWidth, measuredWidth))
      if isSend {
        translationBubbleWidthRight?.constant = width
      } else {
        translationBubbleWidthLeft?.constant = width
      }
    } else {
      bubble.isHidden = true
    }
  }

  private func translationBubbleImage(isSend: Bool) -> UIImage? {
    let properties = ChatUIConfig.shared.messageProperties
    var image = isSend
      ? properties.selfMessageBgImage
      : properties.receiveMessageBgImage
    image = image ?? UIImage.ne_imageNamed(name: isSend
      ? "chat_message_send_fun"
      : "chat_message_receive_fun")
    if let insets = properties.backgroundImageCapInsets {
      return image?.resizableImage(withCapInsets: insets)
    }
    return image
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    adjustsReplyReaction = shouldLiftReplyReaction(model)
    super.setModel(model, isSend)
    isLongPress = false

    let contentLabel = isSend ? contentLabelRight : contentLabelLeft
    let bubbleW = isSend ? bubbleWRight : bubbleWLeft
    let hasTranslation = (model as? MessageTextModel).map { hasVisibleTranslation($0) } ?? false

    if let m = model as? MessageTextModel {
      contentLabel.attributedText = m.attributeStr
      contentLabel.accessibilityValue = m.message?.text
      contentSizeToFit(contentLabel, m)
      bindTranslation(m, isSend: isSend)
    }
    if let m = model as? MessageTextModel {
      let reactionView = isSend ? reactionViewRight : reactionViewLeft
      let leadingInset = reactionLeadingInset(for: m, isOutgoing: isSend)
      let trailingInset = reactionTrailingInset(for: m, isOutgoing: isSend)
      let reactionMaxWidth = max(26, chat_content_maxW - leadingInset - trailingInset)
      let reactionWidth = min(reactionMaxWidth,
                              max(reactionView.layoutWidth(forMaxWidth: reactionMaxWidth), 26))
      bubbleW?.constant = max(bubbleW?.constant ?? 0,
                              m.contentSize.width + funMargin,
                              reactionWidth + leadingInset + trailingInset)
    } else {
      bubbleW?.constant += funMargin
    }

    updateMessageSupplementTopConstraints(
      isSend: isSend,
      isReply: model.isReply,
      hasTranslation: hasTranslation
    )
  }

  private func hasVisibleTranslation(_ model: MessageTextModel) -> Bool {
    (model.translationFailed || (model.translationInfo != nil &&
      !(model.translationInfo?.translatedText.isEmpty ?? true))) &&
      model.translationVisible &&
      !model.inMultiForward
  }

  /// 同时存在回复和译文时按“原文 -> 译文 -> 回复”排列。
  private func updateMessageSupplementTopConstraints(isSend: Bool,
                                                     isReply: Bool,
                                                     hasTranslation: Bool) {
    if isSend {
      replyViewRightTopToBubble?.isActive = !isReply || !hasTranslation
      replyViewRightTopToTranslation?.isActive = isReply && hasTranslation
    } else {
      replyViewLeftTopToBubble?.isActive = !isReply || !hasTranslation
      replyViewLeftTopToTranslation?.isActive = isReply && hasTranslation
    }
  }
}

// MARK: - UITextViewDelegate

extension FunChatMessageTextCell: UITextViewDelegate {
  open func selectText() {
    let contentLabel = contentLabelLeft.isHidden ? contentLabelRight : contentLabelLeft
    let range = contentLabel.selectedRange
    contentModel?.selectRange = range
    delegate?.didLongPressMessageView(self, contentModel)
    if (contentModel?.selectRange?.length ?? 0) > 0 {
      contentLabel.becomeFirstResponder()
    } else {
      contentLabel.resignFirstResponder()
    }
  }

  override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    false
  }

  open func textViewDidChangeSelection(_ textView: UITextView) {
    if isLongPress,
       contentModel?.selectRange == nil {
      selectAllRange()
      return
    }
    if textView.selectedRange.length == 0 || contentModel?.selectRange == nil {
      contentModel?.selectRange = nil
      delegate?.didTextViewLoseFocus?(self, contentModel)
      isLongPress = false
    } else {
      selectText()
    }
  }

  func getTextSize(_ attributedText: NSAttributedString?) -> CGSize {
    NSAttributedString.getRealTextViewSize(attributedText, messageTextFont, messageMaxSize)
  }

  func contentSizeToFit(_ contentLabel: UITextView, _ model: MessageTextModel) {
    let titleSize = getTextSize(contentLabel.attributedText)
    if model.contentSize.height == fun_chat_min_h {
      contentLabel.textContainerInset = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
      return
    }
    let textHeight = titleSize.height
    let textViewHeight = model.textHeight
    if textHeight <= textViewHeight {
      let offsetY = (textViewHeight - textHeight) / 2
      contentLabel.textContainerInset = UIEdgeInsets(top: offsetY, left: 0, bottom: 0, right: 0)
    } else {
      contentLabel.textContainerInset = .zero
    }
  }

  open func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange) -> Bool {
    selectAllRange()
    return false
  }

  public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
    delegate?.didTapDetectedLink?(self, contentModel, URL)
    return false
  }
}
