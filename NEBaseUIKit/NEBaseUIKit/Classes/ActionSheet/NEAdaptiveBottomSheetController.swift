// Copyright (c) 2026 NetEase. All rights reserved.

import UIKit

/// 自适应宿主下可嵌入内容列的底部弹窗基类。
///
/// 子类只需要搭建自己的弹窗内容；列宽、rail 避让、折叠/展开后的重排
/// 以及列内 dismiss 都由基类统一处理。
open class NEAdaptiveBottomSheetController: UIViewController {
  /// 列内嵌时由宿主移除子视图；为 nil 时保持原 modal dismiss。
  public var columnDismissHandler: (() -> Void)?

  private weak var columnPresenter: UIViewController?
  private weak var columnContainerView: UIView?
  private var columnGeometryObserver: NSObjectProtocol?

  /// 嵌入根控制器的内容区域。
  func embedInColumn(presenter: UIViewController, container: UIView) {
    columnPresenter = presenter
    columnContainerView = container
    updateColumnFrame()
    columnGeometryObserver = NotificationCenter.default.addObserver(
      forName: Notification.Name("NEAdaptiveGeometryDidChange"), object: nil, queue: .main
    ) { [weak self] _ in
      self?.scheduleColumnRefresh()
    }
  }

  func detachFromColumn() {
    if let observer = columnGeometryObserver {
      NotificationCenter.default.removeObserver(observer)
      columnGeometryObserver = nil
    }
    columnPresenter = nil
    columnContainerView = nil
    columnDismissHandler = nil
  }

  open override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    updateColumnFrame()
  }

  open override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
    guard let columnDismissHandler else {
      super.dismiss(animated: flag, completion: completion)
      return
    }
    columnDismissHandler()
    completion?()
  }

  private func scheduleColumnRefresh() {
    updateColumnFrame()
    // 折叠/展开时聊天页先移动、后改宽度；下一轮 runloop、转场中段和结束后各补一次。
    DispatchQueue.main.async { [weak self] in self?.updateColumnFrame() }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in self?.updateColumnFrame() }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in self?.updateColumnFrame() }
  }

  private func updateColumnFrame() {
    guard let host = columnPresenter?.viewIfLoaded, host.window != nil,
          let container = columnContainerView else { return }
    var target = host.convert(host.bounds, to: container)
    if target.width >= container.bounds.width - 1 {
      target.size.width = max(0, target.width - max(0, container.safeAreaInsets.right))
    }
    guard view.frame != target else { return }
    view.frame = target
    // 弹窗内部多为 Auto Layout 或 draw(_:) 自绘，frame 变化后必须立即重排/重绘。
    view.setNeedsLayout()
    view.layoutIfNeeded()
    for subview in view.subviews {
      subview.setNeedsDisplay()
    }
  }
}
