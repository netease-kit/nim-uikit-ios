
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// import Foundation - UIKit contains Foundation
import UIKit

@available(iOSApplicationExtension, unavailable)
@objc public extension UIScrollView {
  private enum NEAssociatedKeys {
    static var shouldIgnoreScrollingAdjustment = "shouldIgnoreScrollingAdjustment"
    static var shouldIgnoreContentInsetAdjustment = "shouldIgnoreContentInsetAdjustment"
    static var shouldRestoreScrollViewContentOffset = "shouldRestoreScrollViewContentOffset"
  }

  /**
   If YES, then scrollview will ignore scrolling (simply not scroll it) for adjusting textfield position. Default is NO.
   */
  var neShouldIgnoreScrollingAdjustment: Bool {
    get {
      objc_getAssociatedObject(
        self,
        &NEAssociatedKeys.shouldIgnoreScrollingAdjustment
      ) as? Bool ?? false
    }
    set(newValue) {
      objc_setAssociatedObject(
        self,
        &NEAssociatedKeys.shouldIgnoreScrollingAdjustment,
        newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  /**
   If YES, then scrollview will ignore content inset adjustment (simply not updating it) when keyboard is shown. Default is NO.
   */
  var neShouldIgnoreContentInsetAdjustment: Bool {
    get {
      objc_getAssociatedObject(
        self,
        &NEAssociatedKeys.shouldIgnoreContentInsetAdjustment
      ) as? Bool ?? false
    }
    set(newValue) {
      objc_setAssociatedObject(
        self,
        &NEAssociatedKeys.shouldIgnoreContentInsetAdjustment,
        newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  /**
   To set customized distance from keyboard for textField/textView. Can't be less than zero
   */
  var neShouldRestoreScrollViewContentOffset: Bool {
    get {
      objc_getAssociatedObject(
        self,
        &NEAssociatedKeys.shouldRestoreScrollViewContentOffset
      ) as? Bool ?? false
    }
    set(newValue) {
      objc_setAssociatedObject(
        self,
        &NEAssociatedKeys.shouldRestoreScrollViewContentOffset,
        newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }
}

@available(iOSApplicationExtension, unavailable)
extension UITableView {
  func nePreviousIndexPath(of indexPath: IndexPath) -> IndexPath? {
    var previousRow = indexPath.row - 1
    var previousSection = indexPath.section

    // Fixing indexPath
    if previousRow < 0 {
      previousSection -= 1
      if previousSection >= 0 {
        previousRow = numberOfRows(inSection: previousSection) - 1
      }
    }

    if previousRow >= 0, previousSection >= 0 {
      return IndexPath(row: previousRow, section: previousSection)
    } else {
      return nil
    }
  }
}

@available(iOSApplicationExtension, unavailable)
extension UICollectionView {
  func nePreviousIndexPath(of indexPath: IndexPath) -> IndexPath? {
    var previousRow = indexPath.row - 1
    var previousSection = indexPath.section

    // Fixing indexPath
    if previousRow < 0 {
      previousSection -= 1
      if previousSection >= 0 {
        previousRow = numberOfItems(inSection: previousSection) - 1
      }
    }

    if previousRow >= 0, previousSection >= 0 {
      return IndexPath(item: previousRow, section: previousSection)
    } else {
      return nil
    }
  }
}
