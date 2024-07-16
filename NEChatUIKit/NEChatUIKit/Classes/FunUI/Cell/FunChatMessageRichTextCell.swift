// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunChatMessageRichTextCell: FunChatMessageReplyCell {
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

  public var titleLabelLeftHeightAnchor: NSLayoutConstraint?
  public var titleLabelRightHeightAnchor: NSLayoutConstraint?
  public var titleLabelLeftBottomAnchor: NSLayoutConstraint?
  public var titleLabelRightBottomAnchor: NSLayoutConstraint?
  public var contentLabelLeftHeightAnchor: NSLayoutConstraint?
  public var contentLabelRightHeightAnchor: NSLayoutConstraint?

  override open func commonUI() {
    /// left
    bubbleImageLeft.addSubview(titleLabelLeft)
    titleLabelLeftHeightAnchor = titleLabelLeft.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    titleLabelLeftHeightAnchor?.priority = .fittingSizeLevel
    titleLabelLeftHeightAnchor?.isActive = true
    titleLabelLeftBottomAnchor = titleLabelLeft.bottomAnchor.constraint(equalTo: bubbleImageLeft.bottomAnchor, constant: -chat_content_margin)
    NSLayoutConstraint.activate([
      titleLabelLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor, constant: -chat_content_margin),
      titleLabelLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: chat_content_margin + funMargin),
      titleLabelLeft.topAnchor.constraint(equalTo: bubbleImageLeft.topAnchor, constant: chat_content_margin),
    ])

    bubbleImageLeft.addSubview(contentLabelLeft)
    contentLabelLeftHeightAnchor = contentLabelLeft.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    contentLabelLeftHeightAnchor?.priority = .fittingSizeLevel
    contentLabelLeftHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      contentLabelLeft.rightAnchor.constraint(equalTo: titleLabelLeft.rightAnchor, constant: -0),
      contentLabelLeft.leftAnchor.constraint(equalTo: titleLabelLeft.leftAnchor, constant: 0),
      contentLabelLeft.topAnchor.constraint(equalTo: titleLabelLeft.bottomAnchor, constant: chat_content_margin),
    ])

    commonUILeft()

    /// right
    bubbleImageRight.addSubview(titleLabelRight)
    titleLabelRightHeightAnchor = titleLabelRight.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    titleLabelRightHeightAnchor?.priority = .fittingSizeLevel
    titleLabelRightHeightAnchor?.isActive = true
    titleLabelRightBottomAnchor = titleLabelRight.bottomAnchor.constraint(equalTo: bubbleImageRight.bottomAnchor, constant: -chat_content_margin)
    NSLayoutConstraint.activate([
      titleLabelRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: -chat_content_margin - funMargin),
      titleLabelRight.leftAnchor.constraint(equalTo: bubbleImageRight.leftAnchor, constant: chat_content_margin),
      titleLabelRight.topAnchor.constraint(equalTo: bubbleImageRight.topAnchor, constant: chat_content_margin),
    ])

    bubbleImageRight.addSubview(contentLabelRight)
    contentLabelRightHeightAnchor = contentLabelRight.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    contentLabelRightHeightAnchor?.priority = .fittingSizeLevel
    contentLabelRightHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      contentLabelRight.rightAnchor.constraint(equalTo: titleLabelRight.rightAnchor, constant: -0),
      contentLabelRight.leftAnchor.constraint(equalTo: titleLabelRight.leftAnchor, constant: 0),
      contentLabelRight.topAnchor.constraint(equalTo: titleLabelRight.bottomAnchor, constant: chat_content_margin),
    ])

    commonUIRight()
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
    let replyView = isSend ? replyTextViewRight : replyTextViewLeft
    let titleLabel = isSend ? titleLabelRight : titleLabelLeft
    let contentLabel = isSend ? contentLabelRight : contentLabelLeft
    let titleLabelHeightAnchor = isSend ? titleLabelRightHeightAnchor : titleLabelLeftHeightAnchor
    let titleLabelBottomAnchor = isSend ? titleLabelRightBottomAnchor : titleLabelLeftBottomAnchor
    let contentLabelHeightAnchor = isSend ? contentLabelRightHeightAnchor : contentLabelLeftHeightAnchor

    if model.replyText == nil || model.replyText!.isEmpty {
      replyView.isHidden = true
    } else {
      replyView.isHidden = false
    }

    if let m = model as? MessageTextModel {
      contentLabelHeightAnchor?.constant = m.textHeight
    }

    if let m = model as? MessageRichTextModel {
      titleLabel.attributedText = m.titleAttributeStr
      if replyView.isHidden {
        titleLabel.textContainerInset = UIEdgeInsets(top: model.offset / 2, left: 0, bottom: 0, right: 0)
      }

      if m.attributeStr == nil {
        // contentLabel 为空（只有 title）
        titleLabel.isUserInteractionEnabled = true
        titleLabelHeightAnchor?.isActive = false
        titleLabelBottomAnchor?.isActive = true
      } else {
        titleLabel.isUserInteractionEnabled = false
        titleLabelBottomAnchor?.isActive = false
        titleLabelHeightAnchor?.isActive = true
        titleLabelHeightAnchor?.constant = m.titleTextHeight
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
