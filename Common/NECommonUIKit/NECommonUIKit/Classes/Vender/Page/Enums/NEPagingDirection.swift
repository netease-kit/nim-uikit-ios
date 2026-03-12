// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import UIKit

public enum PagingDirection: Equatable {
  case reverse(sibling: Bool)
  case forward(sibling: Bool)
  case none
}

extension PagingDirection {
  var pageViewControllerNavigationDirection: UIPageViewController.NavigationDirection {
    switch self {
    case .forward, .none:
      return .forward
    case .reverse:
      return .reverse
    }
  }
}
