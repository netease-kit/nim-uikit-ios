// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

open class NEGrowingTextView: UIView {
  // MARK: - Public properties

  open weak var delegate: NEGrowingTextViewDelegate?

  open var internalTextView: UITextView {
    return textView
  }

  open var maxNumberOfLines: Int? {
    didSet {
      updateMaxHeight()
    }
  }

  /// 最小行数
  open var minNumberOfLines: Int? {
    didSet {
      updateMinHeight()
    }
  }

  /// 最大高度
  open var maxHeight: CGFloat?
  /// 最小高度
  open var minHeight: CGFloat = 0
  /// 控件因为输入内容变高的时候是否开启动画
  open var isGrowingAnimationEnabled = true
  /// 缺省动画时间
  open var animationDuration: TimeInterval = 0.1
  /// 内容区域内边距
  open var contentInset = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5) {
    didSet {
      updateTextViewFrame()
      updateMaxHeight()
      updateMinHeight()
    }
  }

  /// 是否支持滚动，默认不支持
  open var isScrollEnabled = false {
    didSet {
      textView.isScrollEnabled = isScrollEnabled
    }
  }

  /// 是否开启缺省文案
  open var isPlaceholderEnabled = true {
    didSet {
      textView.shouldDisplayPlaceholder = textView.text.isEmpty && isPlaceholderEnabled
    }
  }

  /// 通过富文本设置缺省文案
  open var placeholder: NSAttributedString? {
    set {
      textView.placeholder = newValue
    }
    get {
      return textView.placeholder
    }
  }

  open var isCaretHidden = false {
    didSet {
      textView.isCaretHidden = isCaretHidden
    }
  }

  /// 设置文本
  open var text: String? {
    set {
      textView.text = newValue
      updateHeight()
    }
    get {
      return textView.text
    }
  }

  /// 字号
  open var font: UIFont? {
    set {
      textView.font = newValue
      updateMaxHeight()
      updateMinHeight()
    }
    get {
      return textView.font
    }
  }

  /// 文本颜色
  open var textColor: UIColor? {
    set {
      textView.textColor = newValue
    }
    get {
      return textView.textColor
    }
  }

  /// 对齐方式
  open var textAlignment: NSTextAlignment {
    set {
      textView.textAlignment = newValue
    }
    get {
      return textView.textAlignment
    }
  }

  /// 是否可编辑
  open var isEditable: Bool {
    set {
      textView.isEditable = newValue
    }
    get {
      return textView.isEditable
    }
  }

  /// 选中区域
  open var selectedRange: NSRange? {
    set {
      if let newValue = newValue {
        textView.selectedRange = newValue
      }
    }
    get {
      return textView.selectedRange
    }
  }

  open var dataDetectorTypes: UIDataDetectorTypes {
    set {
      textView.dataDetectorTypes = newValue
    }
    get {
      return textView.dataDetectorTypes
    }
  }

  open var returnKeyType: UIReturnKeyType {
    set {
      textView.returnKeyType = newValue
    }
    get {
      return textView.returnKeyType
    }
  }

  open var keyboardType: UIKeyboardType {
    set {
      textView.keyboardType = newValue
    }
    get {
      return textView.keyboardType
    }
  }

  open var enablesReturnKeyAutomatically: Bool {
    set {
      textView.enablesReturnKeyAutomatically = newValue
    }
    get {
      return textView.enablesReturnKeyAutomatically
    }
  }

  /// 是否有内容
  open var hasText: Bool {
    return textView.hasText
  }

  // MARK: - Private properties

  /// 内部 text view
  fileprivate var textView: NEInternalTextView = {
    let textView = NEInternalTextView(frame: .zero)
    textView.textContainerInset = .zero
    textView.textContainer.lineFragmentPadding = 1 // 1 pixel for caret
    textView.showsHorizontalScrollIndicator = false
    textView.contentInset = .zero
    textView.contentMode = .redraw
    return textView
  }()

  // MARK: - Initialization

  override public init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }
}

// MARK: - Overriding

extension NEGrowingTextView {
  override open var backgroundColor: UIColor? {
    didSet {
      textView.backgroundColor = backgroundColor
    }
  }

  override open func layoutSubviews() {
    super.layoutSubviews()
    updateTextViewFrame()
    updateMaxHeight()
    updateMinHeight()
    updateHeight()
  }

