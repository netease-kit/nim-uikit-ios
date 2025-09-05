// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

open class NEPagingBorderView: UICollectionReusableView {
  /// 启用布局参数
  /// - Parameter layoutAttributes: 布局参数
  override open func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    super.apply(layoutAttributes)
    if let attributes = layoutAttributes as? NEPagingBorderLayoutAttributes {
      backgroundColor = attributes.backgroundColor
    }
  }
}
