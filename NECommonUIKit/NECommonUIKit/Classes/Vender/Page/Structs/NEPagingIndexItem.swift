// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

public struct NEPagingIndexItem: NEPagingItem, Hashable, Comparable {
  public let index: Int

  public let title: String

  public init(index: Int, title: String) {
    self.index = index
    self.title = title
  }

  public static func < (lhs: NEPagingIndexItem, rhs: NEPagingIndexItem) -> Bool {
    lhs.index < rhs.index
  }
}