  override open func sizeThatFits(_ size: CGSize) -> CGSize {
    var size = size
    if text?.count == 0 {
      size.height = minHeight
    }
    return size
  }

  override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    textView.becomeFirstResponder()
  }

  override open func becomeFirstResponder() -> Bool {
    super.becomeFirstResponder()
    return textView.becomeFirstResponder()
  }

  override open func resignFirstResponder() -> Bool {
    super.resignFirstResponder()
    return textView.resignFirstResponder()
  }

  override open var isFirstResponder: Bool {
    return textView.isFirstResponder
  }
}

// MARK: - Public

public extension NEGrowingTextView {
  /// 是指定位置文本可见
  func scrollRangeToVisible(_ range: NSRange) {
    textView.scrollRangeToVisible(range)
  }

  /// 计算高度
  func calculateHeight() -> CGFloat {
    return ceil(textView.sizeThatFits(textView.frame.size).height + contentInset.top + contentInset.bottom)
  }

  /// 更新高度
  func updateHeight() {
    let updatedHeightInfo = updatedHeight()
    let newHeight = updatedHeightInfo.newHeight
    let difference = updatedHeightInfo.difference

    if difference != 0 {
      if newHeight == maxHeight {
        if !textView.isScrollEnabled {
          textView.isScrollEnabled = true
          textView.flashScrollIndicators()
        }
      } else {
        textView.isScrollEnabled = isScrollEnabled
      }

      if isGrowingAnimationEnabled {
        UIView.animate(withDuration: animationDuration, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
          self.updateGrowingTextView(newHeight: newHeight, difference: difference)
        }, completion: { _ in
          if let delegate = self.delegate, delegate.responds(to: DelegateSelectors.didChangeHeight) {
            delegate.growingTextView!(self, didChangeHeight: newHeight, difference: difference)
          }
        })
      } else {
        updateGrowingTextView(newHeight: newHeight, difference: difference)

        if let delegate = delegate, delegate.responds(to: DelegateSelectors.didChangeHeight) {
          delegate.growingTextView!(self, didChangeHeight: newHeight, difference: difference)
        }
      }
    }

    updateScrollPosition(animated: false)
    textView.shouldDisplayPlaceholder = textView.text.isEmpty && isPlaceholderEnabled
  }
}

// MARK: - Helper

private extension NEGrowingTextView {
  /// 默认初始化
  func commonInit() {
    textView.frame = CGRect(origin: .zero, size: frame.size)
    textView.delegate = self
    minNumberOfLines = 1
    addSubview(textView)
  }

  /// 更新边框尺寸
  func updateTextViewFrame() {
    let lineFragmentPadding = textView.textContainer.lineFragmentPadding
    var textViewFrame = frame
    textViewFrame.origin.x = contentInset.left - lineFragmentPadding
    textViewFrame.origin.y = contentInset.top
    textViewFrame.size.width -= contentInset.left + contentInset.right - lineFragmentPadding * 2
    textViewFrame.size.height -= contentInset.top + contentInset.bottom
    textView.frame = textViewFrame
    textView.sizeThatFits(textView.frame.size)
  }

  /// 更新高度触发回调协议
  func updateGrowingTextView(newHeight: CGFloat, difference: CGFloat) {
    if let delegate = delegate, delegate.responds(to: DelegateSelectors.willChangeHeight) {
      delegate.growingTextView!(self, willChangeHeight: newHeight, difference: difference)
    }
    frame.size.height = newHeight
    updateTextViewFrame()
  }

  /// 内部更新高度方法
  func updatedHeight() -> (newHeight: CGFloat, difference: CGFloat) {
    var newHeight = calculateHeight()
    if newHeight < minHeight || !hasText {
      newHeight = minHeight
    }
    if let maxHeight = maxHeight, newHeight > maxHeight {
      newHeight = maxHeight
    }
    let difference = newHeight - frame.height

    return (newHeight, difference)
  }

  /// 根据传入行数计算高度
  /// - Parameter numerOfLines: 行数
  /// - Returns: 高度
  func heightForNumberOfLines(_ numberOfLines: Int) -> CGFloat {
    var text = "-"
    if numberOfLines > 0 {
      for _ in 1 ..< numberOfLines {
        text += "\n|W|"
      }
    }
    let textViewCopy: NEInternalTextView = textView.copy() as! NEInternalTextView
    textViewCopy.text = text
    let height = ceil(textViewCopy.sizeThatFits(textViewCopy.frame.size).height + contentInset.top + contentInset.bottom)
    return height
  }

