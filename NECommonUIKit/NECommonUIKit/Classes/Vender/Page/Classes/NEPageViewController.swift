// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NEPageViewController: UIViewController {
  public weak var dataSource: NEPageViewControllerDataSource?
  public weak var delegate: NEPageViewControllerDelegate?

  override public var shouldAutomaticallyForwardAppearanceMethods: Bool {
    false
  }

  /// 当前页面的左侧页面
  public var beforeViewController: UIViewController? {
    manager.previousViewController
  }

  /// 当前页面
  public var selectedViewController: UIViewController? {
    manager.selectedViewController
  }

  /// 当前页面的右侧页面
  private var afterViewController: UIViewController? {
    manager.nextViewController
  }

  /// 内容华东区域
  public private(set) lazy var scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.isPagingEnabled = true
    scrollView.autoresizingMask = [
      .flexibleTopMargin,
      .flexibleRightMargin,
      .flexibleBottomMargin,
      .flexibleLeftMargin,
    ]
    scrollView.scrollsToTop = false
    scrollView.bounces = true
    scrollView.translatesAutoresizingMaskIntoConstraints = true
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.showsVerticalScrollIndicator = false
    return scrollView
  }()

  /// UI配置项
  public var options: NEPagingOptions {
    didSet {
      switch options.contentNavigationOrientation {
      case .vertical:
        scrollView.alwaysBounceHorizontal = false
        scrollView.alwaysBounceVertical = true
      case .horizontal:
        scrollView.alwaysBounceHorizontal = true
        scrollView.alwaysBounceVertical = false
      }
    }
  }

  /// 翻页控制管理器
  private let manager = NEPageViewManager()

  /// 每页尺寸大小(多少宽度定义为一页，一般为屏幕宽度)
  private var pageSize: CGFloat {
    switch options.contentNavigationOrientation {
    case .vertical:
      return view.bounds.height
    case .horizontal:
      return view.bounds.width
    }
  }

  /// 内容尺寸
  private var contentSize: CGSize {
    switch options.contentNavigationOrientation {
    case .horizontal:
      return CGSize(
        width: CGFloat(manager.state.count) * view.bounds.width,
        height: view.bounds.height
      )
    case .vertical:
      return CGSize(
        width: view.bounds.width,
        height: CGFloat(manager.state.count) * view.bounds.height
      )
    }
  }

  /// 内容区域偏移
  private var contentOffset: CGFloat {
    get {
      switch options.contentNavigationOrientation {
      case .horizontal:
        return scrollView.contentOffset.x
      case .vertical:
        return scrollView.contentOffset.y
      }
    }
    set {
      scrollView.contentOffset = point(newValue)
    }
  }

  /// 是否从右到左
  private var isRightToLeft: Bool {
    switch options.contentNavigationOrientation {
    case .vertical:
      return false
    case .horizontal:
      if UIView.userInterfaceLayoutDirection(for: view.semanticContentAttribute) == .rightToLeft {
        return true
      } else {
        return false
      }
    }
  }

  /// 初始化方法
  /// - Parameter options: 滑块UI配置项
  public init(options: NEPagingOptions = NEPagingOptions()) {
    self.options = options
    super.init(nibName: nil, bundle: nil)
    manager.delegate = self
    manager.dataSource = self
  }

  public required init?(coder: NSCoder) {
    options = NEPagingOptions()
    super.init(coder: coder)
    manager.delegate = self
    manager.dataSource = self
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(scrollView)
    scrollView.delegate = self
    scrollView.contentInsetAdjustmentBehavior = .never
  }

  override public func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    scrollView.frame = view.bounds
    manager.viewWillLayoutSubviews()
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    manager.viewWillAppear(animated)
  }

  override public func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    manager.viewDidAppear(animated)
  }

  override public func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    manager.viewWillDisappear(animated)
  }

  override public func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    manager.viewDidDisappear(animated)
  }

  override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { _ in
      self.manager.viewWillTransitionSize()
    })
  }

  // MARK: Public Methods

  /// 跳转指定页面
  /// - Parameter viewController: 要跳转的页面
  /// - Parameter direction: 跳转方向
  /// - Parameter animated: 是否有动画
  public func selectViewController(_ viewController: UIViewController, direction: NEPageViewDirection, animated: Bool = true) {
    manager.select(viewController: viewController, direction: direction, animated: animated)
  }

  /// 滑动到下一个
  /// - Parameter animated: 是否有动画
  public func selectNext(animated: Bool) {
    manager.selectNext(animated: animated)
  }

  /// 滑动到钱一个页面
  /// - Parameter animated: 是否有动画
  public func selectPrevious(animated: Bool) {
    manager.selectPrevious(animated: animated)
  }

  /// 移除所有
  public func removeAll() {
    manager.removeAll()
  }

  // MARK: Private Methods

  /// 设置offset位置
  /// - Parameter value: 位置值
  /// - Parameter animated: 是否有动画
  private func setContentOffset(_ value: CGFloat, animated: Bool) {
    scrollView.setContentOffset(point(value), animated: animated)
  }

  private func point(_ value: CGFloat) -> CGPoint {
    switch options.contentNavigationOrientation {
    case .horizontal:
      return CGPoint(x: value, y: 0)
    case .vertical:
      return CGPoint(x: 0, y: value)
    }
  }
}

