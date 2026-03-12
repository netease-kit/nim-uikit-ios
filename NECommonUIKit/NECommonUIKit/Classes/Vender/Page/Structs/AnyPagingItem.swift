// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

/// 自定义item数据类型
struct AnyPagingItem: NEPagingItem, Hashable, Comparable {
  let base: NEPagingItem

  init(base: NEPagingItem) {
    self.base = base
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(base.identifier)
  }

  static func < (lhs: AnyPagingItem, rhs: AnyPagingItem) -> Bool {
    lhs.base.isBefore(item: rhs.base)
  }

  static func == (lhs: AnyPagingItem, rhs: AnyPagingItem) -> Bool {
    lhs.base.isEqual(to: rhs.base)
  }
}