  func updateMaxHeight() {
    guard let maxNumberOfLines = maxNumberOfLines else {
      return
    }
    maxHeight = heightForNumberOfLines(maxNumberOfLines)
  }

  func updateMinHeight() {
    guard let minNumberOfLines = minNumberOfLines else {
      return
    }
    minHeight = heightForNumberOfLines(minNumberOfLines)
  }

  /// 更新滚动位置
  /// - Parameter animated: 是否动画
  func updateScrollPosition(animated: Bool) {
    guard let selectedTextRange = textView.selectedTextRange else {
      return
    }
    let caretRect = textView.caretRect(for: selectedTextRange.end)
    let caretY = max(caretRect.origin.y + caretRect.height - textView.frame.height, 0)

    // Continuous multiple "\r\n" get an infinity caret rect, set it as the content offset will result in crash.
    guard caretY != CGFloat.infinity, caretY != CGFloat.greatestFiniteMagnitude else {
      print("Invalid caretY: \(caretY)")
      return
    }

    if animated {
      UIView.beginAnimations(nil, context: nil)
      UIView.setAnimationBeginsFromCurrentState(true)
      textView.setContentOffset(CGPoint(x: 0, y: caretY), animated: false)
      UIView.commitAnimations()
    } else {
      textView.setContentOffset(CGPoint(x: 0, y: caretY), animated: false)
    }
  }
}

// MARK: - TextView delegate

extension NEGrowingTextView: UITextViewDelegate {
  /// 文本是否可以开始编辑
  /// - Parameter textView: 文本控件
  /// - Return 是否允许编辑
  public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
    if let delegate = delegate, delegate.responds(to: DelegateSelectors.shouldBeginEditing) {
      return delegate.growingTextViewShouldBeginEditing!(self)
    }
    return true
  }

  /// 文本是否可以结束编辑
  /// - Parameter textView: 文本控件
  /// - Return 是否允许结束编辑
  public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
    if let delegate = delegate, delegate.responds(to: DelegateSelectors.shouldEndEditing) {
      return delegate.growingTextViewShouldEndEditing!(self)
    }
    return true
  }

  /// 文本开始编辑
  /// - Parameter textView: 文本控件
  public func textViewDidBeginEditing(_ textView: UITextView) {
    if let delegate = delegate, delegate.responds(to: DelegateSelectors.didBeginEditing) {
      delegate.growingTextViewDidBeginEditing!(self)
    }
  }

  /// 文本结束编辑
  /// - Parameter textView: 文本控件
  public func textViewDidEndEditing(_ textView: UITextView) {
    if let delegate = delegate, delegate.responds(to: DelegateSelectors.didEndEditing) {
      delegate.growingTextViewDidEndEditing!(self)
    }
  }

  /// 文本是否可以改变
  /// - Parameter textView: 文本控件
  /// - Parameter range: 范围
  /// - Parameter text: 文本
  /// - Return 是否可以改变
  public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    if !hasText && text == "" {
      return false
    }
    if let delegate = delegate, delegate.responds(to: DelegateSelectors.shouldChangeText) {
      return delegate.growingTextView!(self, shouldChangeTextInRange: range, replacementText: text)
    }

    if text == "\n" {
      if let delegate = delegate, delegate.responds(to: DelegateSelectors.shouldReturn) {
        return delegate.growingTextViewShouldReturn!(self)
      } else {
        textView.resignFirstResponder()
        return false
      }
    }
    return true
  }

  /// 文本改变
  /// - Parameter textView: 文本控件
  public func textViewDidChange(_ textView: UITextView) {
    updateHeight()
    if let delegate = delegate, delegate.responds(to: DelegateSelectors.didChange) {
      delegate.growingTextViewDidChange!(self)
    }
  }

  /// 文本选择改变
  /// - Parameter textView: 文本控件
  public func textViewDidChangeSelection(_ textView: UITextView) {
    let willUpdateHeight = updatedHeight().difference != 0
    if !willUpdateHeight {
      updateScrollPosition(animated: true)
    }
    if let delegate = delegate, delegate.responds(to: DelegateSelectors.didChangeSelection) {
      delegate.growingTextViewDidChangeSelection!(self)
    }
  }
}
