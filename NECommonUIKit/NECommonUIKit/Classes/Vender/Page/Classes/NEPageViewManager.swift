// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

final class NEPageViewManager {
  /// 数据源代理
  weak var dataSource: NEPageViewManagerDataSource?
  /// 操作回调代理
  weak var delegate: NEPageViewManagerDelegate?

  private(set) weak var previousViewController: UIViewController?
  private(set) weak var selectedViewController: UIViewController?
  private(set) weak var nextViewController: UIViewController?

  /// 根据页面情况判断当前状态
  var state: NEPageViewState {
    if previousViewController == nil, nextViewController == nil, selectedViewController == nil {
      return .empty
    } else if previousViewController == nil, nextViewController == nil {
      return .single
    } else if nextViewController == nil {
      return .last
    } else if previousViewController == nil {
      return .first
    } else {
      return .center
    }
  }

  private enum NEAppearanceState {
    case appearing(animated: Bool)
    case disappearing(animated: Bool)
    case disappeared
    case appeared
  }

  private var appearanceState: NEAppearanceState = .disappeared
  private var didReload: Bool = false
  private var didSelect: Bool = false
  private var initialDirection: NEPageViewDirection = .none

  /// 跳转指定页面
  /// - Parameter viewController: 待跳转页面
  /// - Parameter direction: 跳转方向
  /// - Parameter animated: 是否动画
  func select(viewController: UIViewController,
              direction: NEPageViewDirection = .none,
              animated: Bool = false) {
    if state == .empty || animated == false {
      selectViewController(viewController, animated: animated)
      return
    } else {
      resetState()
      didSelect = true

      switch direction {
      case .forward, .none:
        if let nextViewController = nextViewController {
          delegate?.removeViewController(nextViewController)
        }
        delegate?.addViewController(viewController)
        nextViewController = viewController
        layoutsViews()
        delegate?.scrollForward()
      case .reverse:
        if let previousViewController = previousViewController {
          delegate?.removeViewController(previousViewController)
        }
        delegate?.addViewController(viewController)
        previousViewController = viewController
        layoutsViews()
        delegate?.scrollReverse()
      }
    }
  }

  /// 选中后一个页面
  /// - Parameter animated: 是否动画
  func selectNext(animated: Bool) {
    if animated {
      resetState()
      delegate?.scrollForward()
    } else if let nextViewController = nextViewController,
              let selectedViewController = selectedViewController {
      beginAppearanceTransition(false, for: selectedViewController, animated: animated)
      beginAppearanceTransition(true, for: nextViewController, animated: animated)

      let newNextViewController = dataSource?.viewControllerAfter(nextViewController)

      if let previousViewController = previousViewController {
        delegate?.removeViewController(previousViewController)
      }

      if let newNextViewController = newNextViewController {
        delegate?.addViewController(newNextViewController)
      }

      previousViewController = selectedViewController
      self.selectedViewController = nextViewController
      self.nextViewController = newNextViewController

      layoutsViews()

      endAppearanceTransition(for: selectedViewController)
      endAppearanceTransition(for: nextViewController)
    }
  }

  /// 选中前置页面
  /// - Parameter animated: 是否动画
  func selectPrevious(animated: Bool) {
    if animated {
      resetState()
      delegate?.scrollReverse()
    } else if let previousViewController = previousViewController,
              let selectedViewController = selectedViewController {
      beginAppearanceTransition(false, for: selectedViewController, animated: animated)
      beginAppearanceTransition(true, for: previousViewController, animated: animated)

      let newPreviousViewController = dataSource?.viewControllerBefore(previousViewController)

      if let nextViewController = nextViewController {
        delegate?.removeViewController(nextViewController)
      }

      if let newPreviousViewController = newPreviousViewController {
        delegate?.addViewController(newPreviousViewController)
      }

      self.previousViewController = newPreviousViewController
      self.selectedViewController = previousViewController
      nextViewController = selectedViewController

      layoutsViews()

      endAppearanceTransition(for: selectedViewController)
      endAppearanceTransition(for: previousViewController)
    }
  }

  /// 移除所有布局
  func removeAll() {
    let oldSelectedViewController = selectedViewController

    if let selectedViewController = oldSelectedViewController {
      beginAppearanceTransition(false, for: selectedViewController, animated: false)
      delegate?.removeViewController(selectedViewController)
    }
    if let previousViewController = previousViewController {
      delegate?.removeViewController(previousViewController)
    }
    if let nextViewController = nextViewController {
      delegate?.removeViewController(nextViewController)
    }
    previousViewController = nil
    selectedViewController = nil
    nextViewController = nil
    layoutsViews()

    if let oldSelectedViewController = oldSelectedViewController {
      endAppearanceTransition(for: oldSelectedViewController)
    }
  }

