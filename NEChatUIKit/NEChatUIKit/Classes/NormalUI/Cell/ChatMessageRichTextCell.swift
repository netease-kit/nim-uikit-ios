
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class ChatMessageRichTextCell: ChatMessageReplyCell {
  public lazy var titleLabelLeft: NEChatTextView = {
    let label = NEChatTextView()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isEditable = false
    label.isSelectable = true
    label.isScrollEnabled = false
    label.delegate = self
    label.textContainerInset = .zero
    label.contentInset = .zero
    label.textContainer.lineFragmentPadding = 0.0
    label.isUserInteractionEnabled = false
    label.font = .systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.messageTextSize, weight: .semibold)
    label.backgroundColor = .clear
    label.accessibilityIdentifier = "id.messageTitle"

    let tap = UITapGestureRecognizer(target: nil, action: nil)
    label.addGestureRecognizer(tap)
    return label
  }()

  public lazy var titleLabelRight: NEChatTextView = {
    let label = NEChatTextView()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isEditable = false
    label.isSelectable = true
    label.isScrollEnabled = false
    label.delegate = self
    label.textContainerInset = .zero
    label.contentInset = .zero
    label.textContainer.lineFragmentPadding = 0.0
    label.isUserInteractionEnabled = false
    label.font = .systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.messageTextSize, weight: .semibold)
    label.backgroundColor = .clear
    label.accessibilityIdentifier = "id.messageTitle"

    let tap = UITapGestureRecognizer(target: nil, action: nil)
    label.addGestureRecognizer(tap)
    return label
  }()

  public var replyLabelLeftHeightAnchor: NSLayoutConstraint?
  public var replyLabelRightHeightAnchor: NSLayoutConstraint?
  public var titleLabelLeftTopAnchor: NSLayoutConstraint?
  public var titleLabelLeftHeightAnchor: NSLayoutConstraint?
  public var titleLabelRightTopAnchor: NSLayoutConstraint?
  public var titleLabelRightHeightAnchor: NSLayoutConstraint?
  public var contentLabelLeftHeightAnchor: NSLayoutConstraint?
  public var contentLabelRightHeightAnchor: NSLayoutConstraint?

  override open func commonUI() {
    /// left
    bubbleImageLeft.addSubview(replyLabelLeft)
    replyLabelLeftHeightAnchor = replyLabelLeft.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    replyLabelLeftHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      replyLabelLeft.leadingAnchor.constraint(equalTo: bubbleImageLeft.leadingAnchor, constant: chat_content_margin),
      replyLabelLeft.topAnchor.constraint(equalTo: bubbleImageLeft.topAnchor, constant: chat_content_margin),
      replyLabelLeft.trailingAnchor.constraint(equalTo: bubbleImageLeft.trailingAnchor, constant: -chat_content_margin),
    ])

    bubbleImageLeft.addSubview(titleLabelLeft)
    titleLabelLeftTopAnchor = titleLabelLeft.topAnchor.constraint(equalTo: replyLabelLeft.bottomAnchor, constant: chat_content_margin)
    titleLabelLeftTopAnchor?.isActive = true
    titleLabelLeftHeightAnchor = titleLabelLeft.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    titleLabelLeftHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      titleLabelLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor, constant: -chat_content_margin),
      titleLabelLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: chat_content_margin),
    ])

    bubbleImageLeft.addSubview(contentLabelLeft)
    contentLabelLeftHeightAnchor = contentLabelLeft.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    contentLabelLeftHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      contentLabelLeft.rightAnchor.constraint(equalTo: titleLabelLeft.rightAnchor, constant: 0),
      contentLabelLeft.leftAnchor.constraint(equalTo: titleLabelLeft.leftAnchor, constant: 0),
      contentLabelLeft.topAnchor.constraint(equalTo: titleLabelLeft.bottomAnchor, constant: chat_content_margin),
    ])

    /// right
    bubbleImageRight.addSubview(replyLabelRight)
    replyLabelRightHeightAnchor = replyLabelRight.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    replyLabelRightHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      replyLabelRight.leadingAnchor.constraint(equalTo: bubbleImageRight.leadingAnchor, constant: chat_content_margin),
      replyLabelRight.topAnchor.constraint(equalTo: bubbleImageRight.topAnchor, constant: chat_content_margin),
      replyLabelRight.trailingAnchor.constraint(equalTo: bubbleImageRight.trailingAnchor, constant: -chat_content_margin),
    ])

    bubbleImageRight.addSubview(titleLabelRight)
    titleLabelRightTopAnchor = titleLabelRight.topAnchor.constraint(equalTo: replyLabelRight.bottomAnchor, constant: chat_content_margin)
    titleLabelRightTopAnchor?.isActive = true
    titleLabelRightHeightAnchor = titleLabelRight.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    titleLabelRightHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      titleLabelRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: -chat_content_margin),
      titleLabelRight.leftAnchor.constraint(equalTo: bubbleImageRight.leftAnchor, constant: chat_content_margin),
    ])

    bubbleImageRight.addSubview(contentLabelRight)
    contentLabelRightHeightAnchor = contentLabelRight.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    contentLabelRightHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      contentLabelRight.rightAnchor.constraint(equalTo: titleLabelRight.rightAnchor, constant: -0),
      contentLabelRight.leftAnchor.constraint(equalTo: titleLabelRight.leftAnchor, constant: 0),
      contentLabelRight.topAnchor.constraint(equalTo: titleLabelRight.bottomAnchor, constant: chat_content_margin),
    ])
  }

  override open func showLeftOrRight(showRight: Bool) {
    super.showLeftOrRight(showRight: showRight)
    titleLabelLeft.isHidden = showRight
    titleLabelRight.isHidden = !showRight
  }

  /// 重设文本选中范围
  override open func resetSelectRange() {
    super.resetSelectRange()
    titleLabelLeft.selectedRange = .init()
    titleLabelRight.selectedRange = .init()
  }

  /// 选中所有文本
  override open func selectAllRange() {
    super.selectAllRange()
    if let model = contentModel as? MessageTextModel, model.attributeStr == nil {
      titleLabelLeft.selectAll(nil)
      titleLabelRight.selectAll(nil)
    }
  }

  /// 设置是否允许多选
  /// 多选状态下文本不可选中
  /// - Parameters:
  ///   - model: 数据模型
  ///   - enableSelect: 是否处于多选状态
  override open func setSelect(_ model: MessageContentModel, _ enableSelect: Bool = false) {
    super.setSelect(model, enableSelect)
    let titleLabel = titleLabelLeft.isHidden ? titleLabelRight : titleLabelLeft
    titleLabel.isUserInteractionEnabled = !enableSelect
  }

  /// 重写 bubbleImage 长按事件
  /// 文本类消息长按默认选中所有文本
  /// - Parameter longPress: 长按手势
  override open func longPress(longPress: UILongPressGestureRecognizer) {
    if let model = contentModel as? MessageTextModel, model.attributeStr == nil {
      let titleLabel = titleLabelLeft.isHidden ? titleLabelRight : titleLabelLeft

      // 选中所有
      let length = titleLabel.text.utf16.count
      let range = NSRange(location: 0, length: length)
      titleLabel.selectedRange = range
      contentModel?.selectRange = range

      delegate?.didLongPressMessageView(self, contentModel)
      titleLabel.becomeFirstResponder()
    } else {
      super.longPress(longPress: longPress)
    }
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    super.setModel(model, isSend)
    let replyLabelHeightAnchor = isSend ? replyLabelRightHeightAnchor : replyLabelLeftHeightAnchor
    let titleLabel = isSend ? titleLabelRight : titleLabelLeft
    let titleLabelTopAnchor = isSend ? titleLabelRightTopAnchor : titleLabelLeftTopAnchor
    let titleLabelHeightAnchor = isSend ? titleLabelRightHeightAnchor : titleLabelLeftHeightAnchor
    let contentLabelHeightAnchor = isSend ? contentLabelRightHeightAnchor : contentLabelLeftHeightAnchor

    if model.replyText == nil || model.replyText!.isEmpty {
      replyLabelHeightAnchor?.constant = 0
      titleLabelTopAnchor?.constant = 0
    } else {
      replyLabelHeightAnchor?.constant = 16
      titleLabelTopAnchor?.constant = chat_content_margin
    }

    if let m = model as? MessageTextModel {
      contentLabelHeightAnchor?.constant = m.textHeight
    }

    if let m = model as? MessageRichTextModel {
      titleLabel.attributedText = m.titleAttributeStr
      titleLabelHeightAnchor?.constant = m.titleTextHeight

      if m.attributeStr == nil {
        // contentLabel 为空（只有 title）
        titleLabel.isUserInteractionEnabled = true
      } else {
        titleLabel.isUserInteractionEnabled = false
      }
    }
  }

  override open func selectText() {
    if let model = contentModel as? MessageTextModel, model.attributeStr != nil {
      super.selectText()
      return
    }

    let titleLabel = titleLabelLeft.isHidden ? titleLabelRight : titleLabelLeft
    let range = titleLabel.selectedRange
    contentModel?.selectRange = range

    if range.location == lastRange?.location || range.location + range.length == (lastRange?.location ?? 0) + (lastRange?.length ?? 0) {
      lastRange = range
    } else {
      contentModel?.selectRange = nil
    }

    // 首次全选
    if contentModel?.selectRange == nil || range.length == 0 {
      let length = titleLabel.text.utf16.count
      let range = NSRange(location: 0, length: length)
      titleLabel.selectedRange = range
      contentModel?.selectRange = range
      lastRange = range
    }

    delegate?.didLongPressMessageView(self, contentModel)

    if (contentModel?.selectRange?.length ?? 0) > 0 {
      titleLabel.becomeFirstResponder()
    } else {
      titleLabel.resignFirstResponder()
    }
  }
}
