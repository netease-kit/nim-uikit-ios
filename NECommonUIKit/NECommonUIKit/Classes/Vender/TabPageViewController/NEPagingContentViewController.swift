// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// this represents the display and behaviour of the cells.
public protocol NEPagingContentViewControllerDelegate: AnyObject {
  /// Tells the delegate when the user is abount to start scroll the content within the receiver.
  ///
  /// - Parameters:
  ///   - viewController: The view controller object that is about to scroll the content view.
  ///   - index: The left side content index where the view controller is about to scroll from.
  func contentViewController(viewController: NEPagingContentViewController, willBeginManualScrollOn index: Int)

  /// Tells the delegate when the user scrolls the content view within the receiver.
  ///
  /// - Parameters:
  ///   - viewController: The view controller object in which the scrolling occurred.
  ///   - index: The left side content index where view controller is showing now.
  ///   - percent: The rate that the view controller is showing the right side content.
  func contentViewController(viewController: NEPagingContentViewController, didManualScrollOn index: Int, percent: CGFloat)

  /// Tells the delegate when the user finished to scroll the content within the receiver.
  ///
  /// - Parameters:
  ///   - viewController: The view controller object in which the scrolling occurred.
  ///   - index: The left side index where the view controller is showing.
  func contentViewController(viewController: NEPagingContentViewController, didEndManualScrollOn index: Int)

  /// Tells the delegate when the view controller is trying to start paging the content.
  /// If it is the same page as the current, this delegate is not called.
  ///
  /// - Parameters:
  ///   - viewController: The view controller object in which the scrolling occurred.
  ///   - index: The index where the paging will begin.
  ///   - animated: true if the scrolling should be animated, false if it should be immediate.
  func contentViewController(viewController: NEPagingContentViewController, willBeginPagingAt index: Int, animated: Bool)

  /// Tells the delegate when the view controller is trying to finish paging the content.
  /// If it is the same page as the current, this delegate is not called.
  ///
  /// - Parameters:
  ///   - viewController: The view controller object in which the scrolling occurred.
  ///   - index: The index where the paging will stop.
  ///   - animated: true if the scrolling should be animated, false if it should be immediate.
  func contentViewController(viewController: NEPagingContentViewController, willFinishPagingAt index: Int, animated: Bool)

  /// Tells the delegate when the view controller was finished to paging the content.
  /// If it is the same page as the current, this delegate is not called.
  ///
  /// - Parameters:
  ///   - viewController: The view controller object in which the scrolling occurred.
  ///   - index: The index where the paging stopped.
  ///   - animated: true if the scrolling should be animated, false if it should be immediate.
  func contentViewController(viewController: NEPagingContentViewController, didFinishPagingAt index: Int, animated: Bool)
}

public extension NEPagingContentViewControllerDelegate {
  func contentViewController(viewController: NEPagingContentViewController, willBeginManualScrollOn index: Int) {}
  func contentViewController(viewController: NEPagingContentViewController, didManualScrollOn index: Int, percent: CGFloat) {}
  func contentViewController(viewController: NEPagingContentViewController, didEndManualScrollOn index: Int) {}

  func contentViewController(viewController: NEPagingContentViewController, willBeginPagingAt index: Int, animated: Bool) {}
  func contentViewController(viewController: NEPagingContentViewController, willFinishPagingAt index: Int, animated: Bool) {}
  func contentViewController(viewController: NEPagingContentViewController, didFinishPagingAt index: Int, animated: Bool) {}
}

/// The data source provides the paging content view controller object with the information it needs to construct and modify the contents.
public protocol NEPagingContentViewControllerDataSource: AnyObject {
  /// Tells the data source to return the number of item in a paging scrollview of the view controller.
  ///
  /// - Parameter viewController: The content view controller object requesting this information.
  /// - Returns: The number of item.
  func numberOfItemsForContentViewController(viewController: NEPagingContentViewController) -> Int

  /// Asks the data source for a cell to insert in a particular location of the scroll view of content view controller.
  ///
  /// - Parameters:
  ///   - viewController: A content view controller object requesting the cell.
  ///   - index: An index locating a items in content view controller.
  /// - Returns: An object inheriting from UIViewController that the content view controller can use for the specified item.
  func contentViewController(viewController: NEPagingContentViewController, viewControllerAt index: Int) -> UIViewController
}

