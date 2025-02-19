
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class ChatMessageRichTextCell: ChatMessageTextCell {
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
    label.font = .systemFont(ofSize: ChatUIConfig.shared.messageProperties.messageTextSize, weight: .semibold)
    label.backgroundColor = .clear
    label.accessibilityIdentifier = "id.messageTitle"

    let singleTap = UITapGestureRecognizer(target: self, action: #selector(tapFunc))
    label.addGestureRecognizer(singleTap)

    let doubleTap = UITapGestureRecognizer(target: self, action: #selector(tapFunc))
    doubleTap.numberOfTapsRequired = 2
    label.addGestureRecognizer(doubleTap)

    let longTap = UILongPressGestureRecognizer(target: self, action: #selector(selectAllRange))
    label.addGestureRecognizer(longTap)

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
    label.font = .systemFont(ofSize: ChatUIConfig.shared.messageProperties.messageTextSize, weight: .semibold)
    label.backgroundColor = .clear
    label.accessibilityIdentifier = "id.messageTitle"

    let singleTap = UITapGestureRecognizer(target: self, action: #selector(tapFunc))
    label.addGestureRecognizer(singleTap)

    let doubleTap = UITapGestureRecognizer(target: self, action: #selector(tapFunc))
    doubleTap.numberOfTapsRequired = 2
    label.addGestureRecognizer(doubleTap)

    let longTap = UILongPressGestureRecognizer(target: self, action: #selector(selectAllRange))
    label.addGestureRecognizer(longTap)

    return label
  }()

  public var titleLabelLeftHeightAnchor: NSLayoutConstraint?
  public var titleLabelRightHeightAnchor: NSLayoutConstraint?
  public var contentLabelLeftHeightAnchor: NSLayoutConstraint?
  public var contentLabelRightHeightAnchor: NSLayoutConstraint?

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func commonUILeft() {
    bubbleImageLeft.addSubview(replyViewLeft)
    replyViewLeftHeightAnchor = replyViewLeft.heightAnchor.constraint(equalToConstant: replyViewHeight)
    replyViewLeftHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      replyViewLeft.leadingAnchor.constraint(equalTo: bubbleImageLeft.leadingAnchor, constant: chat_content_margin),
      replyViewLeft.topAnchor.constraint(equalTo: bubbleImageLeft.topAnchor, constant: 0),
      replyViewLeft.trailingAnchor.constraint(equalTo: bubbleImageLeft.trailingAnchor, constant: -chat_content_margin),
    ])

    bubbleImageLeft.addSubview(titleLabelLeft)
    titleLabelLeftHeightAnchor = titleLabelLeft.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    titleLabelLeftHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      titleLabelLeft.topAnchor.constraint(equalTo: replyViewLeft.bottomAnchor, constant: chat_content_margin),
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
  }

  override open func commonUIRight() {
    bubbleImageRight.addSubview(replyViewRight)
    replyViewRightHeightAnchor = replyViewRight.heightAnchor.constraint(equalToConstant: replyViewHeight)
    replyViewRightHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      replyViewRight.leadingAnchor.constraint(equalTo: bubbleImageRight.leadingAnchor, constant: chat_content_margin),
      replyViewRight.topAnchor.constraint(equalTo: bubbleImageRight.topAnchor, constant: 0),
      replyViewRight.trailingAnchor.constraint(equalTo: bubbleImageRight.trailingAnchor, constant: -chat_content_margin),
    ])

    bubbleImageRight.addSubview(titleLabelRight)
    titleLabelRightHeightAnchor = titleLabelRight.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    titleLabelRightHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      titleLabelRight.topAnchor.constraint(equalTo: replyViewRight.bottomAnchor, constant: chat_content_margin),
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
      let titleLabel = titleLabelLeft.isHidden ? titleLabelRight : titleLabelLeft

      // 选中所有
      let length = titleLabel.text.utf16.count
      let range = NSRange(location: 0, length: length)
      titleLabel.selectedRange = range
      contentModel?.selectRange = range

      delegate?.didLongPressMessageView(self, contentModel)
      titleLabel.becomeFirstResponder()
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
      selectAllRange()
    } else {
      super.longPress(longPress: longPress)
    }
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    super.setModel(model, isSend)
    let titleLabel = isSend ? titleLabelRight : titleLabelLeft
    let titleLabelHeightAnchor = isSend ? titleLabelRightHeightAnchor : titleLabelLeftHeightAnchor
    let contentLabelHeightAnchor = isSend ? contentLabelRightHeightAnchor : contentLabelLeftHeightAnchor

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
    delegate?.didLongPressMessageView(self, contentModel)

    if (contentModel?.selectRange?.length ?? 0) > 0 {
      titleLabel.becomeFirstResponder()
    } else {
      titleLabel.resignFirstResponder()
    }
  }
}
