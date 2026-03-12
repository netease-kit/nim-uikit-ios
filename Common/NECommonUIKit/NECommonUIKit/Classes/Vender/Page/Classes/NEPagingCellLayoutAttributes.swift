// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

open class NEPagingCellLayoutAttributes: UICollectionViewLayoutAttributes {
  open var progress: CGFloat = 0.0

  override open func copy(with zone: NSZone? = nil) -> Any {
    let copy = super.copy(with: zone) as! NEPagingCellLayoutAttributes
    copy.progress = progress
    return copy
  }

  /// 判断是否相同
  override open func isEqual(_ object: Any?) -> Bool {
    if let rhs = object as? NEPagingCellLayoutAttributes {
      if progress != rhs.progress {
        return false
      }
      return super.isEqual(object)
    } else {
      return false
    }
  }
}
