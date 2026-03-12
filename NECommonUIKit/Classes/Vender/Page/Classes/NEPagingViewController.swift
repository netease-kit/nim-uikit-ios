// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NEPagingViewController:
  UIViewController,
  UICollectionViewDelegate,
  NEPageViewControllerDataSource,
  NEPageViewControllerDelegate {
  // MARK: Public Properties

  public var menuItemSize: NEPagingMenuItemSize {
    get { options.menuItemSize }
    set { options.menuItemSize = newValue }
  }

  public var menuItemSpacing: CGFloat {
    get { options.menuItemSpacing }
    set { options.menuItemSpacing = newValue }
  }

  public var menuItemLabelSpacing: CGFloat {
    get { options.menuItemLabelSpacing }
    set { options.menuItemLabelSpacing = newValue }
  }

  public var menuInsets: UIEdgeInsets {
    get { options.menuInsets }
    set { options.menuInsets = newValue }
  }

  public var menuHorizontalAlignment: NEPagingMenuHorizontalAlignment {
    get { options.menuHorizontalAlignment }
    set { options.menuHorizontalAlignment = newValue }
  }

  public var menuPosition: NEPagingMenuPosition {
    get { options.menuPosition }
    set { options.menuPosition = newValue }
  }

  public var menuTransition: NEPagingMenuTransition {
    get { options.menuTransition }
    set { options.menuTransition = newValue }
  }

  public var menuInteraction: PagingMenuInteraction {
    get { options.menuInteraction }
    set { options.menuInteraction = newValue }
  }

  public var menuLayoutClass: NEPagingCollectionViewLayout.Type {
    get { options.menuLayoutClass }
    set { options.menuLayoutClass = newValue }
  }

  public var selectedScrollPosition: NEPagingSelectedScrollPosition {
    get { options.selectedScrollPosition }
    set { options.selectedScrollPosition = newValue }
  }

  public var indicatorOptions: NEPagingIndicatorOptions {
    get { options.indicatorOptions }
    set { options.indicatorOptions = newValue }
  }

  public var indicatorClass: NEPagingIndicatorView.Type {
    get { options.indicatorClass }
    set { options.indicatorClass = newValue }
  }

  public var indicatorColor: UIColor {
    get { options.indicatorColor }
    set { options.indicatorColor = newValue }
  }

  public var borderOptions: NEPagingBorderOptions {
    get { options.borderOptions }
    set { options.borderOptions = newValue }
  }

  public var borderClass: NEPagingBorderView.Type {
    get { options.borderClass }
    set { options.borderClass = newValue }
  }

  public var borderColor: UIColor {
    get { options.borderColor }
    set { options.borderColor = newValue }
  }

  public var includeSafeAreaInsets: Bool {
    get { options.includeSafeAreaInsets }
    set { options.includeSafeAreaInsets = newValue }
  }

  public var font: UIFont {
    get { options.font }
    set { options.font = newValue }
  }

  public var selectedFont: UIFont {
    get { options.selectedFont }
    set { options.selectedFont = newValue }
  }

  public var textColor: UIColor {
    get { options.textColor }
    set { options.textColor = newValue }
  }

  public var selectedTextColor: UIColor {
    get { options.selectedTextColor }
    set { options.selectedTextColor = newValue }
  }

  public var backgroundColor: UIColor {
    get { options.backgroundColor }
    set { options.backgroundColor = newValue }
  }

  public var selectedBackgroundColor: UIColor {
    get { options.selectedBackgroundColor }
    set { options.selectedBackgroundColor = newValue }
  }

  public var menuBackgroundColor: UIColor {
    get { options.menuBackgroundColor }
    set { options.menuBackgroundColor = newValue }
  }

  public var contentNavigationOrientation: NEPagingNavigationOrientation {
    get { options.contentNavigationOrientation }
    set { options.contentNavigationOrientation = newValue }
  }

  public var contentInteraction: PagingContentInteraction {
    get { options.contentInteraction }
    set {
      options.contentInteraction = newValue
      configureContentInteraction()
    }
  }

  public var state: NEPagingState {
    pagingController.state
  }

  public var visibleItems: NEPagingItems {
    pagingController.visibleItems
  }

  public weak var dataSource: NEPagingViewControllerDataSource? {
    didSet {
      configureDataSource()
    }
  }

  public weak var infiniteDataSource: NEPagingViewControllerInfiniteDataSource?

  public weak var delegate: NEPagingViewControllerDelegate?

  public weak var sizeDelegate: NEPagingViewControllerSizeDelegate? {
    didSet {
      pagingController.sizeDelegate = self
    }
  }

  public private(set) var collectionViewLayout: NEPagingCollectionViewLayout

  public let collectionView: UICollectionView

  public let pageViewController: NEPageViewController

  public private(set) var options: NEPagingOptions {
    didSet {
      if options.menuLayoutClass != oldValue.menuLayoutClass {
        let layout = createLayout(layout: options.menuLayoutClass.self)
        collectionViewLayout = layout
        collectionViewLayout.options = options
        collectionView.setCollectionViewLayout(layout, animated: false)
      } else {
        collectionViewLayout.options = options
      }

      pageViewController.options = options
      pagingController.options = options
      pagingView.options = options
    }
  }

  // MARK: Private Properties

  private let pagingController: NEPagingController
  private var didLayoutSubviews: Bool = false

  private var pagingView: NEPagingView {
    view as! NEPagingView
  }

  private enum DataSourceReference {
    case `static`(NEPagingStaticDataSource)
    case finite(NEPagingFiniteDataSource)
    case none
  }

  /// Used to keep a strong reference to the internal data sources.
  private var dataSourceReference: DataSourceReference = .none

  // MARK: Initializers

  public init(options: NEPagingOptions = NEPagingOptions()) {
    self.options = options
    pagingController = NEPagingController(options: options)
    pageViewController = NEPageViewController(options: options)
    collectionViewLayout = createLayout(layout: options.menuLayoutClass.self)
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
    super.init(nibName: nil, bundle: nil)
    collectionView.delegate = self
    collectionViewLayout.options = options
    configurePagingController()

    // Register default cell
    register(NEPagingTitleCell.self, for: NEPagingIndexItem.self)
  }

  public convenience init(options: NEPagingOptions = NEPagingOptions(),
                          viewControllers: [UIViewController]) {
    self.init(options: options)
    configureDataSource(for: viewControllers)
  }

  public required init?(coder: NSCoder) {
    options = NEPagingOptions()
    pagingController = NEPagingController(options: options)
    pageViewController = NEPageViewController(options: options)
    collectionViewLayout = createLayout(layout: options.menuLayoutClass.self)
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
    super.init(coder: coder)
    collectionView.delegate = self
    configurePagingController()
    // Register default cell
    register(NEPagingTitleCell.self, for: NEPagingIndexItem.self)
  }

  // MARK: Public Methods

  open func reloadMenu() {
    var updatedItems: [NEPagingItem] = []

    switch dataSourceReference {
    case let .static(dataSource):
      dataSource.reloadItems()
      updatedItems = dataSource.items
    case let .finite(dataSource):
      dataSource.items = itemsForFiniteDataSource()
      updatedItems = dataSource.items
    default:
      break
    }

    if let previouslySelected = state.currentPagingItem,
       let pagingItem = updatedItems.first(where: { $0.isEqual(to: previouslySelected) }) {
      pagingController.reloadMenu(around: pagingItem)
    } else if let firstItem = updatedItems.first {
      pagingController.reloadMenu(around: firstItem)
    } else {
      pagingController.removeAll()
    }
  }

  open func reloadData() {
    var updatedItems: [NEPagingItem] = []

    switch dataSourceReference {
    case let .static(dataSource):
      dataSource.reloadItems()
      updatedItems = dataSource.items
    case let .finite(dataSource):
      dataSource.items = itemsForFiniteDataSource()
      updatedItems = dataSource.items
    default:
      break
    }

    if let previouslySelected = state.currentPagingItem,
       let pagingItem = updatedItems.first(where: { $0.isEqual(to: previouslySelected) }) {
      pagingController.reloadData(around: pagingItem)
    } else if let firstItem = updatedItems.first {
      pagingController.reloadData(around: firstItem)
    } else {
      pagingController.removeAll()
    }
  }

  open func reloadData(around pagingItem: NEPagingItem) {
    switch dataSourceReference {
    case let .static(dataSource):
      dataSource.reloadItems()
    case let .finite(dataSource):
      dataSource.items = itemsForFiniteDataSource()
    default:
      break
    }
    pagingController.reloadData(around: pagingItem)
  }

  open func select(pagingItem: NEPagingItem, animated: Bool = false) {
    pagingController.select(pagingItem: pagingItem, animated: animated)
  }

  open func select(index: Int, animated: Bool = false) {
    switch dataSourceReference {
    case let .static(dataSource):
      let pagingItem = dataSource.items[index]
      pagingController.select(pagingItem: pagingItem, animated: animated)
    case let .finite(dataSource):
      let pagingItem = dataSource.items[index]
      pagingController.select(pagingItem: pagingItem, animated: animated)
    case .none:
      fatalError("select(index:animated:): You need to set the dataSource property to use this method")
    }
  }

  override open func loadView() {
    view = NEPagingView(
      options: options,
      collectionView: collectionView,
      pageView: pageViewController.view
    )
  }

  override open func viewDidLoad() {
    super.viewDidLoad()

    addChild(pageViewController)
    pagingView.configure()
    pageViewController.willMove(toParent: self)

    pageViewController.delegate = self
    pageViewController.dataSource = self
    configureContentInteraction()
  }

  override open func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    if didLayoutSubviews == false {
      didLayoutSubviews = true
      pagingController.viewAppeared()
    }
  }

  override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { _ in
      self.pagingController.transitionSize()
    }, completion: nil)
  }

  /// UI 样式注册(通过类名)
  public func register(_ cellClass: AnyClass?, for pagingItemType: NEPagingItem.Type) {
    collectionView.register(cellClass, forCellWithReuseIdentifier: String(describing: pagingItemType))
  }

  /// UI 样式注册(通过xib注册)
  public func register(_ nib: UINib?, for pagingItemType: NEPagingItem.Type) {
    collectionView.register(nib, forCellWithReuseIdentifier: String(describing: pagingItemType))
  }

  // MARK: Private Methods

  /// 配置
  private func configurePagingController() {
    pagingController.collectionView = collectionView
    pagingController.collectionViewLayout = collectionViewLayout
    pagingController.dataSource = self
    pagingController.delegate = self
    pagingController.options = options
  }

  private func itemsForFiniteDataSource() -> [NEPagingItem] {
    let numberOfItems = dataSource?.numberOfViewControllers(in: self) ?? 0
    var items: [NEPagingItem] = []

    for index in 0 ..< numberOfItems {
      if let item = dataSource?.pagingViewController(self, pagingItemAt: index) {
        items.append(item)
      }
    }
    return items
  }

  private func configureDataSource() {
    let dataSource = NEPagingFiniteDataSource()
    dataSource.items = itemsForFiniteDataSource()
    dataSource.viewControllerForIndex = { [unowned self] in
      self.dataSource?.pagingViewController(self, viewControllerAt: $0)
    }

    dataSourceReference = .finite(dataSource)
    infiniteDataSource = dataSource

    if let firstItem = dataSource.items.first {
      pagingController.select(pagingItem: firstItem, animated: false)
    }
  }

  private func configureDataSource(for viewControllers: [UIViewController]) {
    let dataSource = NEPagingStaticDataSource(viewControllers: viewControllers)
    dataSourceReference = .static(dataSource)
    infiniteDataSource = dataSource
    if let pagingItem = dataSource.items.first {
      pagingController.select(pagingItem: pagingItem, animated: false)
    }
  }

  private func configureContentInteraction() {
    switch contentInteraction {
    case .scrolling:
      pageViewController.scrollView.isScrollEnabled = true
    case .none:
      pageViewController.scrollView.isScrollEnabled = false
    }
  }

  // MARK: UIScrollViewDelegate

  open func scrollViewDidScroll(_: UIScrollView) {
    pagingController.menuScrolled()
  }

  open func scrollViewWillBeginDragging(_: UIScrollView) {}

  open func scrollViewWillEndDragging(_: UIScrollView, withVelocity _: CGPoint, targetContentOffset _: UnsafeMutablePointer<CGPoint>) {}

  open func scrollViewDidEndDragging(_: UIScrollView, willDecelerate _: Bool) {}

  open func scrollViewDidEndScrollingAnimation(_: UIScrollView) {}

  open func scrollViewWillBeginDecelerating(_: UIScrollView) {}

  open func scrollViewDidEndDecelerating(_: UIScrollView) {}

  // MARK: UICollectionViewDelegate

  open func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let pagingItem = pagingController.visibleItems.pagingItem(for: indexPath)
    delegate?.pagingViewController(self, didSelectItem: pagingItem)
    pagingController.select(indexPath: indexPath, animated: true)
  }

  open func collectionView(_: UICollectionView, targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
    proposedContentOffset
  }

  open func collectionView(_: UICollectionView, didUnhighlightItemAt _: IndexPath) {}

  open func collectionView(_: UICollectionView, didHighlightItemAt _: IndexPath) {}

  open func collectionView(_: UICollectionView, didDeselectItemAt _: IndexPath) {}

  open func collectionView(_: UICollectionView, willDisplay _: UICollectionViewCell, forItemAt _: IndexPath) {}

  open func collectionView(_: UICollectionView, didEndDisplaying _: UICollectionViewCell, forItemAt _: IndexPath) {}

  // MARK: NEPageViewControllerDataSource

  open func pageViewController(_: NEPageViewController, viewControllerBeforeViewController _: UIViewController) -> UIViewController? {
    guard
      let dataSource = infiniteDataSource,
      let currentPagingItem = state.currentPagingItem,
      let pagingItem = dataSource.pagingViewController(self, itemBefore: currentPagingItem) else { return nil }

    return dataSource.pagingViewController(self, viewControllerFor: pagingItem)
  }

  open func pageViewController(_: NEPageViewController, viewControllerAfterViewController _: UIViewController) -> UIViewController? {
    guard
      let dataSource = infiniteDataSource,
      let currentPagingItem = state.currentPagingItem,
      let pagingItem = dataSource.pagingViewController(self, itemAfter: currentPagingItem) else { return nil }

    return dataSource.pagingViewController(self, viewControllerFor: pagingItem)
  }

  // MARK: NEPageViewControllerDelegate

  open func pageViewController(_: NEPageViewController, isScrollingFrom startingViewController: UIViewController, destinationViewController: UIViewController?, progress: CGFloat) {
    guard let currentPagingItem = state.currentPagingItem else { return }

    pagingController.contentScrolled(progress: progress)
    delegate?.pagingViewController(
      self,
      isScrollingFromItem: currentPagingItem,
      toItem: state.upcomingPagingItem,
      startingViewController: startingViewController,
      destinationViewController: destinationViewController,
      progress: progress
    )
  }

  open func pageViewController(_: NEPageViewController, willStartScrollingFrom startingViewController: UIViewController, destinationViewController: UIViewController) {
    if let upcomingPagingItem = state.upcomingPagingItem {
      delegate?.pagingViewController(
        self,
        willScrollToItem: upcomingPagingItem,
        startingViewController: startingViewController,
        destinationViewController: destinationViewController
      )
    }
  }

  open func pageViewController(_: NEPageViewController, didFinishScrollingFrom startingViewController: UIViewController, destinationViewController: UIViewController, transitionSuccessful: Bool) {
    if transitionSuccessful {
      pagingController.contentFinishedScrolling()
    }

    if let currentPagingItem = state.currentPagingItem {
      delegate?.pagingViewController(
        self,
        didScrollToItem: currentPagingItem,
        startingViewController: startingViewController,
        destinationViewController: destinationViewController,
        transitionSuccessful: transitionSuccessful
      )
    }
  }
}

