// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

protocol PagingControllerSizeDelegate: AnyObject {
  func width(for: NEPagingItem, isSelected: Bool) -> CGFloat
}

final class NEPagingController: NSObject {
  weak var dataSource: NEPagingMenuDataSource?
  weak var sizeDelegate: PagingControllerSizeDelegate?
  weak var delegate: NEPagingMenuDelegate?

  weak var collectionView: NECollectionView! {
    didSet {
      configureCollectionView()
    }
  }

  weak var collectionViewLayout: CollectionViewLayout! {
    didSet {
      configureCollectionViewLayout()
    }
  }

  var options: NEPagingOptions {
    didSet {
      optionsChanged(oldValue: oldValue)
    }
  }

  private(set) var state: NEPagingState {
    didSet {
      collectionViewLayout.state = state
    }
  }

  private(set) var visibleItems: NEPagingItems {
    didSet {
      collectionViewLayout.visibleItems = visibleItems
    }
  }

  private(set) var sizeCache: NEPagingSizeCache {
    didSet {
      collectionViewLayout.sizeCache = sizeCache
    }
  }

  private var swipeGestureRecognizerLeft: UISwipeGestureRecognizer?
  private var swipeGestureRecognizerRight: UISwipeGestureRecognizer?

  public init(options: NEPagingOptions) {
    self.options = options
    sizeCache = NEPagingSizeCache(options: options)
    visibleItems = NEPagingItems(items: [])
    state = .empty
  }

  // MARK: Public

  /// 滑动到指定索引
  /// - Parameter index: 索引
  /// - Parameter animated: 是否动画
  func select(indexPath: IndexPath, animated: Bool) {
    let pagingItem = visibleItems.pagingItem(for: indexPath)
    select(pagingItem: pagingItem, animated: animated)
  }

  /// 滑动到指定 item
  /// - Parameter pagingItem : item
  /// - Parameter animated: 是否动画
  func select(pagingItem: NEPagingItem, animated: Bool) {
    if collectionView.superview == nil || collectionView.window == nil {
      state = .selected(pagingItem: pagingItem)
      return
    }

    switch state {
    case .empty:
      state = .selected(pagingItem: pagingItem)

      reloadItems(around: pagingItem)

      delegate?.selectContent(
        pagingItem: pagingItem,
        direction: .none,
        animated: false
      )

      collectionView.selectItem(
        at: visibleItems.indexPath(for: pagingItem),
        animated: false,
        scrollPosition: options.scrollPosition
      )

    case .selected:
      if let currentPagingItem = state.currentPagingItem {
        if pagingItem.isEqual(to: currentPagingItem) == false {
          if animated {
            appendItemsIfNeeded(upcomingPagingItem: pagingItem)

            let transition = calculateTransition(
              from: currentPagingItem,
              to: pagingItem
            )

            state = .scrolling(
              pagingItem: currentPagingItem,
              upcomingPagingItem: pagingItem,
              progress: 0,
              initialContentOffset: transition.contentOffset,
              distance: transition.distance
            )

            let direction = visibleItems.direction(
              from: currentPagingItem,
              to: pagingItem
            )

            delegate?.selectContent(
              pagingItem: pagingItem,
              direction: direction,
              animated: animated
            )
          } else {
            state = .selected(pagingItem: pagingItem)

            reloadItems(around: pagingItem)

            delegate?.selectContent(
              pagingItem: pagingItem,
              direction: .none,
              animated: false
            )

            collectionView.selectItem(
              at: visibleItems.indexPath(for: pagingItem),
              animated: false,
              scrollPosition: options.scrollPosition
            )
          }
        }
      }

    default:
      break
    }
  }

  /// 内容区域滑动进度
  /// - Parameter progress: 滑动进度
  func contentScrolled(progress: CGFloat) {
    switch state {
    case let .selected(pagingItem):
      var upcomingItem: NEPagingItem?

      if progress > 0 {
        upcomingItem = dataSource?.pagingItemAfter(pagingItem: pagingItem)
      } else if progress < 0 {
        upcomingItem = dataSource?.pagingItemBefore(pagingItem: pagingItem)
      } else {
        return
      }

      appendItemsIfNeeded(upcomingPagingItem: upcomingItem)
      let transition = calculateTransition(from: pagingItem, to: upcomingItem)
      updateScrollingState(
        pagingItem: pagingItem,
        upcomingPagingItem: upcomingItem,
        initialContentOffset: transition.contentOffset,
        distance: transition.distance,
        progress: progress
      )

    case let .scrolling(pagingItem, upcomingPagingItem, oldProgress, initialContentOffset, distance):
      if oldProgress < 0, progress > 0 {
        state = .selected(pagingItem: pagingItem)
      } else if oldProgress > 0, progress < 0 {
        state = .selected(pagingItem: pagingItem)
      } else if progress == 0 {
        state = .selected(pagingItem: pagingItem)
      } else {
        updateScrollingState(
          pagingItem: pagingItem,
          upcomingPagingItem: upcomingPagingItem,
          initialContentOffset: initialContentOffset,
          distance: distance,
          progress: progress
        )
      }

    default:
      break
    }
  }

