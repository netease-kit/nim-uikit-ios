// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

struct NEPagingTransition: Equatable {
  let contentOffset: CGPoint
  let distance: CGFloat

  static func == (lhs: NEPagingTransition, rhs: NEPagingTransition) -> Bool {
    lhs.contentOffset == rhs.contentOffset && lhs.distance == rhs.distance
  }
}
