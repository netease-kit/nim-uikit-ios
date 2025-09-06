// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// 边框配置枚举
public enum NEPagingBorderOptions {
  case hidden
  case visible(
    height: CGFloat,
    zIndex: Int,
    insets: UIEdgeInsets
  )
}
