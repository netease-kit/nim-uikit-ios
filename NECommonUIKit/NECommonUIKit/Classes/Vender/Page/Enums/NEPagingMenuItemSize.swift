// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import UIKit

public enum NEPagingMenuItemSize {
  case fixed(width: CGFloat, height: CGFloat)

  case selfSizing(estimatedWidth: CGFloat, height: CGFloat)

  case sizeToFit(minWidth: CGFloat, height: CGFloat)
}

public extension NEPagingMenuItemSize {
  var width: CGFloat {
    switch self {
    case let .fixed(width, _): return width
    case let .sizeToFit(minWidth, _): return minWidth
    case let .selfSizing(estimatedWidth, _): return estimatedWidth
    }
  }

  var height: CGFloat {
    switch self {
    case let .fixed(_, height): return height
    case let .sizeToFit(_, height): return height
    case let .selfSizing(_, height): return height
    }
  }
}
