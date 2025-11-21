// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import UIKit

class NEPagingSizeCache {
  var options: NEPagingOptions
  var implementsSizeDelegate: Bool = false
  var sizeForPagingItem: ((NEPagingItem, Bool) -> CGFloat?)?

  /// 缓存大小
  private var sizeCache: [Int: CGFloat] = [:]

  private var selectedSizeCache: [Int: CGFloat] = [:]

  public init(options: NEPagingOptions) {
    self.options = options

    let didEnterBackground = UIApplication.didEnterBackgroundNotification
    let didReceiveMemoryWarning = UIApplication.didReceiveMemoryWarningNotification

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(applicationDidEnterBackground(notification:)),
                                           name: didEnterBackground,
                                           object: nil)

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(didReceiveMemoryWarning(notification:)),
                                           name: didReceiveMemoryWarning,
                                           object: nil)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  /// 清理缓存
  func clear() {
    sizeCache = [:]
    selectedSizeCache = [:]
  }

  func itemSize(for pagingItem: NEPagingItem) -> CGFloat {
    if let size = sizeCache[pagingItem.identifier] {
      return size
    } else {
      let size = sizeForPagingItem?(pagingItem, false)
      sizeCache[pagingItem.identifier] = size
      return size ?? options.estimatedItemWidth
    }
  }

  func itemWidthSelected(for pagingItem: NEPagingItem) -> CGFloat {
    if let size = selectedSizeCache[pagingItem.identifier] {
      return size
    } else {
      let size = sizeForPagingItem?(pagingItem, true)
      selectedSizeCache[pagingItem.identifier] = size
      return size ?? options.estimatedItemWidth
    }
  }

  /// 收到内存警告，清理缓存
  @objc private func didReceiveMemoryWarning(notification _: NSNotification) {
    clear()
  }

  /// 进入后台，清理缓存
  @objc private func applicationDidEnterBackground(notification _: NSNotification) {
    clear()
  }
}
