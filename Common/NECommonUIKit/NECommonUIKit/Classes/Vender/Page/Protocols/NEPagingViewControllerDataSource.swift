// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

public protocol NEPagingViewControllerDataSource: AnyObject {
  /// 视图个数协议
  func numberOfViewControllers(in pagingViewController: NEPagingViewController) -> Int
  /// 获取某个索引的视图协议
  func pagingViewController(_: NEPagingViewController, viewControllerAt index: Int) -> UIViewController
  /// 获取某个滑动item协议
  func pagingViewController(_: NEPagingViewController, pagingItemAt index: Int) -> NEPagingItem
}
