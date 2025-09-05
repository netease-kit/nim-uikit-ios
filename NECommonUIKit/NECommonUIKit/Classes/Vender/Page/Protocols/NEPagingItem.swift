// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

public protocol NEPagingItem {
  var identifier: Int { get }
  func isEqual(to item: NEPagingItem) -> Bool
  func isBefore(item: NEPagingItem) -> Bool
}

public extension NEPagingItem where Self: Equatable {
  func isEqual(to item: NEPagingItem) -> Bool {
    guard let item = item as? Self else { return false }
    return self == item
  }
}

public extension NEPagingItem where Self: Comparable {
  func isBefore(item: NEPagingItem) -> Bool {
    guard let item = item as? Self else { return false }
    return self < item
  }
}

public extension NEPagingItem where Self: Hashable {
  var identifier: Int {
    hashValue
  }
}
