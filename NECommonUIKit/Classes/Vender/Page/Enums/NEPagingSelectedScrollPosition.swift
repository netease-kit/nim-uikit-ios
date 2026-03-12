// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

public enum NEPagingSelectedScrollPosition {
  case left
  case right
  case center
  /// 尽可能使所选菜单项居中。如果项目是向左或向右移动，它将不会更新滚动位置实际上与.centredHorizontally相同UICollectionViewScrollPosition。
  case preferCentered
}
