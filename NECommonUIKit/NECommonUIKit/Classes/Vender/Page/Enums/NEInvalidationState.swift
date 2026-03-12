// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

public enum NEInvalidationState {
  case nothing
  case everything
  case sizes

  /// 状态初始化
  public init(_ invalidationContext: UICollectionViewLayoutInvalidationContext) {
    if invalidationContext.invalidateEverything {
      self = .everything
    } else if invalidationContext.invalidateDataSourceCounts {
      self = .everything
    } else if let context = invalidationContext as? NEPagingInvalidationContext {
      if context.invalidateSizes {
        self = .sizes
      } else {
        self = .nothing
      }
    } else {
      self = .nothing
    }
  }

  public static func + (lhs: NEInvalidationState, rhs: NEInvalidationState) -> NEInvalidationState {
    switch (lhs, rhs) {
    case (.everything, _), (_, .everything):
      return .everything
    case (.sizes, _), (_, .sizes):
      return .sizes
    case (.nothing, _), (_, .nothing):
      return .nothing
    default:
      return .everything
    }
  }
}