/// A view controller that lets the user navigate between pages of content, where each page is managed by its own view controller object.
public class NEPagingContentViewController: UIViewController {
  fileprivate class ExplicitPaging {
    private var oneTimeHandler: (() -> Void)?
    private(set) var isPaging: Bool

    public init(oneTimeHandler: (() -> Void)?) {
      self.oneTimeHandler = oneTimeHandler
      isPaging = false
    }

    func start() {
      isPaging = true
    }

    func fireOnetimeHandlerIfNeeded() {
      oneTimeHandler?()
      oneTimeHandler = nil
    }

    func stop() {
      isPaging = false
    }
  }

  fileprivate var cachedViewControllers = [UIViewController?]()
  fileprivate var leftSidePageIndex = 0
  fileprivate var numberOfPages: Int = 0
  fileprivate var explicitPaging: ExplicitPaging?

  /// The ratio at which the origin of the left side content is offset from the origin of the page.
  private var leftSidePagingPercent: CGFloat {
    let rawPagingPercent = scrollView.contentOffset.x.truncatingRemainder(dividingBy: scrollView.bounds.width) / scrollView.bounds.width
    return rawPagingPercent
  }

  var appearanceHandler: NEContentsAppearanceHandlerProtocol = NEContentsAppearanceHandler()

  /// The object that acts as the delegate of the content view controller.
  public weak var delegate: NEPagingContentViewControllerDelegate?

  /// The object that provides view controllers.
  public weak var dataSource: NEPagingContentViewControllerDataSource?

  public var isEnabledPreloadContent = true

  /// The ratio at which the origin of the content view is offset from the origin of the scroll view.
  public var contentOffsetRatio: CGFloat {
    return scrollView.contentOffset.x / (scrollView.contentSize.width - scrollView.bounds.width)
  }

  /// The index at which the view controller is showing.
  public var currentPageIndex: Int {
    return calcCurrentPageIndex(from: leftSidePageIndex, pagingPercent: leftSidePagingPercent)
  }

  public var currentPagingPercent: CGFloat {
    return calcCurrentPagingPercent(leftSidePagingPercent)
  }

  /// previsous or next focusing index
  public var adjucentPageIndex: Int {
    let percent = calcCurrentPagingPercent(leftSidePagingPercent)
    return percent < 0 ? currentPageIndex - 1 : currentPageIndex + 1
  }

  ///  Reloads the content of the view controller.
  ///
  /// - Parameter page: An index to show after reloading.
  public func reloadData(with page: Int? = nil, completion: (() -> Void)? = nil) {
    removeAll()
    appearanceHandler.preReload(at: leftSidePageIndex)
    let preferredPage = page ?? leftSidePageIndex
    leftSidePageIndex = preferredPage
    initialLoad(with: preferredPage)
    UIView.pk.catchLayoutCompletion(
      layout: { [weak self] in
        self?.view.setNeedsLayout()
        self?.view.layoutIfNeeded()
      },
      completion: { [weak self] _ in
        self?.scroll(to: preferredPage, needsCallAppearance: false, animated: false) { _ in
          self?.appearanceHandler.postReload(at: preferredPage)
          completion?()
        }
      }
    )
  }

  /// Scrolls a specific page of the contents so that it is visible in the receiver.
  ///
  /// - Parameters:
  ///   - page: A index defining an content of the content view controller.
  ///   - animated: true if the scrolling should be animated, false if it should be immediate.
  public func scroll(to page: Int, animated: Bool, completion: ((Bool) -> Void)? = nil) {
    scroll(to: page, needsCallAppearance: true, animated: animated, completion: completion)
  }

  private func scroll(to page: Int, needsCallAppearance: Bool, animated: Bool, completion: ((Bool) -> Void)? = nil) {
    let isScrollingToAnotherPage = leftSidePageIndex != page

    if isScrollingToAnotherPage {
      delegate?.contentViewController(viewController: self, willBeginPagingAt: leftSidePageIndex, animated: animated)
    }

    if needsCallAppearance {
      appearanceHandler.beginDragging(at: leftSidePageIndex)
    }

    loadPagesIfNeeded(page: page)
    leftSidePageIndex = page

    if isScrollingToAnotherPage {
      delegate?.contentViewController(viewController: self, willFinishPagingAt: leftSidePageIndex, animated: animated)
    }

    move(to: page, animated: animated) { [weak self] finished in
      guard let _self = self, finished else { return }

      if needsCallAppearance {
        _self.appearanceHandler.stopScrolling(at: _self.leftSidePageIndex)
      }

      if isScrollingToAnotherPage {
        _self.delegate?.contentViewController(viewController: _self, didFinishPagingAt: _self.leftSidePageIndex, animated: animated)
      }

      completion?(finished)
    }
  }

