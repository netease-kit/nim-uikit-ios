// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

open class NEPagingCollectionViewLayout: UICollectionViewLayout, NEPagingLayout {
  // MARK: Public Properties

  /// 配置参数
  public var options = NEPagingOptions() {
    didSet {
      optionsChanged(oldValue: oldValue)
    }
  }

  /// 当前状态
  public var state: NEPagingState = .empty

  /// 可见滑块
  public var visibleItems = NEPagingItems(items: [])

  /// 布局参数
  public private(set) var layoutAttributes: [IndexPath: NEPagingCellLayoutAttributes] = [:]

  /// 指示器布局参数设置
  public private(set) var indicatorLayoutAttributes: NEPagingIndicatorLayoutAttributes?

  /// 边框布局设置
  public private(set) var borderLayoutAttributes: NEPagingBorderLayoutAttributes?

  /// 状态标识
  public var invalidationState: NEInvalidationState = .everything

  /// 获取当前内容区域尺寸
  override open var collectionViewContentSize: CGSize {
    contentSize
  }

  /// 自定义UI
  override open class var layoutAttributesClass: AnyClass {
    NEPagingCellLayoutAttributes.self
  }

  /// 是否开启单向循环
  override open var flipsHorizontallyInOppositeLayoutDirection: Bool {
    true
  }

  // MARK: Initializers

  override public required init() {
    super.init()
    configure()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    configure()
  }

  // MARK: Internal Properties

  var sizeCache: NEPagingSizeCache?

  // MARK: Private Properties

  private var view: UICollectionView {
    collectionView!
  }

  private var range: Range<Int> {
    0 ..< view.numberOfItems(inSection: 0)
  }

  /// 自适应边距
  private var adjustedMenuInsets: UIEdgeInsets {
    UIEdgeInsets(
      top: options.menuInsets.top,
      left: options.menuInsets.left + safeAreaInsets.left,
      bottom: options.menuInsets.bottom,
      right: options.menuInsets.right + safeAreaInsets.right
    )
  }

  /// 安全内边距
  private var safeAreaInsets: UIEdgeInsets {
    if options.includeSafeAreaInsets {
      return view.safeAreaInsets
    } else {
      return .zero
    }
  }

  private var preferredSizeCache: [Int: CGFloat] = [:]

  private(set) var contentInsets: UIEdgeInsets = .zero
  private var contentSize: CGSize = .zero
  private let PagingIndicatorKind = "PagingIndicatorKind"
  private let PagingBorderKind = "PagingBorderKind"

  // MARK: Public Methods

  override open func prepare() {
    super.prepare()

    switch invalidationState {
    case .everything:
      layoutAttributes = [:]
      borderLayoutAttributes = nil
      indicatorLayoutAttributes = nil
      createLayoutAttributes()
      createDecorationLayoutAttributes()
    case .sizes:
      layoutAttributes = [:]
      createLayoutAttributes()
    case .nothing:
      break
    }

    updateBorderLayoutAttributes()
    updateIndicatorLayoutAttributes()

    invalidationState = .nothing
  }

  override open func invalidateLayout() {
    super.invalidateLayout()
    invalidationState = .everything
  }

