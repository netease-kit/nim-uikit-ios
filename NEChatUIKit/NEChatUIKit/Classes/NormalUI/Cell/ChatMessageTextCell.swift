
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreKit
import UIKit

@objcMembers
open class ChatMessageTextCell: NormalChatMessageBaseCell {
  var isLongPress: Bool = false

  public lazy var contentLabelLeft: NEChatTextView = {
    let label = NEChatTextView()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isEditable = false
    label.isSelectable = true
    label.isScrollEnabled = false
    label.delegate = self
    label.textContainerInset = .zero
    label.contentInset = .zero
    label.textContainer.lineFragmentPadding = 0.0
    label.isUserInteractionEnabled = true
    label.font = messageTextFont
    label.backgroundColor = .clear
    label.accessibilityIdentifier = "id.messageText"

    let singleTap = UITapGestureRecognizer(target: self, action: #selector(tapFunc))
    label.addGestureRecognizer(singleTap)

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
    label.delegate = self
    label.textContainerInset = .zero
    label.contentInset = .zero
    label.textContainer.lineFragmentPadding = 0.0
    label.isUserInteractionEnabled = true
    label.font = messageTextFont
    label.backgroundColor = .clear
    label.accessibilityIdentifier = "id.messageText"

    let singleTap = UITapGestureRecognizer(target: self, action: #selector(tapFunc))
    label.addGestureRecognizer(singleTap)

    let doubleTap = UITapGestureRecognizer(target: self, action: #selector(tapFunc))
    doubleTap.numberOfTapsRequired = 2
    label.addGestureRecognizer(doubleTap)

    let longTap = UILongPressGestureRecognizer(target: self, action: #selector(selectAllRange))
    label.addGestureRecognizer(longTap)

    return label
  }()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func tapFunc() {
    contentModel?.selectRange = nil
    delegate?.didTextViewLoseFocus?(self, contentModel)
    isLongPress = false
  }

  override open func commonUILeft() {
    super.commonUILeft()
    bubbleImageLeft.addSubview(contentLabelLeft)
    NSLayoutConstraint.activate([
      contentLabelLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor, constant: -chat_content_margin),
      contentLabelLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: chat_content_margin),
      contentLabelLeft.topAnchor.constraint(equalTo: replyViewLeft.bottomAnchor, constant: chat_content_margin),
      contentLabelLeft.bottomAnchor.constraint(equalTo: bubbleImageLeft.bottomAnchor, constant: -chat_content_margin),
    ])
  }

  override open func commonUIRight() {
    super.commonUIRight()
    bubbleImageRight.addSubview(contentLabelRight)
    NSLayoutConstraint.activate([
      contentLabelRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: -chat_content_margin),
      contentLabelRight.leftAnchor.constraint(equalTo: bubbleImageRight.leftAnchor, constant: chat_content_margin),
      contentLabelRight.topAnchor.constraint(equalTo: replyViewRight.bottomAnchor, constant: chat_content_margin),
      contentLabelRight.bottomAnchor.constraint(equalTo: bubbleImageRight.bottomAnchor, constant: -chat_content_margin),
    ])
  }

  override open func showLeftOrRight(showRight: Bool) {
    super.showLeftOrRight(showRight: showRight)
    contentLabelLeft.isHidden = showRight
    contentLabelRight.isHidden = !showRight
  }

  /// 重设文本选中范围
  override open func resetSelectRange() {
    contentLabelLeft.selectedRange = .init()
    contentLabelRight.selectedRange = .init()
  }

  /// 选中所有文本
  override open func selectAllRange() {
    let contentLabel = contentLabelLeft.isHidden ? contentLabelRight : contentLabelLeft

    // 选中所有
    let length = contentLabel.text.utf16.count
    let range = NSRange(location: 0, length: length)
    contentLabel.selectedRange = range
    contentModel?.selectRange = range

    delegate?.didLongPressMessageView(self, contentModel)
    contentLabel.becomeFirstResponder()
  }

  /// 设置是否允许多选
  /// 多选状态下文本不可选中
  /// - Parameters:
  ///   - model: 数据模型
  ///   - enableSelect: 是否处于多选状态
  override open func setSelect(_ model: MessageContentModel, _ enableSelect: Bool = false) {
    super.setSelect(model, enableSelect)
    contentLabelLeft.isUserInteractionEnabled = !enableSelect
    contentLabelRight.isUserInteractionEnabled = !enableSelect

    bubbleImageLeft.isUserInteractionEnabled = !enableSelect
    bubbleImageRight.isUserInteractionEnabled = !enableSelect
  }

  /// 重写 bubbleImage 长按事件
  /// 文本类消息长按默认选中所有文本
  /// - Parameter longPress: 长按手势
  override open func longPress(longPress: UILongPressGestureRecognizer) {
    isLongPress = true
    selectAllRange()
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    super.setModel(model, isSend)
    contentModel?.cell = self

    let contentLabel = isSend ? contentLabelRight : contentLabelLeft
    if let m = model as? MessageTextModel {
      contentLabel.attributedText = m.attributeStr
      contentLabel.accessibilityValue = m.message?.text
      contentSizeToFit(contentLabel, m)
    } else {
      contentLabel.text = model.message?.text
      contentLabel.accessibilityValue = model.message?.text
    }
  }
}

// MARK: - UITextViewDelegate

/// 划词（文本选中）实现
extension ChatMessageTextCell: UITextViewDelegate {
  /// 选中文本
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

  /// 拦截系统菜单
  override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    false
  }

  /// 选中范围变更
  /// - Parameter textView: textview
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

  // textView 垂直居中
  func contentSizeToFit(_ contentLabel: UITextView, _ model: MessageTextModel) {
    let messageTextFont = UIFont.systemFont(ofSize: ChatUIConfig.shared.messageProperties.messageTextSize)
    let messageMaxSize = CGSize(width: chat_content_maxW, height: CGFloat.greatestFiniteMagnitude)
    let titleSize = NSAttributedString.getRealSize(contentLabel.attributedText, messageTextFont, messageMaxSize)

    let textHeight = titleSize.height
    let textViewHeight = model.textHeight
    if textHeight <= textViewHeight {
      let offsetY = (textViewHeight - textHeight) / 2
      contentLabel.textContainerInset = UIEdgeInsets(top: offsetY, left: 0, bottom: 0, right: 0)
    } else {
      contentLabel.textContainerInset = .zero
    }
  }

  // 禁用长按图片突出显示
  open func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange) -> Bool {
    selectAllRange()
    return false
  }
}
