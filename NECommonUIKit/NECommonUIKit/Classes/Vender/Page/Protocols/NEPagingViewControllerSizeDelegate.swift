// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// 滑动区域size回调协议
public protocol NEPagingViewControllerSizeDelegate: AnyObject {
  func pagingViewController(_: NEPagingViewController,
                            widthForPagingItem pagingItem: NEPagingItem,
                            isSelected: Bool) -> CGFloat
}