  /// 将要布局子视图
  func viewWillLayoutSubviews() {
    layoutsViews()
  }

  /// 视图将要显示在屏幕
  func viewWillAppear(_ animated: Bool) {
    appearanceState = .appearing(animated: animated)
    if let selectedViewController = selectedViewController {
      delegate?.beginAppearanceTransition(
        isAppearing: true,
        viewController: selectedViewController,
        animated: animated
      )
    }

    switch state {
    case .center, .first, .last, .single:
      layoutsViews()
    case .empty:
      break
    }
  }

  /// 视图已经显示
  func viewDidAppear(_: Bool) {
    appearanceState = .appeared
    if let selectedViewController = selectedViewController {
      delegate?.endAppearanceTransition(viewController: selectedViewController)
    }
  }

  /// 视图将要消失
  func viewWillDisappear(_ animated: Bool) {
    appearanceState = .disappearing(animated: animated)
    if let selectedViewController = selectedViewController {
      delegate?.beginAppearanceTransition(
        isAppearing: false,
        viewController: selectedViewController,
        animated: animated
      )
    }
  }

  /// 视图已经消失
  func viewDidDisappear(_: Bool) {
    appearanceState = .disappeared
    if let selectedViewController = selectedViewController {
      delegate?.endAppearanceTransition(viewController: selectedViewController)
    }
  }

  /// 开始拖转
  func willBeginDragging() {
    resetState()
  }

  /// 停止拖转
  func willEndDragging() {
    resetState()
  }

  func viewWillTransitionSize() {
    layoutsViews(keepContentOffset: false)
  }

  /// 开始滑动
  /// - Parameter progress: 滑动进度
  func didScroll(progress: CGFloat) {
    let currentDirection = NEPageViewDirection(progress: progress)

    // MARK: Begin scrolling

    if initialDirection == .none {
      switch currentDirection {
      case .forward:
        initialDirection = .forward
        onScroll(progress: progress)
        willScrollForward()
      case .reverse:
        initialDirection = .reverse
        onScroll(progress: progress)
        willScrollReverse()
      case .none:
        onScroll(progress: progress)
      }
    } else {
      if didReload == false {
        switch (currentDirection, initialDirection) {
        case (.reverse, .forward):
          initialDirection = .reverse
          cancelScrollForward()
          onScroll(progress: progress)
          willScrollReverse()
        case (.forward, .reverse):
          initialDirection = .forward
          cancelScrollReverse()
          onScroll(progress: progress)
          willScrollForward()
        default:
          onScroll(progress: progress)
        }
      } else {
        onScroll(progress: progress)
      }
    }

    if didReload == false {
      if progress >= 1 {
        didReload = true
        didScrollForward()
      } else if progress <= -1 {
        didReload = true
        didScrollReverse()
      } else if progress == 0 {
        switch initialDirection {
        case .forward:
          didReload = true
          cancelScrollForward()
        case .reverse:
          didReload = true
          cancelScrollReverse()
        case .none:
          break
        }
      }
    }
  }

  private func selectViewController(_ viewController: UIViewController, animated: Bool) {
    let oldSelectedViewController = selectedViewController
    let newPreviousViewController = dataSource?.viewControllerBefore(viewController)
    let newNextViewController = dataSource?.viewControllerAfter(viewController)

    if let oldSelectedViewController = oldSelectedViewController {
      beginAppearanceTransition(false, for: oldSelectedViewController, animated: animated)
    }

    if viewController !== selectedViewController {
      beginAppearanceTransition(true, for: viewController, animated: animated)
    }

    if let oldPreviosViewController = previousViewController {
      if oldPreviosViewController !== viewController,
         oldPreviosViewController !== newPreviousViewController,
         oldPreviosViewController !== newNextViewController {
        delegate?.removeViewController(oldPreviosViewController)
      }
    }

    if let oldSelectedViewController = selectedViewController {
      if oldSelectedViewController !== newPreviousViewController,
         oldSelectedViewController !== newNextViewController {
        delegate?.removeViewController(oldSelectedViewController)
      }
    }

    if let oldNextViewController = nextViewController {
      if oldNextViewController !== viewController,
         oldNextViewController !== newPreviousViewController,
         oldNextViewController !== newNextViewController {
        delegate?.removeViewController(oldNextViewController)
      }
    }

    if let newPreviousViewController = newPreviousViewController {
      if newPreviousViewController !== selectedViewController,
         newPreviousViewController !== previousViewController,
         newPreviousViewController !== nextViewController {
        delegate?.addViewController(newPreviousViewController)
      }
    }

    if viewController !== nextViewController,
       viewController !== previousViewController {
      delegate?.addViewController(viewController)
    }

    if let newNextViewController = newNextViewController {
      if newNextViewController !== selectedViewController,
         newNextViewController !== previousViewController,
         newNextViewController !== nextViewController {
        delegate?.addViewController(newNextViewController)
      }
    }

    previousViewController = newPreviousViewController
    selectedViewController = viewController
    nextViewController = newNextViewController

    layoutsViews()

    if let oldSelectedViewController = oldSelectedViewController {
      endAppearanceTransition(for: oldSelectedViewController)
    }

    if viewController !== oldSelectedViewController {
      endAppearanceTransition(for: viewController)
    }
  }

