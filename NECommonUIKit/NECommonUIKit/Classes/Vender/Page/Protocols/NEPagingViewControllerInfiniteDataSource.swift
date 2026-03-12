// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// 滑动区循环滑动数据填充协议
public protocol NEPagingViewControllerInfiniteDataSource: AnyObject {
  func pagingViewController(_: NEPagingViewController, viewControllerFor pagingItem: NEPagingItem) -> UIViewController

  func pagingViewController(_: NEPagingViewController, itemBefore pagingItem: NEPagingItem) -> NEPagingItem?

  func pagingViewController(_: NEPagingViewController, itemAfter pagingItem: NEPagingItem) -> NEPagingItem?
}