// MARK: - UIScrollViewDelegate

extension NEPageViewController: UIScrollViewDelegate {
  public func scrollViewWillBeginDragging(_: UIScrollView) {
    manager.willBeginDragging()
  }

  public func scrollViewWillEndDragging(_: UIScrollView, withVelocity _: CGPoint, targetContentOffset _: UnsafeMutablePointer<CGPoint>) {
    manager.willEndDragging()
  }

  public func scrollViewDidScroll(_: UIScrollView) {
    let distance = pageSize
    var progress: CGFloat

    if isRightToLeft {
      switch manager.state {
      case .last, .empty, .single:
        progress = -(contentOffset / distance)
      case .center, .first:
        progress = -((contentOffset - distance) / distance)
      }
    } else {
      switch manager.state {
      case .first, .empty, .single:
        progress = contentOffset / distance
      case .center, .last:
        progress = (contentOffset - distance) / distance
      }
    }

    manager.didScroll(progress: progress)
  }
}

// MARK: - NEPageViewManagerDataSource

extension NEPageViewController: NEPageViewManagerDataSource {
  func viewControllerAfter(_ viewController: UIViewController) -> UIViewController? {
    dataSource?.pageViewController(self, viewControllerAfterViewController: viewController)
  }

  func viewControllerBefore(_ viewController: UIViewController) -> UIViewController? {
    dataSource?.pageViewController(self, viewControllerBeforeViewController: viewController)
  }
}

// MARK: - NEPageViewManagerDelegate

extension NEPageViewController: NEPageViewManagerDelegate {
  func scrollForward() {
    if isRightToLeft {
      switch manager.state {
      case .first, .center:
        setContentOffset(.zero, animated: true)
      case .single, .empty, .last:
        break
      }
    } else {
      switch manager.state {
      case .first:
        setContentOffset(pageSize, animated: true)
      case .center:
        setContentOffset(pageSize * 2, animated: true)
      case .single, .empty, .last:
        break
      }
    }
  }

  func scrollReverse() {
    if isRightToLeft {
      switch manager.state {
      case .last:
        setContentOffset(pageSize, animated: true)
      case .center:
        setContentOffset(pageSize * 2, animated: true)
      case .single, .empty, .first:
        break
      }
    } else {
      switch manager.state {
      case .last, .center:
        scrollView.setContentOffset(.zero, animated: true)
      case .single, .empty, .first:
        break
      }
    }
  }

