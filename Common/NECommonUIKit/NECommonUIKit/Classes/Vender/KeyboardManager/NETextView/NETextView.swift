
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/** @abstract UITextView with placeholder support   */
@available(iOSApplicationExtension, unavailable)
@objc open class NETextView: UITextView {
  @objc public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(refreshPlaceholder),
      name: UITextView.textDidChangeNotification,
      object: self
    )
  }

  @objc override public init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(refreshPlaceholder),
      name: UITextView.textDidChangeNotification,
      object: self
    )
  }

  @objc override open func awakeFromNib() {
    super.awakeFromNib()
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(refreshPlaceholder),
      name: UITextView.textDidChangeNotification,
      object: self
    )
  }

  deinit {
    placeholderLabel.removeFromSuperview()
  }

  private var placeholderInsets: UIEdgeInsets {
    UIEdgeInsets(
      top: textContainerInset.top,
      left: textContainerInset.left + textContainer.lineFragmentPadding,
      bottom: textContainerInset.bottom,
      right: textContainerInset.right + textContainer.lineFragmentPadding
    )
  }

  private var placeholderExpectedFrame: CGRect {
    let placeholderInsets = placeholderInsets
    let maxWidth = frame.width - placeholderInsets.left - placeholderInsets.right
    let expectedSize = placeholderLabel.sizeThatFits(CGSize(
      width: maxWidth,
      height: frame.height - placeholderInsets.top - placeholderInsets.bottom
    ))

    return CGRect(
      x: placeholderInsets.left,
      y: placeholderInsets.top,
      width: maxWidth,
      height: expectedSize.height
    )
  }

  public lazy var placeholderLabel: UILabel = {
    let label = UILabel()

    label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    label.lineBreakMode = .byWordWrapping
    label.numberOfLines = 0
    label.font = self.font
    label.textAlignment = self.textAlignment
    label.backgroundColor = UIColor.clear
    label.isAccessibilityElement = false
    #if swift(>=5.1)
      label.textColor = UIColor.systemGray
    #else
      label.textColor = UIColor.lightText
    #endif
    label.alpha = 0
    self.addSubview(label)

    return label
  }()

  /** @abstract To set textView's placeholder text color. */
  @IBInspectable open var placeholderTextColor: UIColor? {
    get {
      placeholderLabel.textColor
    }

    set {
      placeholderLabel.textColor = newValue
    }
  }

  /** @abstract To set textView's placeholder text. Default is nil.    */
  @IBInspectable open var placeholder: String? {
    get {
      placeholderLabel.text
    }

    set {
      placeholderLabel.text = newValue
      refreshPlaceholder()
    }
  }

  /** @abstract To set textView's placeholder attributed text. Default is nil.    */
  open var attributedPlaceholder: NSAttributedString? {
    get {
      placeholderLabel.attributedText
    }

    set {
      placeholderLabel.attributedText = newValue
      refreshPlaceholder()
    }
  }

  @objc override open func layoutSubviews() {
    super.layoutSubviews()

    placeholderLabel.frame = placeholderExpectedFrame
  }

  @objc func refreshPlaceholder() {
    if !text.isEmpty || !attributedText.string.isEmpty {
      placeholderLabel.alpha = 0
    } else {
      placeholderLabel.alpha = 1
    }
  }

  @objc override open var text: String! {
    didSet {
      refreshPlaceholder()
    }
  }

  override open var attributedText: NSAttributedString! {
    didSet {
      refreshPlaceholder()
    }
  }

  @objc override open var font: UIFont? {
    didSet {
      if let unwrappedFont = font {
        placeholderLabel.font = unwrappedFont
      } else {
        placeholderLabel.font = UIFont.systemFont(ofSize: 12)
      }
    }
  }

  @objc override open var textAlignment: NSTextAlignment {
    didSet {
      placeholderLabel.textAlignment = textAlignment
    }
  }

  @objc override open weak var delegate: UITextViewDelegate? {
    get {
      refreshPlaceholder()
      return super.delegate
    }

    set {
      super.delegate = newValue
    }
  }

  @objc override open var intrinsicContentSize: CGSize {
    guard !hasText else {
      return super.intrinsicContentSize
    }

    var newSize = super.intrinsicContentSize
    let placeholderInsets = placeholderInsets
    newSize.height = placeholderExpectedFrame.height + placeholderInsets.top + placeholderInsets
      .bottom

    return newSize
  }

  public func removeAllAutoLayout() {
    removeConstraints(constraints)

    for constraint in superview?.constraints ?? [] {
      if let firstItem = constraint.firstItem as? UIView, firstItem == self {
        superview?.removeConstraint(constraint)
      }
    }
  }
}
