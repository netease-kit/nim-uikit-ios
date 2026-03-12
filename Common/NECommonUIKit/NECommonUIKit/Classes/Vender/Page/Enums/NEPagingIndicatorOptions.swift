// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// 页面指示器配置
public enum NEPagingIndicatorOptions {
  case hidden
  case visible(
    height: CGFloat,
    zIndex: Int,
    spacing: UIEdgeInsets,
    insets: UIEdgeInsets
  )
}
