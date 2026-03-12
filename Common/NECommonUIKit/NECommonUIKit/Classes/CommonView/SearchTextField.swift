
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class SearchTextField: UITextField {
  public var leftViewRectX: CGFloat?

  override open func leftViewRect(forBounds bounds: CGRect) -> CGRect {
    var rect = super.leftViewRect(forBounds: bounds)
    rect.origin.x += 10

    if let x = leftViewRectX {
      rect.origin.x = x
    }

    return rect
  }

  override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
    var rect = super.placeholderRect(forBounds: bounds)
    rect.origin.x += 1
    return rect
  }

  override open func editingRect(forBounds bounds: CGRect) -> CGRect {
    var rect = super.editingRect(forBounds: bounds)
    rect.origin.x += 5
    return rect
  }

  override open func textRect(forBounds bounds: CGRect) -> CGRect {
    var rect = super.textRect(forBounds: bounds)
    rect.origin.x += 5
    return rect
  }
}