  private func move(to page: Int, animated: Bool, completion: @escaping (Bool) -> Void) {
    let offsetX = scrollView.bounds.width * CGFloat(page)
    if animated {
      stopScrolling()
      UIView.pk.performSystemAnimation(
        { [weak self] in
          self?.scrollView.contentOffset = CGPoint(x: offsetX, y: 0)
        },
        completion: { finished in
          completion(finished)
        }
      )
    } else {
      UIView.pk.catchLayoutCompletion(
        layout: { [weak self] in
          self?.scrollView.contentOffset = CGPoint(x: offsetX, y: 0)
        },
        completion: { _ in
          completion(true)
        }
      )
    }
  }

  /// Return scrollView that the content view controller uses to show the contents.
  public let scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.isPagingEnabled = true
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.bounces = false
    scrollView.backgroundColor = .clear
    return scrollView
  }()

  public func preloadContentIfNeeded(with scrollingPercent: CGFloat) {
    guard isEnabledPreloadContent else { return }

    if scrollingPercent > 0.5 {
      loadPagesIfNeeded(page: leftSidePageIndex + 1)
    } else {
      loadPagesIfNeeded()
    }
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    scrollView.contentInsetAdjustmentBehavior = .never
    scrollView.frame = view.bounds
    scrollView.delegate = self
    view.addSubview(scrollView)
    view.addConstraints([.top, .bottom, .leading, .trailing].anchor(from: scrollView, to: view))
    view.backgroundColor = .clear

    appearanceHandler.contentsDequeueHandler = { [weak self] in
      self?.cachedViewControllers
    }
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    appearanceHandler.callApparance(.viewWillAppear, animated: animated, at: leftSidePageIndex)
  }

  override public func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    appearanceHandler.callApparance(.viewDidAppear, animated: animated, at: leftSidePageIndex)
  }

  override public func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    appearanceHandler.callApparance(.viewWillDisappear, animated: animated, at: leftSidePageIndex)
  }

  override public func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    appearanceHandler.callApparance(.viewDidDisappear, animated: animated, at: leftSidePageIndex)
  }

  override public func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    scrollView.contentSize = CGSize(
      width: scrollView.bounds.size.width * CGFloat(numberOfPages),
      height: scrollView.bounds.size.height
    )

    scrollView.contentOffset = CGPoint(x: scrollView.bounds.width * CGFloat(leftSidePageIndex), y: 0)

    for (offset, vc) in cachedViewControllers.enumerated() {
      vc?.view.frame = scrollView.bounds
      vc?.view.frame.origin.x = scrollView.bounds.width * CGFloat(offset)
    }
  }

  override public func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

  override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    coordinator.animate(alongsideTransition: { [weak self] context in
      guard let _self = self else { return }
      _self.scroll(to: _self.leftSidePageIndex, needsCallAppearance: false, animated: false)
    }, completion: nil)

    super.viewWillTransition(to: size, with: coordinator)
  }

  override public var shouldAutomaticallyForwardAppearanceMethods: Bool {
    return false
  }

  fileprivate func removeAll() {
    scrollView.subviews.forEach { $0.removeFromSuperview() }
    children.forEach { $0.removeFromParent() }
  }

  fileprivate func initialLoad(with page: Int) {
    numberOfPages = dataSource?.numberOfItemsForContentViewController(viewController: self) ?? 0
    cachedViewControllers = Array(repeating: nil, count: numberOfPages)

    loadScrollView(with: page - 1)
    loadScrollView(with: page)
    loadScrollView(with: page + 1)
  }

  fileprivate func loadScrollView(with page: Int) {
    guard (0 ..< cachedViewControllers.count) ~= page else { return }

    if case nil = cachedViewControllers[page], let dataSource = dataSource {
      let vc = dataSource.contentViewController(viewController: self, viewControllerAt: page)
      addChild(vc)
      vc.view.frame = scrollView.bounds
      vc.view.frame.origin.x = scrollView.bounds.width * CGFloat(page)
      scrollView.addSubview(vc.view)
      vc.willMove(toParent: self)
      cachedViewControllers[page] = vc
    }
  }

  fileprivate func loadPagesIfNeeded(page: Int? = nil) {
    let loadingPage = page ?? leftSidePageIndex
    loadScrollView(with: loadingPage - 1)
    loadScrollView(with: loadingPage)
    loadScrollView(with: loadingPage + 1)
  }

  fileprivate func stopScrolling() {
    explicitPaging = nil
    scrollView.layer.removeAllAnimations()
    scrollView.setContentOffset(scrollView.contentOffset, animated: false)
  }

  /// calculates current page defined in NEPagingKit
  ///
  /// - Parameters:
  ///   - leftSidePageIndex: page index showing on left side
  ///   - pagingPercent: paging percent from left side index
  /// - Returns: current focusing index
  private func calcCurrentPageIndex(from leftSidePageIndex: Int, pagingPercent: CGFloat) -> Int {
    let scrollToRightSide = (pagingPercent >= 0.5)
    let rightSidePageIndex = min(cachedViewControllers.endIndex, leftSidePageIndex + 1)
    return scrollToRightSide ? rightSidePageIndex : leftSidePageIndex
  }

  /// calculate paging percent defined by NEPagingKit from left side paging percent
  ///
  /// - Parameter leftSidePagingPercent: left side paging percent
  /// - Returns: paging parcent defined by NEPagingKit
  fileprivate func calcCurrentPagingPercent(_ leftSidePagingPercent: CGFloat) -> CGFloat {
    if leftSidePagingPercent >= 0.5 {
      return leftSidePagingPercent - 1
    } else {
      return leftSidePagingPercent
    }
  }
}

