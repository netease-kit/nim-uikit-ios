// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import UIKit

public enum NEPagingState: Equatable {
  case empty
  case selected(pagingItem: NEPagingItem)
  case scrolling(
    pagingItem: NEPagingItem,
    upcomingPagingItem: NEPagingItem?,
    progress: CGFloat,
    initialContentOffset: CGPoint,
    distance: CGFloat
  )
}

public extension NEPagingState {
  /// 当前选中页的状态
  var currentPagingItem: NEPagingItem? {
    switch self {
    case .empty:
      return nil
    case let .scrolling(pagingItem, _, _, _, _):
      return pagingItem
    case let .selected(pagingItem):
      return pagingItem
    }
  }

  var upcomingPagingItem: NEPagingItem? {
    switch self {
    case .empty:
      return nil
    case let .scrolling(_, upcomingPagingItem, _, _, _):
      return upcomingPagingItem
    case .selected:
      return nil
    }
  }

  /// 进度
  var progress: CGFloat {
    switch self {
    case let .scrolling(_, _, progress, _, _):
      return progress
    case .selected, .empty:
      return 0
    }
  }

  /// 距离
  var distance: CGFloat {
    switch self {
    case let .scrolling(_, _, _, _, distance):
      return distance
    case .selected, .empty:
      return 0
    }
  }

  var visuallySelectedPagingItem: NEPagingItem? {
    if abs(progress) > 0.5 {
      return upcomingPagingItem ?? currentPagingItem
    } else {
      return currentPagingItem
    }
  }
}

/// 状态判断
public func == (lhs: NEPagingState, rhs: NEPagingState) -> Bool {
  switch (lhs, rhs) {
  case
    (let .scrolling(lhsCurrent, lhsUpcoming, lhsProgress, lhsOffset, lhsDistance),
     let .scrolling(rhsCurrent, rhsUpcoming, rhsProgress, rhsOffset, rhsDistance)):
    if lhsCurrent.isEqual(to: rhsCurrent),
       lhsProgress == rhsProgress,
       lhsOffset == rhsOffset,
       lhsDistance == rhsDistance {
      if let lhsUpcoming = lhsUpcoming, let rhsUpcoming = rhsUpcoming, lhsUpcoming.isEqual(to: rhsUpcoming) {
        return true
      } else if lhsUpcoming == nil, rhsUpcoming == nil {
        return true
      }
    }
    return false
  case let (.selected(a), .selected(b)) where a.isEqual(to: b):
    return true
  case (.empty, .empty):
    return true
  default:
    return false
  }
}
