// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

@objcMembers
open class FunChatMessageTextCell: FunChatMessageBaseCell {
  var isLongPress: Bool = false

  // MARK: - 译文气泡（Fun 皮肤：独立白色圆角气泡，浮于原文气泡下方）

  public lazy var translationBubbleLeft: UIView = makeTranslationBubble(isSend: false)
  public lazy var translationBubbleRight: UIView = makeTranslationBubble(isSend: true)

  public lazy var translationTextLeft: UILabel = .init()
  public lazy var translationTextRight: UILabel = .init()

  // 译文气泡 top 约束（根据有无回复动态切换锚点）
  private var translationBubbleLeftTopToBubble: NSLayoutConstraint?
  private var translationBubbleLeftTopToReply: NSLayoutConstraint?
  private var translationBubbleRightTopToBubble: NSLayoutConstraint?
  private var translationBubbleRightTopToReply: NSLayoutConstraint?

  private func makeTranslationBubble(isSend: Bool) -> UIView {
    let bubble = UIView()
    bubble.translatesAutoresizingMaskIntoConstraints = false
    bubble.backgroundColor = .funChatTranslationBubbleBg
    bubble.layer.cornerRadius = 4 // 圆角调小（原 8 → 4）
    bubble.layer.masksToBounds = true
    bubble.isHidden = true

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

    // 2. 底部「图标 + 译文」footer（取代顶部 tagLabel）
    let footerView = UIView()
    footerView.translatesAutoresizingMaskIntoConstraints = false

    let iconView = UIImageView(image: chatCoreLoader.loadImage("chat_translation"))
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
      textLabel.leftAnchor.constraint(equalTo: bubble.leftAnchor, constant: 10),
      textLabel.rightAnchor.constraint(equalTo: bubble.rightAnchor, constant: -10),

      footerView.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 6),
      footerView.leftAnchor.constraint(equalTo: bubble.leftAnchor, constant: 10),
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

  /// 译文气泡 footer 最小宽度：图标(14) + 间距(4) + 文案 + 左右内边距(10+10)
  private var translationBubbleMinWidth: CGFloat {
    let tag = chatLocalizable("chat_translate_tag") as NSString
    let tagW = tag.size(withAttributes: [.font: UIFont.systemFont(ofSize: 12)]).width
    return 10 + 14 + 4 + ceil(tagW) + 10
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
    // 译文气泡：预先创建两条 top 约束，setModel 时激活其中一条
    contentView.addSubview(translationBubbleLeft)
    translationBubbleLeftTopToBubble = translationBubbleLeft.topAnchor.constraint(
      equalTo: bubbleImageLeft.bottomAnchor, constant: 4
    )
    translationBubbleLeftTopToReply = translationBubbleLeft.topAnchor.constraint(
      equalTo: replyViewLeft.bottomAnchor, constant: 4
    )
    NSLayoutConstraint.activate([
      translationBubbleLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: funMargin),
      translationBubbleLeft.widthAnchor.constraint(lessThanOrEqualToConstant: chat_content_maxW - funMargin),
      translationBubbleLeft.widthAnchor.constraint(greaterThanOrEqualToConstant: translationBubbleMinWidth),
    ])
    // 默认使用 bubbleImage.bottom（无回复时）
    translationBubbleLeftTopToBubble?.isActive = true
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
    // 译文气泡：预先创建两条 top 约束
    contentView.addSubview(translationBubbleRight)
    translationBubbleRightTopToBubble = translationBubbleRight.topAnchor.constraint(
      equalTo: bubbleImageRight.bottomAnchor, constant: 4
    )
    translationBubbleRightTopToReply = translationBubbleRight.topAnchor.constraint(
      equalTo: replyViewRight.bottomAnchor, constant: 4
    )
    NSLayoutConstraint.activate([
      translationBubbleRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: -funMargin),
      translationBubbleRight.widthAnchor.constraint(lessThanOrEqualToConstant: chat_content_maxW - funMargin),
      translationBubbleRight.widthAnchor.constraint(greaterThanOrEqualToConstant: translationBubbleMinWidth),
    ])
    // 默认使用 bubbleImage.bottom（无回复时）
    translationBubbleRightTopToBubble?.isActive = true
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
      model.translationVisible
    if hasTranslation {
      textLabel.text = model.translationInfo?.translatedText
      bubble.isHidden = false
    } else {
      bubble.isHidden = true
    }
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    super.setModel(model, isSend)
    isLongPress = false

    let contentLabel = isSend ? contentLabelRight : contentLabelLeft
    let bubbleW = isSend ? bubbleWRight : bubbleWLeft

    if let m = model as? MessageTextModel {
      contentLabel.attributedText = m.attributeStr
      contentLabel.accessibilityValue = m.message?.text
      contentSizeToFit(contentLabel, m)
      bindTranslation(m, isSend: isSend)
    }
    bubbleW?.constant += funMargin

    // 根据是否有回复内容切换译文气泡的 top 锚点
    updateTranslationBubbleTopConstraint(isSend: isSend, isReply: model.isReply)
  }

  /// 有回复时 top 挂 replyView.bottom，无回复时 top 挂 bubbleImage.bottom
  private func updateTranslationBubbleTopConstraint(isSend: Bool, isReply: Bool) {
    if isSend {
      translationBubbleRightTopToBubble?.isActive = !isReply
      translationBubbleRightTopToReply?.isActive = isReply
    } else {
      translationBubbleLeftTopToBubble?.isActive = !isReply
      translationBubbleLeftTopToReply?.isActive = isReply
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