  /// 导航布局
  override open func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
    super.invalidateLayout(with: context)
    invalidationState = invalidationState + NEInvalidationState(context)
  }

  /// 导航内容
  override open func invalidationContext(forPreferredLayoutAttributes _: UICollectionViewLayoutAttributes, withOriginalAttributes _: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutInvalidationContext {
    let context = NEPagingInvalidationContext()
    context.invalidateSizes = true
    return context
  }

  ///
  override open func shouldInvalidateLayout(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
    switch options.menuItemSize {
    case .selfSizing where originalAttributes is NEPagingCellLayoutAttributes:
      if preferredAttributes.frame.width != originalAttributes.frame.width {
        let pagingItem = visibleItems.pagingItem(for: originalAttributes.indexPath)
        preferredSizeCache[pagingItem.identifier] = preferredAttributes.frame.width
        return true
      }
      return false
    default:
      return false
    }
  }

  override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    guard let layoutAttributes = layoutAttributes[indexPath] else { return nil }
    layoutAttributes.progress = progressForItem(at: layoutAttributes.indexPath)
    return layoutAttributes
  }

  override open func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    switch elementKind {
    case PagingIndicatorKind:
      return indicatorLayoutAttributes
    case PagingBorderKind:
      return borderLayoutAttributes
    default:
      return super.layoutAttributesForDecorationView(ofKind: elementKind, at: indexPath)
    }
  }

  override open func layoutAttributesForElements(in _: CGRect) -> [UICollectionViewLayoutAttributes]? {
    var layoutAttributes: [UICollectionViewLayoutAttributes] = Array(layoutAttributes.values)

    for attributes in layoutAttributes {
      if let pagingAttributes = attributes as? NEPagingCellLayoutAttributes {
        pagingAttributes.progress = progressForItem(at: attributes.indexPath)
      }
    }

    let indicatorAttributes = layoutAttributesForDecorationView(
      ofKind: PagingIndicatorKind,
      at: IndexPath(item: 0, section: 0)
    )

    let borderAttributes = layoutAttributesForDecorationView(
      ofKind: PagingBorderKind,
      at: IndexPath(item: 1, section: 0)
    )

    if let indicatorAttributes = indicatorAttributes {
      layoutAttributes.append(indicatorAttributes)
    }

    if let borderAttributes = borderAttributes {
      layoutAttributes.append(borderAttributes)
    }

    return layoutAttributes
  }

  // MARK: Private Methods

  private func optionsChanged(oldValue: NEPagingOptions) {
    var shouldInvalidateLayout = false

    if options.borderClass != oldValue.borderClass {
      registerBorderClass()
      shouldInvalidateLayout = true
    }

    if options.indicatorClass != oldValue.indicatorClass {
      registerIndicatorClass()
      shouldInvalidateLayout = true
    }

    if options.borderColor != oldValue.borderColor {
      shouldInvalidateLayout = true
    }

    if options.indicatorColor != oldValue.indicatorColor {
      shouldInvalidateLayout = true
    }

    if shouldInvalidateLayout {
      invalidateLayout()
    }
  }

  private func configure() {
    registerBorderClass()
    registerIndicatorClass()
  }

  private func registerIndicatorClass() {
    register(options.indicatorClass, forDecorationViewOfKind: PagingIndicatorKind)
  }

  private func registerBorderClass() {
    register(options.borderClass, forDecorationViewOfKind: PagingBorderKind)
  }

  private func createLayoutAttributes() {
    guard let sizeCache = sizeCache else { return }

    var layoutAttributes: [IndexPath: NEPagingCellLayoutAttributes] = [:]
    var previousFrame: CGRect = .zero
    previousFrame.origin.x = adjustedMenuInsets.left - options.menuItemSpacing

    for index in 0 ..< view.numberOfItems(inSection: 0) {
      let indexPath = IndexPath(item: index, section: 0)
      let attributes = NEPagingCellLayoutAttributes(forCellWith: indexPath)
      let x = previousFrame.maxX + options.menuItemSpacing
      let y = adjustedMenuInsets.top
      let pagingItem = visibleItems.pagingItem(for: indexPath)

      if sizeCache.implementsSizeDelegate {
        var width = sizeCache.itemSize(for: pagingItem)
        let selectedWidth = sizeCache.itemWidthSelected(for: pagingItem)

        if let currentPagingItem = state.currentPagingItem, currentPagingItem.isEqual(to: pagingItem) {
          width = tween(from: selectedWidth, to: width, progress: abs(state.progress))
        } else if let upcomingPagingItem = state.upcomingPagingItem, upcomingPagingItem.isEqual(to: pagingItem) {
          width = tween(from: width, to: selectedWidth, progress: abs(state.progress))
        }

        attributes.frame = CGRect(x: x, y: y, width: width, height: options.menuItemSize.height)
      } else {
        switch options.menuItemSize {
        case let .fixed(width, height):
          attributes.frame = CGRect(x: x, y: y, width: width, height: height)
        case let .sizeToFit(minWidth, height):
          attributes.frame = CGRect(x: x, y: y, width: minWidth, height: height)
        case let .selfSizing(estimatedWidth, height):
          if let actualWidth = preferredSizeCache[pagingItem.identifier] {
            attributes.frame = CGRect(x: x, y: y, width: actualWidth, height: height)
          } else {
            attributes.frame = CGRect(x: x, y: y, width: estimatedWidth, height: height)
          }
        }
      }

      previousFrame = attributes.frame
      layoutAttributes[indexPath] = attributes
    }

    if previousFrame.maxX - adjustedMenuInsets.left < view.bounds.width {
      switch options.menuItemSize {
      case let .sizeToFit(_, height) where sizeCache.implementsSizeDelegate == false:
        let insets = adjustedMenuInsets.left + adjustedMenuInsets.right
        let spacing = (options.menuItemSpacing * CGFloat(range.upperBound - 1))
        let width = (view.bounds.width - insets - spacing) / CGFloat(range.upperBound)
        previousFrame = .zero
        previousFrame.origin.x = adjustedMenuInsets.left - options.menuItemSpacing

        for attributes in layoutAttributes.values.sorted(by: { $0.indexPath < $1.indexPath }) {
          let x = previousFrame.maxX + options.menuItemSpacing
          let y = adjustedMenuInsets.top
          attributes.frame = CGRect(x: x, y: y, width: width, height: height)
          previousFrame = attributes.frame
        }

      default:
        switch options.menuHorizontalAlignment {
        case .center:
          let offset = (view.bounds.width - previousFrame.maxX - adjustedMenuInsets.left) / 2
          for attributes in layoutAttributes.values {
            attributes.frame = attributes.frame.offsetBy(dx: offset, dy: 0)
          }

        case .right:
          let offset = (view.bounds.width - previousFrame.maxX - adjustedMenuInsets.right)
          for attributes in layoutAttributes.values {
            attributes.frame = attributes.frame.offsetBy(dx: offset, dy: 0)
          }

        default:
          break
        }
      }
    }

    if case .center = options.selectedScrollPosition {
      let attributes = layoutAttributes.values.sorted(by: { $0.indexPath < $1.indexPath })

      if let first = attributes.first, let last = attributes.last {
        let insetLeft = (view.bounds.width / 2) - (first.bounds.width / 2)
        let insetRight = (view.bounds.width / 2) - (last.bounds.width / 2)

        for attributes in layoutAttributes.values {
          attributes.frame = attributes.frame.offsetBy(dx: insetLeft, dy: 0)
        }

        contentInsets = UIEdgeInsets(
          top: 0,
          left: insetLeft + adjustedMenuInsets.left,
          bottom: 0,
          right: insetRight + adjustedMenuInsets.right
        )

        contentSize = CGSize(
          width: previousFrame.maxX + insetLeft + insetRight + adjustedMenuInsets.right,
          height: view.bounds.height
        )
      }

    } else {
      contentInsets = adjustedMenuInsets
      contentSize = CGSize(
        width: previousFrame.maxX + adjustedMenuInsets.right,
        height: view.bounds.height
      )
    }

    self.layoutAttributes = layoutAttributes
  }

  private func createDecorationLayoutAttributes() {
    if case .visible = options.indicatorOptions {
      indicatorLayoutAttributes = NEPagingIndicatorLayoutAttributes(
        forDecorationViewOfKind: PagingIndicatorKind,
        with: IndexPath(item: 0, section: 0)
      )
    }

    if case .visible = options.borderOptions {
      borderLayoutAttributes = NEPagingBorderLayoutAttributes(
        forDecorationViewOfKind: PagingBorderKind,
        with: IndexPath(item: 1, section: 0)
      )
    }
  }

  private func updateBorderLayoutAttributes() {
    borderLayoutAttributes?.configure(options)
    borderLayoutAttributes?.update(
      contentSize: collectionViewContentSize,
      bounds: collectionView?.bounds ?? .zero,
      safeAreaInsets: safeAreaInsets
    )
  }

  private func updateIndicatorLayoutAttributes() {
    guard let currentPagingItem = state.currentPagingItem else { return }
    indicatorLayoutAttributes?.configure(options)

    let currentIndexPath = visibleItems.indexPath(for: currentPagingItem)
    let upcomingIndexPath = upcomingIndexPathForIndexPath(currentIndexPath)

    if let upcomingIndexPath = upcomingIndexPath {
      let progress = abs(state.progress)
      let to = NEPagingIndicatorMetric(
        frame: indicatorFrameForIndex(upcomingIndexPath.item),
        insets: indicatorInsetsForIndex(upcomingIndexPath.item),
        spacing: indicatorSpacingForIndex(upcomingIndexPath.item)
      )

      if let currentIndexPath = currentIndexPath {
        let from = NEPagingIndicatorMetric(
          frame: indicatorFrameForIndex(currentIndexPath.item),
          insets: indicatorInsetsForIndex(currentIndexPath.item),
          spacing: indicatorSpacingForIndex(currentIndexPath.item)
        )

        indicatorLayoutAttributes?.update(from: from, to: to, progress: progress)
      } else if let from = indicatorMetricForFirstItem() {
        indicatorLayoutAttributes?.update(from: from, to: to, progress: progress)
      } else if let from = indicatorMetricForLastItem() {
        indicatorLayoutAttributes?.update(from: from, to: to, progress: progress)
      }
    } else if let metric = indicatorMetricForFirstItem() {
      indicatorLayoutAttributes?.update(to: metric)
    } else if let metric = indicatorMetricForLastItem() {
      indicatorLayoutAttributes?.update(to: metric)
    }
  }

  private func indicatorMetricForFirstItem() -> NEPagingIndicatorMetric? {
    guard let currentPagingItem = state.currentPagingItem else { return nil }
    if let first = visibleItems.items.first {
      if currentPagingItem.isBefore(item: first) {
        return NEPagingIndicatorMetric(
          frame: indicatorFrameForIndex(-1),
          insets: indicatorInsetsForIndex(-1),
          spacing: indicatorSpacingForIndex(-1)
        )
      }
    }
    return nil
  }

  private func indicatorMetricForLastItem() -> NEPagingIndicatorMetric? {
    guard let currentPagingItem = state.currentPagingItem else { return nil }
    if let last = visibleItems.items.last {
      if last.isBefore(item: currentPagingItem) {
        return NEPagingIndicatorMetric(
          frame: indicatorFrameForIndex(visibleItems.items.count),
          insets: indicatorInsetsForIndex(visibleItems.items.count),
          spacing: indicatorSpacingForIndex(visibleItems.items.count)
        )
      }
    }
    return nil
  }

  private func progressForItem(at indexPath: IndexPath) -> CGFloat {
    guard let currentPagingItem = state.currentPagingItem else { return 0 }

    let currentIndexPath = visibleItems.indexPath(for: currentPagingItem)

    if let currentIndexPath = currentIndexPath {
      if indexPath.item == currentIndexPath.item {
        return 1 - abs(state.progress)
      }
    }

    if let upcomingIndexPath = upcomingIndexPathForIndexPath(currentIndexPath) {
      if indexPath.item == upcomingIndexPath.item {
        return abs(state.progress)
      }
    }

    return 0
  }

  private func upcomingIndexPathForIndexPath(_ indexPath: IndexPath?) -> IndexPath? {
    if let upcomingPagingItem = state.upcomingPagingItem, let upcomingIndexPath = visibleItems.indexPath(for: upcomingPagingItem) {
      return upcomingIndexPath
    } else if let indexPath = indexPath {
      if indexPath.item == range.lowerBound {
        return IndexPath(item: indexPath.item - 1, section: 0)
      } else if indexPath.item == range.upperBound - 1 {
        return IndexPath(item: indexPath.item + 1, section: 0)
      }
    }
    return indexPath
  }

  private func indicatorSpacingForIndex(_: Int) -> UIEdgeInsets {
    if case let .visible(_, _, insets, _) = options.indicatorOptions {
      return insets
    }
    return UIEdgeInsets.zero
  }

  private func indicatorInsetsForIndex(_ index: Int) -> NEPagingIndicatorMetric.Inset {
    if case let .visible(_, _, _, insets) = options.indicatorOptions {
      if index == 0, range.upperBound == 1 {
        return .both(insets.left, insets.right)
      } else if index == range.lowerBound {
        return .left(insets.left)
      } else if index >= range.upperBound - 1 {
        return .right(insets.right)
      }
    }
    return .none
  }

  private func indicatorFrameForIndex(_ index: Int) -> CGRect {
    if index < range.lowerBound {
      let frame = frameForIndex(0)
      return frame.offsetBy(dx: -frame.width, dy: 0)
    } else if index > range.upperBound - 1 {
      let frame = frameForIndex(visibleItems.items.count - 1)
      return frame.offsetBy(dx: frame.width, dy: 0)
    }

    return frameForIndex(index)
  }

  private func frameForIndex(_ index: Int) -> CGRect {
    guard
      let sizeCache = sizeCache,
      let attributes = layoutAttributes[IndexPath(item: index, section: 0)] else { return .zero }

    var frame = CGRect(
      x: attributes.center.x - attributes.bounds.midX,
      y: attributes.center.y - attributes.bounds.midY,
      width: attributes.bounds.width,
      height: attributes.bounds.height
    )
    if sizeCache.implementsSizeDelegate {
      let indexPath = IndexPath(item: index, section: 0)
      let pagingItem = visibleItems.pagingItem(for: indexPath)

      if let upcomingPagingItem = state.upcomingPagingItem, let currentPagingItem = state.currentPagingItem {
        if upcomingPagingItem.isEqual(to: pagingItem) || currentPagingItem.isEqual(to: pagingItem) {
          frame.size.width = sizeCache.itemWidthSelected(for: pagingItem)
        }
      }
    }

    return frame
  }
}
