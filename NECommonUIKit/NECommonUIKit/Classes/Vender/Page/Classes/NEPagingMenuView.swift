// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

open class NEPagingMenuView: UIView {
  // MARK: Public Properties

  /// 切换按钮间距
  public var menuItemSpacing: CGFloat {
    get { options.menuItemSpacing }
    set { options.menuItemSpacing = newValue }
  }

  /// 切换按钮标签间距
  public var menuItemLabelSpacing: CGFloat {
    get { options.menuItemLabelSpacing }
    set { options.menuItemLabelSpacing = newValue }
  }

  /// 切换按钮大小
  public var menuItemSize: NEPagingMenuItemSize {
    get { options.menuItemSize }
    set { options.menuItemSize = newValue }
  }

  /// 切换按钮内边距
  public var menuInsets: UIEdgeInsets {
    get { options.menuInsets }
    set { options.menuInsets = newValue }
  }

  /// 对齐方式
  public var menuHorizontalAlignment: NEPagingMenuHorizontalAlignment {
    get { options.menuHorizontalAlignment }
    set { options.menuHorizontalAlignment = newValue }
  }

  public var menuTransition: NEPagingMenuTransition {
    get { options.menuTransition }
    set { options.menuTransition = newValue }
  }

  /// 动画过度样式
  public var menuInteraction: PagingMenuInteraction {
    get { options.menuInteraction }
    set { options.menuInteraction = newValue }
  }

  /// 滑动条自定义样式配置
  public var menuLayoutClass: NEPagingCollectionViewLayout.Type {
    get { options.menuLayoutClass }
    set { options.menuLayoutClass = newValue }
  }

  /// 选中后滚动方式
  public var selectedScrollPosition: NEPagingSelectedScrollPosition {
    get { options.selectedScrollPosition }
    set { options.selectedScrollPosition = newValue }
  }

  /// 滑条配置
  public var indicatorOptions: NEPagingIndicatorOptions {
    get { options.indicatorOptions }
    set { options.indicatorOptions = newValue }
  }

  /// 自定义滑条类，如果自定义可传入
  public var indicatorClass: NEPagingIndicatorView.Type {
    get { options.indicatorClass }
    set { options.indicatorClass = newValue }
  }

  /// 滑条颜色配置
  public var indicatorColor: UIColor {
    get { options.indicatorColor }
    set { options.indicatorColor = newValue }
  }

  /// 边框配置
  public var borderOptions: NEPagingBorderOptions {
    get { options.borderOptions }
    set { options.borderOptions = newValue }
  }

  /// 自定义边框
  public var borderClass: NEPagingBorderView.Type {
    get { options.borderClass }
    set { options.borderClass = newValue }
  }

  /// 边框颜色
  public var borderColor: UIColor {
    get { options.borderColor }
    set { options.borderColor = newValue }
  }

  /// 边框是否适配安全区域配置
  public var includeSafeAreaInsets: Bool {
    get { options.includeSafeAreaInsets }
    set { options.includeSafeAreaInsets = newValue }
  }

  /// 默认字号
  public var font: UIFont {
    get { options.font }
    set { options.font = newValue }
  }

  /// 选中字号
  public var selectedFont: UIFont {
    get { options.selectedFont }
    set { options.selectedFont = newValue }
  }

  /// 默认颜色
  public var textColor: UIColor {
    get { options.textColor }
    set { options.textColor = newValue }
  }

  /// 选中颜色
  public var selectedTextColor: UIColor {
    get { options.selectedTextColor }
    set { options.selectedTextColor = newValue }
  }

  /// 背景色
  override open var backgroundColor: UIColor? {
    didSet {
      if let backgroundColor = backgroundColor {
        options.backgroundColor = backgroundColor
      }
    }
  }

  /// 选中背景色
  public var selectedBackgroundColor: UIColor {
    get { options.selectedBackgroundColor }
    set { options.selectedBackgroundColor = newValue }
  }

  /// 单个按钮背景色.
  public var menuBackgroundColor: UIColor {
    get { options.menuBackgroundColor }
    set { options.menuBackgroundColor = newValue }
  }

  /// 操作协议
  public weak var delegate: NEPagingMenuDelegate? {
    didSet {
      pagingController.delegate = delegate
    }
  }

  /// 数据协议
  public weak var dataSource: NEPagingMenuDataSource? {
    didSet {
      pagingController.dataSource = dataSource
    }
  }

  /// 状态
  public var state: NEPagingState {
    pagingController.state
  }

  /// 可见的滑动指示器
  public var visibleItems: NEPagingItems {
    pagingController.visibleItems
  }

  public private(set) lazy var collectionViewLayout: NEPagingCollectionViewLayout = createLayout(layout: options.menuLayoutClass.self)

  public lazy var collectionView: UICollectionView = .init(frame: .zero, collectionViewLayout: collectionViewLayout)

  public private(set) var options = NEPagingOptions() {
    didSet {
      if options.menuLayoutClass != oldValue.menuLayoutClass {
        let layout = createLayout(layout: options.menuLayoutClass.self)
        collectionViewLayout = layout
        collectionViewLayout.options = options
        collectionView.setCollectionViewLayout(layout, animated: false)
      } else {
        collectionViewLayout.options = options
      }

      pagingController.options = options
    }
  }

  // MARK: Private Properties

  private lazy var pagingController = NEPagingController(options: options)

  // MARK: Initializers

  override public init(frame: CGRect) {
    super.init(frame: frame)
    configure()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    configure()
  }

  // TODO: Figure out how we can remove this method.
  open func viewAppeared() {
    pagingController.viewAppeared()
  }

  open func transitionSize() {
    pagingController.transitionSize()
  }

  open func contentScrolled(progress: CGFloat) {
    pagingController.contentScrolled(progress: progress)
  }

  open func contentFinishedScrolling() {
    pagingController.contentFinishedScrolling()
  }

  open func reload(around pagingItem: NEPagingItem) {
    pagingController.reloadMenu(around: pagingItem)
  }

  open func select(pagingItem: NEPagingItem, animated: Bool = false) {
    pagingController.select(pagingItem: pagingItem, animated: animated)
  }

  // MARK: Private Methods

  private func configure() {
    collectionView.backgroundColor = options.menuBackgroundColor
    collectionView.delegate = self
    addSubview(collectionView)
    constrainToEdges(collectionView)

    pagingController.collectionView = collectionView
    pagingController.collectionViewLayout = collectionViewLayout
  }
}

extension NEPagingMenuView: UICollectionViewDelegate {
  public func scrollViewDidScroll(_: UIScrollView) {
    pagingController.menuScrolled()
  }

  public func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    pagingController.select(indexPath: indexPath, animated: true)
  }
}
