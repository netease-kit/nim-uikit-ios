// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

open class NEPagingBorderLayoutAttributes: UICollectionViewLayoutAttributes {
  open var backgroundColor: UIColor?
  open var insets: UIEdgeInsets = .init()

  /// 拷贝方法
  override open func copy(with zone: NSZone? = nil) -> Any {
    let copy = super.copy(with: zone) as! NEPagingBorderLayoutAttributes
    copy.backgroundColor = backgroundColor
    copy.insets = insets
    return copy
  }

  /// 判断是否相等
  override open func isEqual(_ object: Any?) -> Bool {
    if let rhs = object as? NEPagingBorderLayoutAttributes {
      if backgroundColor != rhs.backgroundColor || insets != rhs.insets {
        return false
      }
      return super.isEqual(object)
    } else {
      return false
    }
  }

  /// 配置UI效果
  /// - Parameter options: 配置项
  /// - Parameter safeAreaInsets: 安全区域
  func configure(_ options: NEPagingOptions, safeAreaInsets _: UIEdgeInsets = .zero) {
    if case let .visible(height, index, borderInsets) = options.borderOptions {
      insets = borderInsets
      backgroundColor = options.borderColor

      switch options.menuPosition {
      case .top:
        frame.origin.y = options.menuHeight - height
      case .bottom:
        frame.origin.y = 0
      }

      frame.size.height = height
      zIndex = index
    }
  }

  /// 更新UI效果
  /// - Parameter contentSize: 内容大小
  /// - Parameter safeAreaInsets: 安全区域边界(防止刘海屏遮挡)
  func update(contentSize: CGSize, bounds: CGRect, safeAreaInsets: UIEdgeInsets) {
    let width = max(bounds.width, contentSize.width)
    frame.size.width = width - insets.horizontal - safeAreaInsets.horizontal
    frame.origin.x = insets.left + safeAreaInsets.left
  }
}
