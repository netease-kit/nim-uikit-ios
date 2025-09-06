// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

public extension UIView {
  // 检查视图是否在屏幕可见范围内
  var isVisibleInWindow: Bool {
    guard let window = window else { return false }
    let viewFrame = convert(bounds, to: window)
    return window.bounds.intersects(viewFrame)
  }
}

extension UIView {
  func constrainToEdges(_ subview: UIView) {
    subview.translatesAutoresizingMaskIntoConstraints = false

    let topContraint = NSLayoutConstraint(
      item: subview,
      attribute: .top,
      relatedBy: .equal,
      toItem: self,
      attribute: .top,
      multiplier: 1.0,
      constant: 0
    )

    let bottomConstraint = NSLayoutConstraint(
      item: subview,
      attribute: .bottom,
      relatedBy: .equal,
      toItem: self,
      attribute: .bottom,
      multiplier: 1.0,
      constant: 0
    )

    let leadingContraint = NSLayoutConstraint(
      item: subview,
      attribute: .leading,
      relatedBy: .equal,
      toItem: self,
      attribute: .leading,
      multiplier: 1.0,
      constant: 0
    )

    let trailingContraint = NSLayoutConstraint(
      item: subview,
      attribute: .trailing,
      relatedBy: .equal,
      toItem: self,
      attribute: .trailing,
      multiplier: 1.0,
      constant: 0
    )

    addConstraints([
      topContraint,
      bottomConstraint,
      leadingContraint,
      trailingContraint,
    ])
  }
}