  /// 重置状态为空闲状态
  private func resetState() {
    if didReload {
      initialDirection = .none
    }
    didReload = false
  }

  /// 滑动进度回调
  /// - Parameter progress: 滑动进度
  private func onScroll(progress: CGFloat) {
    // This means we are overshooting, so we need to continue
    // reporting the old view controllers.
    if didReload {
      switch initialDirection {
      case .forward:
        if let previousViewController = previousViewController,
           let selectedViewController = selectedViewController {
          delegate?.isScrolling(
            from: previousViewController,
            to: selectedViewController,
            progress: progress
          )
        }
      case .reverse:
        if let nextViewController = nextViewController,
           let selectedViewController = selectedViewController {
          delegate?.isScrolling(
            from: nextViewController,
            to: selectedViewController,
            progress: progress
          )
        }
      case .none:
        break
      }
    } else {
      // Report progress as normally
      switch initialDirection {
      case .forward:
        if let selectedViewController = selectedViewController {
          delegate?.isScrolling(
            from: selectedViewController,
            to: nextViewController,
            progress: progress
          )
        }
      case .reverse:
        if let selectedViewController = selectedViewController {
          delegate?.isScrolling(
            from: selectedViewController,
            to: previousViewController,
            progress: progress
          )
        }
      case .none:
        break
      }
    }
  }

  /// 取消向前滑动，处理未滑动到指定宽度，恢复之前的UI效果
  private func cancelScrollForward() {
    guard let selectedViewController = selectedViewController else { return }
    let oldNextViewController = nextViewController

    if let nextViewController = oldNextViewController {
      beginAppearanceTransition(true, for: selectedViewController, animated: true)
      beginAppearanceTransition(false, for: nextViewController, animated: true)
    }

    if didSelect {
      let newNextViewController = dataSource?.viewControllerAfter(selectedViewController)
      if let oldNextViewController = oldNextViewController {
        delegate?.removeViewController(oldNextViewController)
      }
      if let newNextViewController = newNextViewController {
        delegate?.addViewController(newNextViewController)
      }
      nextViewController = newNextViewController
      didSelect = false
      layoutsViews()
    }

    if let oldNextViewController = oldNextViewController {
      endAppearanceTransition(for: selectedViewController)
      endAppearanceTransition(for: oldNextViewController)
      delegate?.didFinishScrolling(
        from: selectedViewController,
        to: oldNextViewController,
        transitionSuccessful: false
      )
    }
  }

  /// 取消向后滑动，处理未滑动到指定宽度，恢复之前的UI效果
  private func cancelScrollReverse() {
    guard let selectedViewController = selectedViewController else { return }
    let oldPreviousViewController = previousViewController

    if let previousViewController = oldPreviousViewController {
      beginAppearanceTransition(true, for: selectedViewController, animated: true)
      beginAppearanceTransition(false, for: previousViewController, animated: true)
    }

    if didSelect {
      let newPreviousViewController = dataSource?.viewControllerBefore(selectedViewController)
      if let oldPreviousViewController = oldPreviousViewController {
        delegate?.removeViewController(oldPreviousViewController)
      }
      if let newPreviousViewController = newPreviousViewController {
        delegate?.addViewController(newPreviousViewController)
      }
      previousViewController = newPreviousViewController
      didSelect = false
      layoutsViews()
    }

    if let oldPreviousViewController = oldPreviousViewController {
      endAppearanceTransition(for: selectedViewController)
      endAppearanceTransition(for: oldPreviousViewController)
      delegate?.didFinishScrolling(
        from: selectedViewController,
        to: oldPreviousViewController,
        transitionSuccessful: false
      )
    }
  }

  /// 将要向前置页面滑动
  private func willScrollForward() {
    if let selectedViewController = selectedViewController,
       let nextViewController = nextViewController {
      delegate?.willScroll(from: selectedViewController, to: nextViewController)
      beginAppearanceTransition(true, for: nextViewController, animated: true)
      beginAppearanceTransition(false, for: selectedViewController, animated: true)
    }
  }

