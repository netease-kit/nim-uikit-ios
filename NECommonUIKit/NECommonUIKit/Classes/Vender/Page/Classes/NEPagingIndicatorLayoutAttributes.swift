// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

open class NEPagingIndicatorLayoutAttributes: UICollectionViewLayoutAttributes {
  open var backgroundColor: UIColor?

  override open func copy(with zone: NSZone? = nil) -> Any {
    let copy = super.copy(with: zone) as! NEPagingIndicatorLayoutAttributes
    copy.backgroundColor = backgroundColor
    return copy
  }

  override open func isEqual(_ object: Any?) -> Bool {
    if let rhs = object as? NEPagingIndicatorLayoutAttributes {
      if backgroundColor != rhs.backgroundColor {
        return false
      }
      return super.isEqual(object)
    } else {
      return false
    }
  }

  func configure(_ options: NEPagingOptions) {
    if case let .visible(height, index, _, insets) = options.indicatorOptions {
      backgroundColor = options.indicatorColor
      frame.size.height = height

      switch options.menuPosition {
      case .top:
        frame.origin.y = options.menuHeight - height - insets.bottom + insets.top
      case .bottom:
        frame.origin.y = insets.bottom
      }
      zIndex = index
    }
  }

  func update(from: NEPagingIndicatorMetric, to: NEPagingIndicatorMetric, progress: CGFloat) {
    frame.origin.x = tween(from: from.x, to: to.x, progress: progress)
    frame.size.width = tween(from: from.width, to: to.width, progress: progress)
  }

  func update(to metric: NEPagingIndicatorMetric) {
    frame.origin.x = metric.x
    frame.size.width = metric.width
  }
}
