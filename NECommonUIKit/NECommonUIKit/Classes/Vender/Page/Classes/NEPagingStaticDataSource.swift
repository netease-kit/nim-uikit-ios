// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import UIKit

class NEPagingStaticDataSource: NEPagingViewControllerInfiniteDataSource {
  private(set) var items: [NEPagingItem] = []
  private let viewControllers: [UIViewController]

  init(viewControllers: [UIViewController]) {
    self.viewControllers = viewControllers
    reloadItems()
  }

  func pagingItem(at index: Int) -> NEPagingItem {
    items[index]
  }

  /// 重新加载
  func reloadItems() {
    items = viewControllers.enumerated().map {
      NEPagingIndexItem(index: $0, title: $1.title ?? "")
    }
  }

  /// 数据填充回调
  func pagingViewController(_: NEPagingViewController, viewControllerFor pagingItem: NEPagingItem) -> UIViewController {
    guard let index = items.firstIndex(where: { $0.isEqual(to: pagingItem) }) else {
      fatalError("pagingViewController:viewControllerFor: PagingItem does not exist")
    }
    return viewControllers[index]
  }

  /// 前置滑动指示器填充回调
  func pagingViewController(_: NEPagingViewController, itemBefore pagingItem: NEPagingItem) -> NEPagingItem? {
    guard let index = items.firstIndex(where: { $0.isEqual(to: pagingItem) }) else { return nil }
    if index > 0 {
      return items[index - 1]
    }
    return nil
  }

  /// 后置滑动指示器填充回调
  func pagingViewController(_: NEPagingViewController, itemAfter pagingItem: NEPagingItem) -> NEPagingItem? {
    guard let index = items.firstIndex(where: { $0.isEqual(to: pagingItem) }) else { return nil }
    if index < items.count - 1 {
      return items[index + 1]
    }
    return nil
  }
}
