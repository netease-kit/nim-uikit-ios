// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunChatMessageTextCell: FunChatMessageBaseCell {
  var lastRange: NSRange? // 上一次的文本选中范围

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

    let tap = UITapGestureRecognizer(target: nil, action: nil)
    label.addGestureRecognizer(tap)
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

    let tap = UITapGestureRecognizer(target: nil, action: nil)
    label.addGestureRecognizer(tap)
    return label
  }()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func commonUI() {
    bubbleImageLeft.addSubview(contentLabelLeft)
    NSLayoutConstraint.activate([
      contentLabelLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor, constant: -chat_content_margin),
      contentLabelLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: chat_content_margin + funMargin),
      contentLabelLeft.topAnchor.constraint(equalTo: bubbleImageLeft.topAnchor, constant: chat_content_margin),
      contentLabelLeft.bottomAnchor.constraint(equalTo: bubbleImageLeft.bottomAnchor, constant: -chat_content_margin),
    ])

    bubbleImageRight.addSubview(contentLabelRight)
    NSLayoutConstraint.activate([
      contentLabelRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: -chat_content_margin - funMargin),
      contentLabelRight.leftAnchor.constraint(equalTo: bubbleImageRight.leftAnchor, constant: chat_content_margin),
      contentLabelRight.topAnchor.constraint(equalTo: bubbleImageRight.topAnchor, constant: chat_content_margin),
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
    contentLabelLeft.selectAll(nil)
    contentLabelRight.selectAll(nil)
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
    let contentLabel = contentLabelLeft.isHidden ? contentLabelRight : contentLabelLeft

    // 选中所有
    let length = contentLabel.text.utf16.count
    let range = NSRange(location: 0, length: length)
    contentLabel.selectedRange = range
    contentModel?.selectRange = range

    delegate?.didLongPressMessageView(self, contentModel)
    contentLabel.becomeFirstResponder()
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    super.setModel(model, isSend)

    let contentLabel = isSend ? contentLabelRight : contentLabelLeft
    let bubbleW = isSend ? bubbleWRight : bubbleWLeft

    if let m = model as? MessageTextModel {
      contentLabel.attributedText = m.attributeStr
      contentLabel.accessibilityValue = m.message?.text
      contentSizeToFit(contentLabel, m)
    }
    bubbleW?.constant += funMargin
  }
}

// MARK: - UITextViewDelegate

/// 划词（文本选中）实现
extension FunChatMessageTextCell: UITextViewDelegate {
  /// 选中文本
  open func selectText() {
    let contentLabel = contentLabelLeft.isHidden ? contentLabelRight : contentLabelLeft
    let range = contentLabel.selectedRange
    contentModel?.selectRange = range

    if range.location == lastRange?.location || range.location + range.length == (lastRange?.location ?? 0) + (lastRange?.length ?? 0) {
      lastRange = range
    } else {
      contentModel?.selectRange = nil
    }

    // 首次全选
    if contentModel?.selectRange == nil || range.length == 0 {
      let length = contentLabel.text.utf16.count
      let range = NSRange(location: 0, length: length)
      contentLabel.selectedRange = range
      contentModel?.selectRange = range
      lastRange = range
    }

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
  public func textViewDidChangeSelection(_ textView: UITextView) {
    if textView.selectedRange.length == 0 {
      delegate?.didTextViewLoseFocus?(self, contentModel)
    } else {
      selectText()
    }
  }

  // textView 垂直居中
  func contentSizeToFit(_ contentLabel: UITextView, _ model: MessageTextModel) {
    let messageTextFont = UIFont.systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.messageTextSize)
    let messageMaxSize = CGSize(width: chat_content_maxW, height: CGFloat.greatestFiniteMagnitude)
    let titleSize = NSAttributedString.getRealSize(contentLabel.attributedText, messageTextFont, messageMaxSize)

    if model.contentSize.height == fun_chat_min_h {
      // 单行消息单独设置文本内边距
      contentLabel.textContainerInset = UIEdgeInsets(top: model.offset / 2, left: 0, bottom: 0, right: 0)
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
}
