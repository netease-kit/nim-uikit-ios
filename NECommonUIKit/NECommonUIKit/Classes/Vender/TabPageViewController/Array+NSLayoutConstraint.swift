// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

extension Array where Element == NSLayoutConstraint.Attribute {
  /// anchor same attributes between fromView and toView
  /// convert to "view1.attr1 = view2.attr2 * multiplier + constant"
  /// - Parameters:
  ///   - from: view1
  ///   - to: view2
  /// - Returns: NSLayoutAttributes
  func anchor(from fromView: UIView, to toView: UIView) -> [NSLayoutConstraint] {
    return map {
      NSLayoutConstraint(
        item: fromView,
        attribute: $0,
        relatedBy: .equal,
        toItem: toView,
        attribute: $0,
        multiplier: 1,
        constant: 0
      )
    }
  }
}