extension NEPagingViewController: NEPagingMenuDataSource {
  public func pagingItemBefore(pagingItem: NEPagingItem) -> NEPagingItem? {
    infiniteDataSource?.pagingViewController(self, itemBefore: pagingItem)
  }

  public func pagingItemAfter(pagingItem: NEPagingItem) -> NEPagingItem? {
    infiniteDataSource?.pagingViewController(self, itemAfter: pagingItem)
  }
}

extension NEPagingViewController: PagingControllerSizeDelegate {
  func width(for pagingItem: NEPagingItem, isSelected: Bool) -> CGFloat {
    sizeDelegate?.pagingViewController(self, widthForPagingItem: pagingItem, isSelected: isSelected) ?? 0
  }
}

extension NEPagingViewController: NEPagingMenuDelegate {
  public func selectContent(pagingItem: NEPagingItem, direction: PagingDirection, animated: Bool) {
    guard let dataSource = infiniteDataSource else { return }

    switch direction {
    case .forward(true):
      pageViewController.selectNext(animated: animated)

    case .reverse(true):
      pageViewController.selectPrevious(animated: animated)

    default:
      let viewController = dataSource.pagingViewController(self, viewControllerFor: pagingItem)
      pageViewController.selectViewController(
        viewController,
        direction: NEPageViewDirection(from: direction),
        animated: animated
      )
    }
  }

  public func removeContent() {
    pageViewController.removeAll()
  }
}