  /// 将要向后置页面滑动
  private func willScrollReverse() {
    if let selectedViewController = selectedViewController,
       let previousViewController = previousViewController {
      delegate?.willScroll(from: selectedViewController, to: previousViewController)
      beginAppearanceTransition(true, for: previousViewController, animated: true)
      beginAppearanceTransition(false, for: selectedViewController, animated: true)
    }
  }

  /// 滑动到前置页面
  private func didScrollForward() {
    guard
      let oldSelectedViewController = selectedViewController,
      let oldNextViewController = nextViewController else { return }

    delegate?.didFinishScrolling(
      from: oldSelectedViewController,
      to: oldNextViewController,
      transitionSuccessful: true
    )

    let newNextViewController = dataSource?.viewControllerAfter(oldNextViewController)

    if let oldPreviousViewController = previousViewController {
      if oldPreviousViewController !== newNextViewController {
        delegate?.removeViewController(oldPreviousViewController)
      }
    }

    if let newNextViewController = newNextViewController {
      if newNextViewController !== previousViewController {
        delegate?.addViewController(newNextViewController)
      }
    }

    if didSelect {
      let newPreviousViewController = dataSource?.viewControllerBefore(oldNextViewController)
      if let oldSelectedViewController = selectedViewController {
        delegate?.removeViewController(oldSelectedViewController)
      }
      if let newPreviousViewController = newPreviousViewController {
        delegate?.addViewController(newPreviousViewController)
      }
      previousViewController = newPreviousViewController
      didSelect = false
    } else {
      previousViewController = oldSelectedViewController
    }

    selectedViewController = oldNextViewController
    nextViewController = newNextViewController

    layoutsViews()

    endAppearanceTransition(for: oldSelectedViewController)
    endAppearanceTransition(for: oldNextViewController)
  }

  /// 滑动到后置页面
  private func didScrollReverse() {
    guard
      let oldSelectedViewController = selectedViewController,
      let oldPreviousViewController = previousViewController else { return }

    delegate?.didFinishScrolling(
      from: oldSelectedViewController,
      to: oldPreviousViewController,
      transitionSuccessful: true
    )

    let newPreviousViewController = dataSource?.viewControllerBefore(oldPreviousViewController)

    if let oldNextViewController = nextViewController {
      if oldNextViewController !== newPreviousViewController {
        delegate?.removeViewController(oldNextViewController)
      }
    }

    if let newPreviousViewController = newPreviousViewController {
      if newPreviousViewController !== nextViewController {
        delegate?.addViewController(newPreviousViewController)
      }
    }

    if didSelect {
      let newNextViewController = dataSource?.viewControllerAfter(oldPreviousViewController)
      if let oldSelectedViewController = selectedViewController {
        delegate?.removeViewController(oldSelectedViewController)
      }
      if let newNextViewController = newNextViewController {
        delegate?.addViewController(newNextViewController)
      }
      nextViewController = newNextViewController
      didSelect = false
    } else {
      nextViewController = oldSelectedViewController
    }

    previousViewController = newPreviousViewController
    selectedViewController = oldPreviousViewController

    layoutsViews()

    endAppearanceTransition(for: oldSelectedViewController)
    endAppearanceTransition(for: oldPreviousViewController)
  }

  ///  子视图布局
  ///  keepContentOffset: 是否保持内容偏移
  private func layoutsViews(keepContentOffset: Bool = true) {
    var viewControllers: [UIViewController] = []

    if let previousViewController = previousViewController {
      viewControllers.append(previousViewController)
    }
    if let selectedViewController = selectedViewController {
      viewControllers.append(selectedViewController)
    }
    if let nextViewController = nextViewController {
      viewControllers.append(nextViewController)
    }

    delegate?.layoutViews(for: viewControllers, keepContentOffset: keepContentOffset)
  }

  /// 开始视图控制器的出现或消失过渡
  /// - Parameter isAppearing: 是否是出现
  /// - Parameter viewController: 视图控制器
  /// - Parameter animated: 是否动画
  private func beginAppearanceTransition(_ isAppearing: Bool,
                                         for viewController: UIViewController,
                                         animated: Bool) {
    switch appearanceState {
    case .appeared:
      delegate?.beginAppearanceTransition(
        isAppearing: isAppearing,
        viewController: viewController,
        animated: animated
      )
    case let .appearing(animated):
      delegate?.beginAppearanceTransition(
        isAppearing: isAppearing,
        viewController: viewController,
        animated: animated
      )
    case let .disappearing(animated):
      delegate?.beginAppearanceTransition(
        isAppearing: false,
        viewController: viewController,
        animated: animated
      )
    default:
      break
    }
  }

  /// 结束视图过度动画
  /// - Parameter viewController: 视图控制器
  private func endAppearanceTransition(for viewController: UIViewController) {
    guard case .appeared = appearanceState else { return }
    delegate?.endAppearanceTransition(viewController: viewController)
  }
}