  /// 内容区域滑动结束
  func contentFinishedScrolling() {
    guard case let .scrolling(pagingItem, upcomingPagingItem, _, _, _) = state else { return }

    if let upcomingPagingItem = upcomingPagingItem {
      state = .selected(pagingItem: upcomingPagingItem)

      if collectionView.isDragging == false {
        reloadItems(around: upcomingPagingItem)
        collectionView.selectItem(
          at: visibleItems.indexPath(for: upcomingPagingItem),
          animated: options.menuTransition == .animateAfter,
          scrollPosition: options.scrollPosition
        )
      }
    } else {
      state = .selected(pagingItem: pagingItem)
    }
  }

  func transitionSize() {
    switch state {
    case let .scrolling(pagingItem, _, _, _, _):
      sizeCache.clear()
      state = .selected(pagingItem: pagingItem)
      reloadItems(around: pagingItem)
      collectionView.selectItem(
        at: visibleItems.indexPath(for: pagingItem),
        animated: options.menuTransition == .animateAfter,
        scrollPosition: options.scrollPosition
      )

    default:
      if let pagingItem = state.currentPagingItem {
        sizeCache.clear()
        reloadItems(around: pagingItem)

        collectionView.selectItem(
          at: visibleItems.indexPath(for: pagingItem),
          animated: options.menuTransition == .animateAfter,
          scrollPosition: options.scrollPosition
        )
      }
    }
  }

  /// 重置
  func removeAll() {
    state = .empty
    sizeCache.clear()
    visibleItems = NEPagingItems(items: [])
    collectionView.reloadData()
    delegate?.removeContent()
  }

  /// 视图可见
  func viewAppeared() {
    switch state {
    case let .selected(pagingItem), let .scrolling(_, pagingItem?, _, _, _):
      state = .selected(pagingItem: pagingItem)
      reloadItems(around: pagingItem)

      delegate?.selectContent(
        pagingItem: pagingItem,
        direction: .none,
        animated: false
      )

      collectionView.selectItem(
        at: visibleItems.indexPath(for: pagingItem),
        animated: false,
        scrollPosition: options.scrollPosition
      )

    default:
      break
    }
  }

  /// 重新加载滑动只是器
  /// - Parameter pagingItem: 刷新的item
  func reloadData(around pagingItem: NEPagingItem) {
    reloadMenu(around: pagingItem)

    delegate?.removeContent()
    delegate?.selectContent(
      pagingItem: pagingItem,
      direction: .none,
      animated: false
    )

    state = .selected(pagingItem: pagingItem)
    collectionViewLayout.invalidateLayout()
  }

  func reloadMenu(around pagingItem: NEPagingItem) {
    sizeCache.clear()

    let toItems = generateItems(around: pagingItem)

    visibleItems = NEPagingItems(
      items: toItems,
      hasItemsBefore: hasItemBefore(pagingItem: toItems.first),
      hasItemsAfter: hasItemAfter(pagingItem: toItems.last)
    )

    state = .selected(pagingItem: pagingItem)
    collectionViewLayout.invalidateLayout()
    collectionView.reloadData()
    configureSizeCache(for: pagingItem)
  }

  /// 指示器滑动
  func menuScrolled() {
    if collectionView.indexPathsForVisibleItems.isEmpty == true {
      return
    }

    let contentInsets = collectionViewLayout.contentInsets

    if collectionView.near(edge: .left, clearance: contentInsets.left) {
      if let firstPagingItem = visibleItems.items.first {
        if visibleItems.hasItemsBefore {
          reloadItems(around: firstPagingItem)
        }
      }
    } else if collectionView.near(edge: .right, clearance: contentInsets.right) {
      if let lastPagingItem = visibleItems.items.last {
        if visibleItems.hasItemsAfter {
          reloadItems(around: lastPagingItem)
        }
      }
    }
  }

  // MARK: Private

  private func optionsChanged(oldValue: NEPagingOptions) {
    if options.menuInteraction != oldValue.menuInteraction {
      configureMenuInteraction()
    }

    sizeCache.options = options
    collectionViewLayout.invalidateLayout()
  }

  private func configureCollectionViewLayout() {
    collectionViewLayout.state = state
    collectionViewLayout.visibleItems = visibleItems
    collectionViewLayout.sizeCache = sizeCache
  }

  private func configureCollectionView() {
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.dataSource = self
    collectionView.contentInsetAdjustmentBehavior = .never

    configureMenuInteraction()
  }

