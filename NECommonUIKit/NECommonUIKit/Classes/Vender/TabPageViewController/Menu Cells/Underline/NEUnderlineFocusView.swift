// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// Basic style of focus view
/// - underline height
/// - underline color
public class NEUnderlineFocusView: UIView {
  /// The color of underline
  public var underlineColor = NEPagingKitConfig.focusColor {
    didSet {
      underlineView.backgroundColor = underlineColor
    }
  }

  /// The color of underline
  public var underlineHeight = CGFloat(4) {
    didSet {
      heightConstraint.constant = underlineHeight
    }
  }

  public var underlineWidth: CGFloat? = nil {
    didSet {
      if let underlineWidth = underlineWidth {
        widthConstraint.isActive = true
        widthConstraint.constant = underlineWidth
      } else {
        widthConstraint.isActive = false
      }
    }
  }

  public var masksToBounds: Bool {
    get { return underlineView.layer.masksToBounds }
    set { underlineView.layer.masksToBounds = newValue }
  }

  public var cornerRadius: CGFloat {
    get { return underlineView.layer.cornerRadius }
    set { underlineView.layer.cornerRadius = newValue }
  }

  private let widthConstraint: NSLayoutConstraint
  private let heightConstraint: NSLayoutConstraint
  private let underlineView = UIView()

  public required init?(coder aDecoder: NSCoder) {
    widthConstraint = NSLayoutConstraint(
      item: underlineView,
      attribute: .width,
      relatedBy: .equal,
      toItem: nil,
      attribute: .width, multiplier: 1, constant: 0
    )

    heightConstraint = NSLayoutConstraint(
      item: underlineView,
      attribute: .height,
      relatedBy: .equal,
      toItem: nil,
      attribute: .height, multiplier: 1, constant: 0
    )
    super.init(coder: aDecoder)
    setup()
  }

  override public init(frame: CGRect) {
    widthConstraint = NSLayoutConstraint(
      item: underlineView,
      attribute: .width,
      relatedBy: .equal,
      toItem: nil,
      attribute: .height, multiplier: 1, constant: underlineHeight
    )

    heightConstraint = NSLayoutConstraint(
      item: underlineView,
      attribute: .height,
      relatedBy: .equal,
      toItem: nil,
      attribute: .height, multiplier: 1, constant: underlineHeight
    )
    super.init(frame: frame)
    setup()
  }

  private func setup() {
    addSubview(underlineView)
    underlineView.translatesAutoresizingMaskIntoConstraints = false
    addConstraint(heightConstraint)
    addConstraint(widthConstraint)
    widthConstraint.isActive = false

    let constraintsA = [.bottom].anchor(from: underlineView, to: self)
    let constraintsB = [.width, .centerX].anchor(from: underlineView, to: self)
    for item in constraintsB {
      item.priority = .defaultHigh
      item.isActive = true
    }
    addConstraints(constraintsA + constraintsB)
    underlineView.backgroundColor = underlineColor
  }
}
