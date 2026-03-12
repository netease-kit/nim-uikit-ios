// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import UIKit

struct NEPagingIndicatorMetric {
  enum Inset {
    case left(CGFloat)
    case right(CGFloat)
    case both(CGFloat, CGFloat)
    case none
  }

  let frame: CGRect
  let insets: Inset
  let spacing: UIEdgeInsets

  var x: CGFloat {
    switch insets {
    case let .left(inset), let .both(inset, _):
      return frame.origin.x + max(inset, spacing.left)
    default:
      return frame.origin.x + spacing.left
    }
  }

  var width: CGFloat {
    switch insets {
    case let .left(inset):
      return frame.size.width - max(inset, spacing.left) - spacing.right
    case let .right(inset):
      return frame.size.width - max(inset, spacing.right) - spacing.left
    case let .both(insetLeft, insetRight):
      return frame.size.width - max(insetRight, spacing.right) - max(insetLeft, spacing.left)
    case .none:
      return frame.size.width - spacing.left - spacing.right
    }
  }
}
