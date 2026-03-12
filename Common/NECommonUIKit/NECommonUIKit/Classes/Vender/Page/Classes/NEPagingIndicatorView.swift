// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

open class NEPagingIndicatorView: UICollectionReusableView {
  override open func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    super.apply(layoutAttributes)
    if let attributes = layoutAttributes as? NEPagingIndicatorLayoutAttributes {
      backgroundColor = attributes.backgroundColor
    }
  }
}
