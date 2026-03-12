// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

public class NEOverlayMenuCell: NEPagingMenuViewCell {
  public weak var referencedMenuView: NETabPagingMenuView?
  public weak var referencedFocusView: PagingMenuFocusView?

  public var hightlightTextColor: UIColor? {
    set {
      highlightLabel.textColor = newValue
    }
    get {
      return highlightLabel.textColor
    }
  }

  public var normalTextColor: UIColor? {
    set {
      titleLabel.textColor = newValue
    }
    get {
      return titleLabel.textColor
    }
  }

  public var hightlightTextFont: UIFont? {
    set {
      highlightLabel.font = newValue
    }
    get {
      return highlightLabel.font
    }
  }

  public var normalTextFont: UIFont? {
    set {
      titleLabel.font = newValue
    }
    get {
      return titleLabel.font
    }
  }

  public static let sizingCell = NEOverlayMenuCell()

  let maskInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)

  let textMaskView: UIView = {
    let view = UIView()
    view.backgroundColor = .black
    return view
  }()

  let highlightLabel = UILabel()
  let titleLabel = UILabel()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    addConstraints()
    highlightLabel.mask = textMaskView
    highlightLabel.textColor = .white
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    addConstraints()
    highlightLabel.mask = textMaskView
    highlightLabel.textColor = .white
  }

  override public func layoutSubviews() {
    super.layoutSubviews()
    textMaskView.bounds = bounds.inset(by: maskInsets)
  }

  public func configure(title: String) {
    titleLabel.text = title
    highlightLabel.text = title
  }

  public func updateMask(animated: Bool = true) {
    guard let menuView = referencedMenuView, let focusView = referencedFocusView else {
      return
    }

    setFrame(menuView, maskFrame: focusView.frame, animated: animated)
  }

  func setFrame(_ menuView: NETabPagingMenuView, maskFrame: CGRect, animated: Bool) {
    textMaskView.frame = menuView.convert(maskFrame, to: highlightLabel).inset(by: maskInsets)

    if let expectedOriginX = menuView.getExpectedAlignmentPositionXIfNeeded() {
      textMaskView.frame.origin.x += expectedOriginX
    }
  }

  public func calculateWidth(from height: CGFloat, title: String) -> CGFloat {
    configure(title: title)
    var referenceSize = UIView.layoutFittingCompressedSize
    referenceSize.height = height
    let size = systemLayoutSizeFitting(referenceSize, withHorizontalFittingPriority: UILayoutPriority.defaultLow, verticalFittingPriority: UILayoutPriority.defaultHigh)
    return size.width
  }
}

extension NEOverlayMenuCell {
  private func addConstraints() {
    addSubview(titleLabel)
    addSubview(highlightLabel)

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    highlightLabel.translatesAutoresizingMaskIntoConstraints = false

    for element in [titleLabel, highlightLabel] {
      let trailingConstraint = NSLayoutConstraint(
        item: self,
        attribute: .trailing,
        relatedBy: .equal,
        toItem: element,
        attribute: .trailing,
        multiplier: 1,
        constant: 16
      )
      let leadingConstraint = NSLayoutConstraint(
        item: element,
        attribute: .leading,
        relatedBy: .equal,
        toItem: self,
        attribute: .leading,
        multiplier: 1,
        constant: 16
      )
      let bottomConstraint = NSLayoutConstraint(
        item: self,
        attribute: .top,
        relatedBy: .equal,
        toItem: element,
        attribute: .top,
        multiplier: 1,
        constant: 8
      )
      let topConstraint = NSLayoutConstraint(
        item: element,
        attribute: .bottom,
        relatedBy: .equal,
        toItem: self,
        attribute: .bottom,
        multiplier: 1,
        constant: 8
      )

      addConstraints([topConstraint, bottomConstraint, trailingConstraint, leadingConstraint])
    }
  }
}
