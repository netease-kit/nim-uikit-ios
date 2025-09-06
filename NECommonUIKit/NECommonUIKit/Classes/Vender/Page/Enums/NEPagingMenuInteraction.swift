// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

/// 指示器滑动配置枚举
public enum PagingMenuInteraction {
  /// 滑动
  case scrolling
  /// 页卡式翻动(保证滑动距离至少是一个指示器的宽度)
  case swipe
  case none
}
