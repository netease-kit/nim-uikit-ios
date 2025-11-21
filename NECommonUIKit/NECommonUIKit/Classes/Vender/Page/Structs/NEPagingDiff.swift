// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

struct NEPagingDiff {
  private let from: NEPagingItems
  private let to: NEPagingItems
  private var fromCache: [Int: NEPagingItem]
  private var toCache: [Int: NEPagingItem]
  private var lastMatchingItem: NEPagingItem?

  public init(from: NEPagingItems, to: NEPagingItems) {
    self.from = from
    self.to = to
    fromCache = [:]
    toCache = [:]

    for item in from.items {
      fromCache[item.identifier] = item
    }

    for item in to.items {
      toCache[item.identifier] = item
    }

    for toItem in to.items {
      for fromItem in from.items {
        if toItem.isEqual(to: fromItem) {
          lastMatchingItem = toItem
          break
        }
      }
    }
  }

  func removed() -> [IndexPath] {
    let removed = diff(visibleItems: from, cache: toCache)
    var items: [IndexPath] = []

    if let lastItem = lastMatchingItem {
      for indexPath in removed {
        if let lastIndexPath = from.indexPath(for: lastItem) {
          if indexPath.item < lastIndexPath.item {
            items.append(indexPath)
          }
        }
      }
    }

    return items
  }

  func added() -> [IndexPath] {
    let removedCount = removed().count
    let added = diff(visibleItems: to, cache: fromCache)

    var items: [IndexPath] = []

    if let lastItem = lastMatchingItem {
      for indexPath in added {
        if let lastIndexPath = from.indexPath(for: lastItem) {
          if indexPath.item + removedCount <= lastIndexPath.item {
            items.append(indexPath)
          }
        }
      }
    }

    return items
  }

  private func diff(visibleItems: NEPagingItems, cache: [Int: NEPagingItem]) -> [IndexPath] {
    visibleItems.items.compactMap { item in
      if cache[item.identifier] == nil {
        return visibleItems.indexPath(for: item)
      }
      return nil
    }
  }
}
