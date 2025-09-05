// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

public struct NEPagingItems {
  /// 滑动指示器数据模型数组
  public let items: [NEPagingItem]
  /// 是否有前置数据
  let hasItemsBefore: Bool
  /// 是否有后置数据
  let hasItemsAfter: Bool
  /// 缓存数据
  private var cachedItems: [Int: NEPagingItem]

  /// 初始化构造函数
  public init(items: [NEPagingItem], hasItemsBefore: Bool = false, hasItemsAfter: Bool = false) {
    self.items = items
    self.hasItemsBefore = hasItemsBefore
    self.hasItemsAfter = hasItemsAfter
    cachedItems = [:]

    for item in items {
      cachedItems[item.identifier] = item
    }
  }

  /// 根据数据模型获取索引
  /// - Parameter pagingItem: 数据模型
  /// - Returns: 索引
  public func indexPath(for pagingItem: NEPagingItem) -> IndexPath? {
    guard let index = items.firstIndex(where: { $0.isEqual(to: pagingItem) }) else { return nil }
    return IndexPath(item: index, section: 0)
  }

  /// 根据索引获取数据模型
  /// - Parameter indexPath: 索引
  /// - Returns: 数据模型
  public func pagingItem(for indexPath: IndexPath) -> NEPagingItem {
    items[indexPath.item]
  }

  /// 获取从某个模型运动到另一个数据数据模型的滑动方向
  /// - Parameters:
  ///   - from: 起始数据模型
  ///   - to: 终点数据模型
  /// - Returns: 方向

  public func direction(from: NEPagingItem, to: NEPagingItem) -> PagingDirection {
    if from.isBefore(item: to) {
      return .forward(sibling: isSibling(from: from, to: to))
    } else if to.isBefore(item: from) {
      return .reverse(sibling: isSibling(from: from, to: to))
    }
    return .none
  }

  func isSibling(from: NEPagingItem, to: NEPagingItem) -> Bool {
    guard
      let fromIndex = items.firstIndex(where: { $0.isEqual(to: from) }),
      let toIndex = items.firstIndex(where: { $0.isEqual(to: to) })
    else { return false }

    if fromIndex == toIndex - 1 {
      return true
    } else if fromIndex - 1 == toIndex {
      return true
    } else {
      return false
    }
  }

  /// 是否包含指定数据模型
  /// - Parameter pagingItem: 数据模型
  /// - Returns: 是否包含
  func contains(_ pagingItem: NEPagingItem) -> Bool {
    cachedItems[pagingItem.identifier] != nil ? true : false
  }

  /// 合并数据模型
  /// - Parameter newItems: 新的数据模型
  /// - Returns: 合并后的数据模型
  func union(_ newItems: [NEPagingItem]) -> [NEPagingItem] {
    let old = Set(items.map { AnyPagingItem(base: $0) })
    let new = Set(newItems.map { AnyPagingItem(base: $0) })
    return Array(old.union(new))
      .map(\.base)
      .sorted(by: { $0.isBefore(item: $1) })
  }
}
