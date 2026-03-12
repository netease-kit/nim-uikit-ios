// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

public struct NEPagingOptions {
  /// 切换按钮大小
  public var menuItemSize: NEPagingMenuItemSize

  /// 切换按钮间距
  public var menuItemSpacing: CGFloat

  /// 切换按钮标签间距
  public var menuItemLabelSpacing: CGFloat

  /// 切换按钮内边距
  public var menuInsets: UIEdgeInsets

  /// 对齐方式
  public var menuHorizontalAlignment: NEPagingMenuHorizontalAlignment

  /// 位置: 顶部或者底部
  public var menuPosition: NEPagingMenuPosition

  /// 动画过度样式
  public var menuTransition: NEPagingMenuTransition

  /// 滑动条自定义样式配置
  public var menuInteraction: PagingMenuInteraction

  /// 滑动内容区域交互方式
  public var contentInteraction: PagingContentInteraction

  /// 顶部滑动按钮布局控制
  public var menuLayoutClass: NEPagingCollectionViewLayout.Type

  /// 选中后滚动方式
  public var selectedScrollPosition: NEPagingSelectedScrollPosition

  /// 滑条配置
  public var indicatorOptions: NEPagingIndicatorOptions

  /// 自定义滑条类，如果自定义可传入
  public var indicatorClass: NEPagingIndicatorView.Type

  /// 滑条颜色配置
  public var indicatorColor: UIColor

  /// 边框配置
  public var borderOptions: NEPagingBorderOptions

  /// 自定义边框
  public var borderClass: NEPagingBorderView.Type

  /// 边框颜色
  public var borderColor: UIColor

  /// 边框是否适配安全区域配置
  public var includeSafeAreaInsets: Bool

  /// 默认字号
  public var font: UIFont

  /// 选中字号
  public var selectedFont: UIFont

  /// 默认颜色
  public var textColor: UIColor

  /// 选中颜色
  public var selectedTextColor: UIColor

  /// 背景色
  public var backgroundColor: UIColor

  /// 选中背景色
  public var selectedBackgroundColor: UIColor

  /// 单个按钮背景色.
  public var menuBackgroundColor: UIColor

  /// 内容区域背景色
  public var pagingContentBackgroundColor: UIColor

  /// 内容区域滑动方向
  public var contentNavigationOrientation: NEPagingNavigationOrientation

  public var scrollPosition: UICollectionView.ScrollPosition {
    switch selectedScrollPosition {
    case .left:
      return UICollectionView.ScrollPosition.left
    case .right:
      return UICollectionView.ScrollPosition.right
    case .preferCentered, .center:
      return UICollectionView.ScrollPosition.centeredHorizontally
    }
  }

  public var menuHeight: CGFloat {
    menuItemSize.height + menuInsets.top + menuInsets.bottom
  }

  public var estimatedItemWidth: CGFloat {
    switch menuItemSize {
    case let .fixed(width, _):
      return width
    case let .sizeToFit(minWidth, _):
      return minWidth
    case let .selfSizing(estimatedItemWidth, _):
      return estimatedItemWidth
    }
  }

  public init() {
    selectedScrollPosition = .preferCentered
    menuItemSize = .sizeToFit(minWidth: 150, height: 40)
    menuPosition = .top
    menuTransition = .scrollAlongside
    menuInteraction = .scrolling
    menuInsets = UIEdgeInsets.zero
    menuItemSpacing = 0
    menuItemLabelSpacing = 20
    menuHorizontalAlignment = .left
    includeSafeAreaInsets = true
    indicatorClass = NEPagingIndicatorView.self
    borderClass = NEPagingBorderView.self
    menuLayoutClass = NEPagingCollectionViewLayout.self

    indicatorOptions = .visible(
      height: 4,
      zIndex: Int.max,
      spacing: UIEdgeInsets.zero,
      insets: UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    )

    borderOptions = .visible(
      height: 1,
      zIndex: Int.max - 1,
      insets: UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    )

    font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.medium)
    selectedFont = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.medium)

    textColor = UIColor.black
    selectedTextColor = UIColor(red: 3 / 255, green: 125 / 255, blue: 233 / 255, alpha: 1)
    backgroundColor = .clear
    selectedBackgroundColor = .clear
    pagingContentBackgroundColor = .white
    menuBackgroundColor = UIColor.white
    borderColor = UIColor(white: 0.9, alpha: 1)
    indicatorColor = UIColor(red: 3 / 255, green: 125 / 255, blue: 233 / 255, alpha: 1)
    contentNavigationOrientation = .horizontal
    contentInteraction = .scrolling
  }
}
