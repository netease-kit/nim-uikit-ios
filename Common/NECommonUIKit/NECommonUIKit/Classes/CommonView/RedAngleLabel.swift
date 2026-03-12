
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class RedAngleLabel: UILabel {
  public var textInsets: UIEdgeInsets = .zero
  override open func drawText(in rect: CGRect) {
    super.drawText(in: rect.inset(by: textInsets))
    accessibilityIdentifier = "id.unread"
  }

  override open func textRect(forBounds bounds: CGRect,
                              limitedToNumberOfLines numberOfLines: Int) -> CGRect {
    let insets = textInsets
    var rect = super.textRect(forBounds: bounds.inset(by: insets),
                              limitedToNumberOfLines: numberOfLines)

    rect.origin.x -= insets.left
    rect.origin.y -= insets.top
    rect.size.width += (insets.left + insets.right)
    rect.size.height += (insets.top + insets.bottom)
    return rect
  }
}