  private func configureMenuInteraction() {
    if let swipeGestureRecognizerLeft = swipeGestureRecognizerLeft {
      collectionView.removeGestureRecognizer(swipeGestureRecognizerLeft)
    }

    if let swipeGestureRecognizerRight = swipeGestureRecognizerRight {
      collectionView.removeGestureRecognizer(swipeGestureRecognizerRight)
    }

    collectionView.isScrollEnabled = false
    collectionView.alwaysBounceHorizontal = false

    switch options.menuInteraction {
    case .scrolling:
      collectionView.isScrollEnabled = true
      collectionView.alwaysBounceHorizontal = true
    case .swipe:
      setupGestureRecognizers()
    case .none:
      break
    }
  }

  private func setupGestureRecognizers() {
    let swipeGestureRecognizerLeft = UISwipeGestureRecognizer(
      target: self,
      action: #selector(handleSwipeGestureRecognizer)
    )
    let swipeGestureRecognizerRight = UISwipeGestureRecognizer(
      target: self,
      action: #selector(handleSwipeGestureRecognizer)
    )

    swipeGestureRecognizerLeft.direction = .left
    swipeGestureRecognizerRight.direction = .right

    collectionView.addGestureRecognizer(swipeGestureRecognizerLeft)
    collectionView.addGestureRecognizer(swipeGestureRecognizerRight)

    self.swipeGestureRecognizerLeft = swipeGestureRecognizerLeft
    self.swipeGestureRecognizerRight = swipeGestureRecognizerRight
  }

  @objc private dynamic func handleSwipeGestureRecognizer(_ recognizer: UISwipeGestureRecognizer) {
    guard let currentPagingItem = state.currentPagingItem else { return }

    var upcomingPagingItem: NEPagingItem?

    if recognizer.direction.contains(.left) {
      upcomingPagingItem = dataSource?.pagingItemAfter(pagingItem: currentPagingItem)
    } else if recognizer.direction.contains(.right) {
      upcomingPagingItem = dataSource?.pagingItemBefore(pagingItem: currentPagingItem)
    }

    if let pagingItem = upcomingPagingItem {
      select(pagingItem: pagingItem, animated: true)
    }
  }

  private func updateScrollingState(pagingItem: NEPagingItem,
                                    upcomingPagingItem: NEPagingItem?,
                                    initialContentOffset: CGPoint,
                                    distance: CGFloat,
                                    progress: CGFloat) {
    state = .scrolling(
      pagingItem: pagingItem,
      upcomingPagingItem: upcomingPagingItem,
      progress: progress,
      initialContentOffset: initialContentOffset,
      distance: distance
    )

    if options.menuTransition == .scrollAlongside {
      let invalidationContext = NEPagingInvalidationContext()
      if upcomingPagingItem != nil {
        if collectionView.contentSize.width >= collectionView.bounds.width, state.progress != 0 {
          let contentOffset = CGPoint(
            x: initialContentOffset.x + (distance * abs(progress)),
            y: initialContentOffset.y
          )
          collectionView.setContentOffset(contentOffset, animated: false)
        }

        if sizeCache.implementsSizeDelegate {
          invalidationContext.invalidateSizes = true
        }
      }

      collectionViewLayout.invalidateLayout(with: invalidationContext)
    }
  }

  private func calculateTransition(from pagingItem: NEPagingItem,
                                   to upcomingPagingItem: NEPagingItem?) -> NEPagingTransition {
    guard let upcomingPagingItem = upcomingPagingItem else {
      return NEPagingTransition(contentOffset: .zero, distance: 0)
    }

    let distance = NEPagingDistance(
      view: collectionView,
      currentPagingItem: pagingItem,
      upcomingPagingItem: upcomingPagingItem,
      visibleItems: visibleItems,
      sizeCache: sizeCache,
      selectedScrollPosition: options.selectedScrollPosition,
      layoutAttributes: collectionViewLayout.layoutAttributes,
      navigationOrientation: options.contentNavigationOrientation
    )

    return NEPagingTransition(
      contentOffset: collectionView.contentOffset,
      distance: distance?.calculate() ?? 0
    )
  }

  private func appendItemsIfNeeded(upcomingPagingItem: NEPagingItem?) {
    if let upcomingPagingItem = upcomingPagingItem {
      if visibleItems.contains(upcomingPagingItem) == false {
        reloadItems(around: upcomingPagingItem, keepExisting: true)
      }
    }
  }

