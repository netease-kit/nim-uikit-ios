
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class ExpandButton: UIButton {
  override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    var bounds = bounds
    // 若原热区小于44*44， 则放大热区，否则保持不变
    let widthDelta = max(44.0 - bounds.size.width, 0)
    let heightDelta = max(44.0 - bounds.size.height, 0)

    bounds = bounds.insetBy(dx: -0.5 * widthDelta, dy: -0.5 * heightDelta)

    // 如果返回新的bounds里，就返回YES
    return bounds.contains(point)
  }
}
