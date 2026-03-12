// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

/// 页面状态枚举
enum NEPageViewState {
  case empty
  case single
  case first
  case center
  case last

  var count: Int {
    switch self {
    case .empty:
      return 0
    case .single:
      return 1
    case .first, .last:
      return 2
    case .center:
      return 3
    }
  }
}
