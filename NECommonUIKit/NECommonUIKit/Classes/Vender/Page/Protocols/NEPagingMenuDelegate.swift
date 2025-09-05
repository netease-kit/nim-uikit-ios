// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

/// 指示器交互协议
public protocol NEPagingMenuDelegate: AnyObject {
  /// 选择的内容
  /// - Parameter pagingItem: 页卡数据模型
  /// - Parameter direction: 滑动方向
  /// - Parameter animated: 是否需要动画
  func selectContent(pagingItem: NEPagingItem, direction: PagingDirection, animated: Bool)
  /// 移除内容
  func removeContent()
}
