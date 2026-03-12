
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// import Foundation - UIKit contains Foundation
import UIKit

/**
 UIView.subviews sorting category.
 */
@available(iOSApplicationExtension, unavailable)
extension Array where Element: UIView {
  /**
   Returns the array by sorting the UIView's by their tag property.
   */
  func neSortedArrayByTag() -> [Element] {
    sorted(by: { (obj1: Element, obj2: Element) -> Bool in
      obj1.tag < obj2.tag
    })
  }

  /**
   Returns the array by sorting the UIView's by their tag property.
   */
  func neSortedArrayByPosition() -> [Element] {
    sorted(by: { (obj1: Element, obj2: Element) -> Bool in
      if obj1.frame.minY != obj2.frame.minY {
        return obj1.frame.minY < obj2.frame.minY
      } else {
        return obj1.frame.minX < obj2.frame.minX
      }
    })
  }
}
