// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

protocol CollectionViewLayout: AnyObject {
  var state: NEPagingState { get set }
  var visibleItems: NEPagingItems { get set }
  var sizeCache: NEPagingSizeCache? { get set }
  var contentInsets: UIEdgeInsets { get }
  var layoutAttributes: [IndexPath: NEPagingCellLayoutAttributes] { get }
  func prepare()
  func invalidateLayout()
  func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext)
}

extension NEPagingCollectionViewLayout: CollectionViewLayout {}

protocol NECollectionView: AnyObject {
  /// 当前可见items
  var indexPathsForVisibleItems: [IndexPath] { get }
  /// 是否正在拖动
  var isDragging: Bool { get }
  /// window
  var window: UIWindow? { get }
  /// 父视图
  var superview: UIView? { get }
  /// 外框尺寸
  var bounds: CGRect { get }
  /// 滑动偏移量
  var contentOffset: CGPoint { get set }
  /// 内容尺寸
  var contentSize: CGSize { get }
  /// 内容区域内边距
  var contentInset: UIEdgeInsets { get }
  /// 滑动长度位置指示器
  var showsHorizontalScrollIndicator: Bool { get set }
  /// 数据源协议
  var dataSource: UICollectionViewDataSource? { get set }
  /// 可滑动配置
  var isScrollEnabled: Bool { get set }
  /// 是否开启边缘回弹动画效果
  var alwaysBounceHorizontal: Bool { get set }

  var contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior { get set }

  func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier: String)
  func register(_ nib: UINib?, forCellWithReuseIdentifier: String)
  func addGestureRecognizer(_ recognizer: UIGestureRecognizer)
  func removeGestureRecognizer(_ recognizer: UIGestureRecognizer)
  func reloadData()
  func layoutIfNeeded()
  func setContentOffset(_ contentOffset: CGPoint, animated: Bool)
  func selectItem(at indexPath: IndexPath?, animated: Bool, scrollPosition: UICollectionView.ScrollPosition)
}

extension UICollectionView: NECollectionView {}

enum Edge {
  case left, right, top, bottom
}

extension NECollectionView {
  func near(edge: Edge, clearance: CGFloat = 0) -> Bool {
    switch edge {
    case .left:
      return contentOffset.x + contentInset.left - clearance <= 0
    case .right:
      return (contentOffset.x + bounds.width + clearance) >= contentSize.width
    case .top:
      return contentOffset.y + contentInset.top - clearance <= 0
    case .bottom:
      return (contentOffset.y + bounds.height + clearance) >= contentSize.height
    }
  }
}
