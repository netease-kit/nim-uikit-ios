// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

/// tabbar滑动指示器数据源填充协议
public protocol NEPagingMenuDataSource: AnyObject {
  func pagingItemBefore(pagingItem: NEPagingItem) -> NEPagingItem?
  func pagingItemAfter(pagingItem: NEPagingItem) -> NEPagingItem?
}
