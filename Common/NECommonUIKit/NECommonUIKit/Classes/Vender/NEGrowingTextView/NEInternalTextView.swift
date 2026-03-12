// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

class NEInternalTextView: UITextView, NSCopying {
  /// 缺省占位
  var placeholder: NSAttributedString? {
    didSet {
      setNeedsDisplay()
    }
  }

  /// 是否应该显示占位
  var shouldDisplayPlaceholder = true {
    didSet {
      if shouldDisplayPlaceholder != oldValue {
        setNeedsDisplay()
      }
    }
  }

  var isCaretHidden = false

  fileprivate var isScrollEnabledTemp = false

  /// 文本内容
  override var text: String! {
    willSet {
      isScrollEnabledTemp = isScrollEnabled
      isScrollEnabled = true
    }
    didSet {
      isScrollEnabled = isScrollEnabledTemp
    }
  }

  override func draw(_ rect: CGRect) {
    super.draw(rect)
    guard let placeholder = placeholder, shouldDisplayPlaceholder else {
      return
    }
    let placeholderSize = sizeForAttributedString(placeholder)
    let xPosition: CGFloat = textContainer.lineFragmentPadding + textContainerInset.left
    let yPosition: CGFloat = (textContainerInset.top - textContainerInset.bottom) / 2
    let rect = CGRect(origin: CGPoint(x: xPosition, y: yPosition), size: placeholderSize)
    placeholder.draw(in: rect)
  }

  override func caretRect(for position: UITextPosition) -> CGRect {
    if isCaretHidden {
      return .zero
    }
    return super.caretRect(for: position)
  }

  func copy(with zone: NSZone?) -> Any {
    let textView = NEInternalTextView(frame: frame)
    textView.isScrollEnabled = isScrollEnabled
    textView.shouldDisplayPlaceholder = shouldDisplayPlaceholder
    textView.isCaretHidden = isCaretHidden
    textView.placeholder = placeholder
    textView.text = text
    textView.font = font
    textView.textColor = textColor
    textView.textAlignment = textAlignment
    textView.isEditable = isEditable
    textView.selectedRange = selectedRange
    textView.dataDetectorTypes = dataDetectorTypes
    textView.returnKeyType = returnKeyType
    textView.keyboardType = keyboardType
    textView.enablesReturnKeyAutomatically = enablesReturnKeyAutomatically

    textView.textContainerInset = textContainerInset
    textView.textContainer.lineFragmentPadding = textContainer.lineFragmentPadding
    textView.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
    textView.contentInset = contentInset
    textView.contentMode = contentMode

    return textView
  }

  fileprivate func sizeForAttributedString(_ attributedString: NSAttributedString) -> CGSize {
    let size = attributedString.size()
    return CGRect(origin: .zero, size: size).integral.size
  }
}