  private func reloadItems(around pagingItem: NEPagingItem, keepExisting: Bool = false) {
    var toItems = generateItems(around: pagingItem)

    if keepExisting {
      toItems = visibleItems.union(toItems)
    }

    let oldLayoutAttributes = collectionViewLayout.layoutAttributes
    let oldContentOffset = collectionView.contentOffset
    let oldVisibleItems = visibleItems

    configureSizeCache(for: pagingItem)

    visibleItems = NEPagingItems(
      items: toItems,
      hasItemsBefore: hasItemBefore(pagingItem: toItems.first),
      hasItemsAfter: hasItemAfter(pagingItem: toItems.last)
    )

    collectionView.reloadData()
    collectionViewLayout.prepare()

    let newLayoutAttributes = collectionViewLayout.layoutAttributes

    var offset: CGFloat = 0
    let diff = NEPagingDiff(from: oldVisibleItems, to: visibleItems)

    for indexPath in diff.removed() {
      offset += oldLayoutAttributes[indexPath]?.bounds.width ?? 0
      offset += options.menuItemSpacing
    }

    for indexPath in diff.added() {
      offset -= newLayoutAttributes[indexPath]?.bounds.width ?? 0
      offset -= options.menuItemSpacing
    }

    collectionView.contentOffset = CGPoint(
      x: oldContentOffset.x - offset,
      y: oldContentOffset.y
    )

    collectionView.layoutIfNeeded()

    if case let .scrolling(pagingItem, upcomingPagingItem, progress, _, distance) = state {
      let transition = calculateTransition(
        from: pagingItem,
        to: upcomingPagingItem
      )

      let contentOffset = collectionView.contentOffset
      let newContentOffset = CGPoint(
        x: contentOffset.x - (distance - transition.distance),
        y: contentOffset.y
      )

      state = .scrolling(
        pagingItem: pagingItem,
        upcomingPagingItem: upcomingPagingItem,
        progress: progress,
        initialContentOffset: newContentOffset,
        distance: distance
      )
    }
  }

  private func generateItems(around pagingItem: NEPagingItem) -> [NEPagingItem] {
    var items: [NEPagingItem] = [pagingItem]
    var previousItem: NEPagingItem = pagingItem
    var nextItem: NEPagingItem = pagingItem
    let menuWidth = collectionView.bounds.width

    var widthBefore: CGFloat = menuWidth
    while widthBefore > 0 {
      if let item = dataSource?.pagingItemBefore(pagingItem: previousItem) {
        widthBefore -= itemWidth(for: item)
        widthBefore -= options.menuItemSpacing
        previousItem = item
        items.insert(item, at: 0)
      } else {
        break
      }
    }

    var widthAfter: CGFloat = menuWidth + widthBefore
    while widthAfter > 0 {
      if let item = dataSource?.pagingItemAfter(pagingItem: nextItem) {
        widthAfter -= itemWidth(for: item)
        widthAfter -= options.menuItemSpacing
        nextItem = item
        items.append(item)
      } else {
        break
      }
    }

    var remainingWidth = widthAfter
    while remainingWidth > 0 {
      if let item = dataSource?.pagingItemBefore(pagingItem: previousItem) {
        remainingWidth -= itemWidth(for: item)
        remainingWidth -= options.menuItemSpacing
        previousItem = item
        items.insert(item, at: 0)
      } else {
        break
      }
    }

    return items
  }

  private func itemWidth(for pagingItem: NEPagingItem) -> CGFloat {
    guard let currentPagingItem = state.currentPagingItem else { return options.estimatedItemWidth }

    if currentPagingItem.isEqual(to: pagingItem) {
      return sizeCache.itemWidthSelected(for: pagingItem)
    } else {
      return sizeCache.itemSize(for: pagingItem)
    }
  }

  private func configureSizeCache(for _: NEPagingItem) {
    if sizeDelegate != nil {
      sizeCache.implementsSizeDelegate = true
      sizeCache.sizeForPagingItem = { [weak self] item, selected in
        self?.sizeDelegate?.width(for: item, isSelected: selected)
      }
    }
  }

  private func hasItemBefore(pagingItem: NEPagingItem?) -> Bool {
    guard let item = pagingItem else { return false }
    return dataSource?.pagingItemBefore(pagingItem: item) != nil
  }

  private func hasItemAfter(pagingItem: NEPagingItem?) -> Bool {
    guard let item = pagingItem else { return false }
    return dataSource?.pagingItemAfter(pagingItem: item) != nil
  }
}

extension NEPagingController: UICollectionViewDataSource {
  // MARK: UICollectionViewDataSource

  /// 滑动UI数据绑定
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let pagingItem = visibleItems.items[indexPath.item]
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: String(describing: type(of: pagingItem)),
      for: indexPath
    ) as! NEPagingCell
    var selected = false
    if let currentPagingItem = state.currentPagingItem {
      selected = currentPagingItem.isEqual(to: pagingItem)
    }
    cell.setPagingItem(pagingItem, selected: selected, options: options)
    return cell
  }

  func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
    visibleItems.items.count
  }
}
