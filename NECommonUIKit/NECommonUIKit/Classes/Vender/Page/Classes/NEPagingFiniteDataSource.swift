// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import UIKit

class NEPagingFiniteDataSource: NEPagingViewControllerInfiniteDataSource {
  var items: [NEPagingItem] = []
  var viewControllerForIndex: ((Int) -> UIViewController?)?

  func pagingViewController(_: NEPagingViewController, viewControllerFor pagingItem: NEPagingItem) -> UIViewController {
    guard let index = items.firstIndex(where: { $0.isEqual(to: pagingItem) }) else {
      fatalError("pagingViewController:viewControllerFor: PagingItem does not exist")
    }
    guard let viewController = viewControllerForIndex?(index) else {
      fatalError("pagingViewController:viewControllerFor: No view controller exist for PagingItem")
    }

    return viewController
  }

  func pagingViewController(_: NEPagingViewController, itemBefore pagingItem: NEPagingItem) -> NEPagingItem? {
    guard let index = items.firstIndex(where: { $0.isEqual(to: pagingItem) }) else { return nil }
    if index > 0 {
      return items[index - 1]
    }
    return nil
  }

  func pagingViewController(_: NEPagingViewController, itemAfter pagingItem: NEPagingItem) -> NEPagingItem? {
    guard let index = items.firstIndex(where: { $0.isEqual(to: pagingItem) }) else { return nil }
    if index < items.count - 1 {
      return items[index + 1]
    }
    return nil
  }
}