  func layoutViews(for viewControllers: [UIViewController], keepContentOffset: Bool) {
    let viewControllers = isRightToLeft ? viewControllers.reversed() : viewControllers

    // Need to trigger a layout here to ensure that the scroll view
    // bounds is updated before we use its frame for calculations.
    view.layoutIfNeeded()

    for (index, viewController) in viewControllers.enumerated() {
      switch options.contentNavigationOrientation {
      case .horizontal:
        viewController.view.frame = CGRect(
          x: CGFloat(index) * scrollView.bounds.width,
          y: 0,
          width: scrollView.bounds.width,
          height: scrollView.bounds.height
        )
      case .vertical:
        viewController.view.frame = CGRect(
          x: 0,
          y: CGFloat(index) * scrollView.bounds.height,
          width: scrollView.bounds.width,
          height: scrollView.bounds.height
        )
      }
    }

    var diff: CGFloat = 0
    if keepContentOffset {
      if contentOffset > pageSize * 2 {
        diff = contentOffset - pageSize * 2
      } else if contentOffset > pageSize, contentOffset < pageSize * 2 {
        diff = contentOffset - pageSize
      } else if contentOffset < pageSize, contentOffset < 0 {
        diff = contentOffset
      }
    }

    scrollView.contentSize = contentSize

    if isRightToLeft {
      switch manager.state {
      case .first, .center:
        contentOffset = pageSize + diff
      case .single, .empty, .last:
        contentOffset = diff
      }
    } else {
      switch manager.state {
      case .first, .single, .empty:
        contentOffset = diff
      case .last, .center:
        contentOffset = pageSize + diff
      }
    }
  }

  /// 添加页面到当前视图管理器
  /// - Parameter viewController: 视图控制器
  func addViewController(_ viewController: UIViewController) {
    viewController.willMove(toParent: self)
    addChild(viewController)
    scrollView.addSubview(viewController.view)
    viewController.didMove(toParent: self)
  }

  /// 把视图控制器从当前视图控制器移除
  func removeViewController(_ viewController: UIViewController) {
    viewController.willMove(toParent: nil)
    viewController.removeFromParent()
    viewController.view.removeFromSuperview()
    viewController.didMove(toParent: nil)
  }

  func beginAppearanceTransition(isAppearing: Bool, viewController: UIViewController, animated: Bool) {
    viewController.beginAppearanceTransition(isAppearing, animated: animated)
  }

  func endAppearanceTransition(viewController: UIViewController) {
    viewController.endAppearanceTransition()
  }

  /// 将要开始滑动到某个页面
  /// - Parameter selectedViewController: 当前页面
  /// - Parameter destinationViewController: 目标页面
  func willScroll(from selectedViewController: UIViewController,
                  to destinationViewController: UIViewController) {
    delegate?.pageViewController(
      self,
      willStartScrollingFrom: selectedViewController,
      destinationViewController: destinationViewController
    )
  }

  /// 滑动结束
  /// - Parameter selectedViewController: 当前页面
  /// - Parameter destinationViewController: 目标页面
  /// - Parameter transitionSuccessful: 是否成功
  func didFinishScrolling(from selectedViewController: UIViewController,
                          to destinationViewController: UIViewController,
                          transitionSuccessful: Bool) {
    delegate?.pageViewController(
      self,
      didFinishScrollingFrom: selectedViewController,
      destinationViewController: destinationViewController,
      transitionSuccessful: transitionSuccessful
    )
  }

  /// 正在滑动
  /// - Parameter selectedViewController: 当前页面
  /// - Parameter destinationViewController: 目标页面
  /// - Parameter progress: 滑动进度
  func isScrolling(from selectedViewController: UIViewController,
                   to destinationViewController: UIViewController?,
                   progress: CGFloat) {
    delegate?.pageViewController(
      self,
      isScrollingFrom: selectedViewController,
      destinationViewController: destinationViewController,
      progress: progress
    )
  }
}
