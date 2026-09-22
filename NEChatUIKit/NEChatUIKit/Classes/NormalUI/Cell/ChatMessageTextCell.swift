
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

@objcMembers
open class ChatMessageTextCell: NormalChatMessageBaseCell {
  override open var usesInlineReactionSurface: Bool { true }
  var isLongPress: Bool = false

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

  // MARK: - 译文区域（Normal 皮肤：气泡内原文下方，分割线 + 译文正文 + 底部「图标+译文」标签）

  public lazy var translationAreaLeft: UIView = makeTranslationArea(isSend: false)
  public lazy var translationAreaRight: UIView = makeTranslationArea(isSend: true)

  public lazy var translationTextLabelLeft: UILabel = .init()
  public lazy var translationTextLabelRight: UILabel = .init()

  // 隐藏时强制高度为 0 的约束（激活 = 隐藏，停用 = 显示）
  private var translationAreaLeftHeightZero: NSLayoutConstraint?
  private var translationAreaRightHeightZero: NSLayoutConstraint?
  private var translationAreaLeftTopAnchor: NSLayoutConstraint?
  private var translationAreaRightTopAnchor: NSLayoutConstraint?

  private func makeTranslationArea(isSend: Bool) -> UIView {
    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    container.isHidden = true
    container.isUserInteractionEnabled = true

    // 将译文正文、底部译文标识行及整行空白区域统一纳入长按范围。
    let longPress = UILongPressGestureRecognizer(target: self, action: #selector(onTranslationLongPress(_:)))
    container.addGestureRecognizer(longPress)
    let retryTap = UITapGestureRecognizer(target: self, action: #selector(onTranslationRetryTap(_:)))
    container.addGestureRecognizer(retryTap)

    // 1. 分割线
    let divider = UIView()
    divider.translatesAutoresizingMaskIntoConstraints = false
    divider.backgroundColor = .normalChatTranslationDividerColor

    // 2. 译文正文
    let textLabel = UILabel()
    textLabel.translatesAutoresizingMaskIntoConstraints = false
    textLabel.numberOfLines = 0
    textLabel.font = messageTextFont // 与原文字体一致
    textLabel.textColor = .ne_darkText
    textLabel.accessibilityIdentifier = "id.translationText"
    textLabel.isUserInteractionEnabled = false

    // 3. 底部「图标 + 译文」footer
    let footerView = UIView()
    footerView.translatesAutoresizingMaskIntoConstraints = false

    let iconView = UIImageView(image: chatUIKitLoader.loadImage("chat_translation"))
    iconView.translatesAutoresizingMaskIntoConstraints = false
    iconView.contentMode = .scaleAspectFit

    let footerLabel = UILabel()
    footerLabel.translatesAutoresizingMaskIntoConstraints = false
    footerLabel.text = chatLocalizable("chat_translate_tag")
    footerLabel.font = .systemFont(ofSize: 12)
    footerLabel.textColor = .normalChatTranslationTagColor

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
    // container 宽度不足时保证 footerView 不被裁切
    footerView.clipsToBounds = false
    footerLabel.setContentHuggingPriority(.required, for: .horizontal)
    footerLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

    container.addSubview(divider)
    container.addSubview(textLabel)
    container.addSubview(footerView)

    NSLayoutConstraint.activate([
      divider.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
      divider.leftAnchor.constraint(equalTo: container.leftAnchor),
      divider.rightAnchor.constraint(equalTo: container.rightAnchor),
      divider.heightAnchor.constraint(equalToConstant: 0.5),

      textLabel.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 12),
      textLabel.leftAnchor.constraint(equalTo: container.leftAnchor),
      textLabel.rightAnchor.constraint(equalTo: container.rightAnchor),

      footerView.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 6),
      footerView.leftAnchor.constraint(equalTo: container.leftAnchor),
      footerView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])

    if isSend {
      translationTextLabelRight = textLabel
    } else {
      translationTextLabelLeft = textLabel
    }
    return container
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

  func tapFunc() {
    contentModel?.selectRange = nil
    delegate?.didTextViewLoseFocus?(self, contentModel)
    isLongPress = false
  }

  // MARK: - Layout

  override open func commonUILeft() {
    super.commonUILeft()
    bubbleImageLeft.addSubview(contentLabelLeft)
    bubbleImageLeft.addSubview(translationAreaLeft)

    // contentLabel 底部：无译文时贴气泡底（低优先级），有译文时被译文区域撑开
    let bottomToBubble = contentLabelLeft.bottomAnchor.constraint(
      equalTo: bubbleImageLeft.bottomAnchor, constant: -chat_content_margin
    )
    bottomToBubble.priority = .defaultLow

    // 无译文时高度强制 0（防止约束撑开气泡）；默认激活（隐藏状态）
    translationAreaLeftHeightZero = translationAreaLeft.heightAnchor.constraint(equalToConstant: 0)
    translationAreaLeftHeightZero?.isActive = true

    translationAreaLeftTopAnchor = translationAreaLeft.topAnchor.constraint(equalTo: contentLabelLeft.bottomAnchor)
    reactionTopAnchorLeft?.isActive = false
    reactionTopAnchorLeft = reactionViewLeft.topAnchor.constraint(
      equalTo: translationAreaLeft.bottomAnchor,
      constant: chat_content_margin
    )
    NSLayoutConstraint.activate([
      contentLabelLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: chat_content_margin),
      contentLabelLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor, constant: -chat_content_margin),
      contentLabelLeft.topAnchor.constraint(equalTo: replyViewLeft.bottomAnchor, constant: chat_content_margin),
      bottomToBubble,

      // A collapsed translation area keeps ordinary text spacing unchanged.
      translationAreaLeftTopAnchor!,
      translationAreaLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: chat_content_margin),
      translationAreaLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor, constant: -chat_content_margin),
      reactionViewLeft.bottomAnchor.constraint(equalTo: bubbleImageLeft.bottomAnchor, constant: -chat_content_margin),
      reactionTopAnchorLeft!,
    ])
  }

  override open func commonUIRight() {
    super.commonUIRight()
    bubbleImageRight.addSubview(contentLabelRight)
    bubbleImageRight.addSubview(translationAreaRight)

    let bottomToBubble = contentLabelRight.bottomAnchor.constraint(
      equalTo: bubbleImageRight.bottomAnchor, constant: -chat_content_margin
    )
    bottomToBubble.priority = .defaultLow

    translationAreaRightHeightZero = translationAreaRight.heightAnchor.constraint(equalToConstant: 0)
    translationAreaRightHeightZero?.isActive = true

    translationAreaRightTopAnchor = translationAreaRight.topAnchor.constraint(equalTo: contentLabelRight.bottomAnchor)
    reactionTopAnchorRight?.isActive = false
    reactionTopAnchorRight = reactionViewRight.topAnchor.constraint(
      equalTo: translationAreaRight.bottomAnchor,
      constant: chat_content_margin
    )
    NSLayoutConstraint.activate([
      contentLabelRight.leftAnchor.constraint(equalTo: bubbleImageRight.leftAnchor, constant: chat_content_margin),
      contentLabelRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: -chat_content_margin),
      contentLabelRight.topAnchor.constraint(equalTo: replyViewRight.bottomAnchor, constant: chat_content_margin),
      bottomToBubble,

      translationAreaRightTopAnchor!,
      translationAreaRight.leftAnchor.constraint(equalTo: bubbleImageRight.leftAnchor, constant: chat_content_margin),
      translationAreaRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: -chat_content_margin),
      reactionViewRight.bottomAnchor.constraint(equalTo: bubbleImageRight.bottomAnchor, constant: -chat_content_margin),
      reactionTopAnchorRight!,
    ])
  }

  override open func showLeftOrRight(showRight: Bool) {
    super.showLeftOrRight(showRight: showRight)
    contentLabelLeft.isHidden = showRight
    contentLabelRight.isHidden = !showRight
    // 两侧 area 均重置为隐藏，由 bindTranslation 决定是否显示
    translationAreaLeft.isHidden = true
    translationAreaRight.isHidden = true
  }

  // MARK: - 译文绑定

  open func bindTranslation(_ model: MessageTextModel, isSend: Bool) {
    let area = isSend ? translationAreaRight : translationAreaLeft
    let textLabel = isSend ? translationTextLabelRight : translationTextLabelLeft
    let heightZero = isSend ? translationAreaRightHeightZero : translationAreaLeftHeightZero
    let hasTranslation = (model.translationFailed || model.translationInfo != nil) &&
      !(model.translationInfo?.translatedText.isEmpty ?? true) &&
      model.translationVisible &&
      !model.inMultiForward

    let shouldShowFailure = model.translationFailed && model.translationVisible && !model.inMultiForward

    if hasTranslation || shouldShowFailure {
      textLabel.text = shouldShowFailure
        ? chatLocalizable("chat_translate_failed_retry")
        : model.translationInfo?.translatedText
      textLabel.textColor = shouldShowFailure ? UIColor.ne_normalTheme : .ne_darkText
      // 停用高度为 0 的约束，让内容自然撑开
      heightZero?.isActive = false
      area.isHidden = false
    } else {
      // 激活高度为 0 的约束，折叠 area 防止撑开气泡
      heightZero?.isActive = true
      area.isHidden = true
    }
  }

  // MARK: - setModel

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    super.setModel(model, isSend)
    isLongPress = false
    contentModel?.cell = self

    let contentLabel = isSend ? contentLabelRight : contentLabelLeft
    if let m = model as? MessageTextModel {
      contentLabel.attributedText = m.attributeStr
      contentLabel.accessibilityValue = m.message?.text
      contentSizeToFit(contentLabel, m)
      bindTranslation(m, isSend: isSend)
    } else {
      contentLabel.text = model.message?.text
      contentLabel.accessibilityValue = model.message?.text
    }

    // Keep Normal/Feishu reactions below the complete text and translation body.
    // The base cell still owns the same reaction view and callbacks; only the
    // bubble dimensions and the two vertical anchors change here.
    let reactionView = isSend ? reactionViewRight : reactionViewLeft
    let hasReaction = model.reactionHeight > 0
    // A text bubble may be visually short while its minimum height is greater
    // than `chat_min_h`. Always measure Reaction against the available message
    // width so short messages do not collapse into one item per row.
    let reactionInset = reactionHorizontalInset(for: model)
    let reactionMaxWidth = max(26, chat_content_maxW - reactionInset * 2)
    let reactionWidth = hasReaction
      ? min(reactionMaxWidth,
            max(reactionView.layoutWidth(forMaxWidth: reactionMaxWidth), 26))
      : 0
    // `MessageTextModel.contentSize.width` includes the text view's two
    // horizontal insets. Keep those insets when the text reaches the maximum
    // measured width; otherwise the Reaction surface is wider than the
    // bubble and the leading capsule can render outside the text area.
    let bubbleMaxWidth = chat_content_maxW + reactionInset * 2
    let bubbleWidth = hasReaction
      ? min(bubbleMaxWidth, max(model.contentSize.width, reactionWidth + reactionInset * 2))
      : model.contentSize.width
    if isSend {
      bubbleWRight?.constant = bubbleWidth
      bubbleHRight?.constant = model.contentSize.height + (hasReaction ? model.reactionHeight : 0)
      translationAreaRightTopAnchor?.constant = 0
    } else {
      bubbleWLeft?.constant = bubbleWidth
      bubbleHLeft?.constant = model.contentSize.height + (hasReaction ? model.reactionHeight : 0)
      translationAreaLeftTopAnchor?.constant = 0
    }
  }

  // MARK: - select

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
    let contentLabel = contentLabelLeft.isHidden ? contentLabelRight : contentLabelLeft
    let location = longPress.location(in: contentLabel)
    guard contentLabel.bounds.contains(location) else {
      return
    }
    isLongPress = true
    selectAllRange()
  }
}

// MARK: - UITextViewDelegate

extension ChatMessageTextCell: UITextViewDelegate {
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
      tapFunc()
    } else {
      selectText()
    }
  }

  func getTextSize(_ attributedText: NSAttributedString?) -> CGSize {
    NSAttributedString.getRealTextViewSize(attributedText, messageTextFont, messageMaxSize)
  }

  func contentSizeToFit(_ contentLabel: UITextView, _ model: MessageTextModel) {
    let titleSize = getTextSize(contentLabel.attributedText)
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
