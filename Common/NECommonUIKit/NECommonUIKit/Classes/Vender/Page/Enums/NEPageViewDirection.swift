// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics
import Foundation

public enum NEPageViewDirection {
  /// 前向
  case forward
  /// 后向
  case reverse
  case none

  init(from direction: PagingDirection) {
    switch direction {
    case .forward:
      self = .forward
    case .reverse:
      self = .reverse
    case .none:
      self = .none
    }
  }

  init(progress: CGFloat) {
    if progress > 0 {
      self = .forward
    } else if progress < 0 {
      self = .reverse
    } else {
      self = .none
    }
  }
}