// MARK: - UIScrollViewDelegate

extension NEPagingContentViewController: UIScrollViewDelegate {
  public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    guard !(scrollView.isDragging && scrollView.isDecelerating) else {
      return
    }

    explicitPaging = ExplicitPaging(oneTimeHandler: { [weak self, leftSidePageIndex = leftSidePageIndex] in
      guard let _self = self else { return }
      _self.delegate?.contentViewController(viewController: _self, willBeginPagingAt: leftSidePageIndex, animated: false)
      _self.explicitPaging?.start()
      _self.appearanceHandler.beginDragging(at: leftSidePageIndex)
    })
    leftSidePageIndex = Int(scrollView.contentOffset.x / scrollView.bounds.width)
    delegate?.contentViewController(viewController: self, willBeginManualScrollOn: leftSidePageIndex)
  }

  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if let explicitPaging = explicitPaging {
      explicitPaging.fireOnetimeHandlerIfNeeded()
      leftSidePageIndex = Int(scrollView.contentOffset.x / scrollView.bounds.width)
      let normalizedPercent = calcCurrentPagingPercent(leftSidePagingPercent)
      let currentIndex = calcCurrentPageIndex(from: leftSidePageIndex, pagingPercent: leftSidePagingPercent)
      delegate?.contentViewController(viewController: self, didManualScrollOn: currentIndex, percent: normalizedPercent)
    }
  }

  public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
    if let explicitPaging = explicitPaging, explicitPaging.isPaging {
      delegate?.contentViewController(viewController: self, willFinishPagingAt: currentPageIndex, animated: true)
    }
  }

  public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    // When scrollview is bouncing, touching the scrollview calls scrollViewDidEndDecelerating(_:) immediately. So this line guards the end process.
    guard scrollView.bounds.origin.x >= 0, scrollView.bounds.maxX <= scrollView.contentSize.width else { return }

    if let explicitPaging = explicitPaging {
      leftSidePageIndex = Int(scrollView.contentOffset.x / scrollView.bounds.width)
      loadPagesIfNeeded()
      delegate?.contentViewController(viewController: self, didEndManualScrollOn: leftSidePageIndex)
      if explicitPaging.isPaging {
        appearanceHandler.stopScrolling(at: leftSidePageIndex)

        delegate?.contentViewController(viewController: self, didFinishPagingAt: leftSidePageIndex, animated: true)
      }
    }
    explicitPaging = nil
  }

  public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    guard !decelerate else { return }

    if let explicitPaging = explicitPaging {
      leftSidePageIndex = Int(scrollView.contentOffset.x / scrollView.bounds.width)
      loadPagesIfNeeded()
      delegate?.contentViewController(viewController: self, didEndManualScrollOn: leftSidePageIndex)
      if explicitPaging.isPaging {
        appearanceHandler.stopScrolling(at: leftSidePageIndex)

        delegate?.contentViewController(viewController: self, willFinishPagingAt: leftSidePageIndex, animated: false)
        delegate?.contentViewController(viewController: self, didFinishPagingAt: leftSidePageIndex, animated: false)
      }
    }
    explicitPaging = nil
  }
}
