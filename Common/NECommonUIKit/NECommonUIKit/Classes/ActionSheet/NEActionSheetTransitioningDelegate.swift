// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// 转场动画代理实现
class NEActionSheetTransitioningDelegate: NSObject {
  /// 点击空白区域是否收回弹出视图，默认 true
  var dismissOnTouchOutside: Bool = true

  /// 响应驱动消失手势驱动的距离. 默认 30
  var interactiveDismissalDistance: CGFloat = 30

  /// present动画
  private var presentationController = NEActionSheetPresentationController()

  /// dismiss动画
  private var dismissalController = NEActionSheetDismissalController()

  private static var instance: NEActionSheetTransitioningDelegate?

  /// 创建默认对象，使用方则不需要管理生命周期
  /// - Returns: 默认对象
  class func defaultInstance() -> NEActionSheetTransitioningDelegate {
    guard let instance = instance else {
      instance = NEActionSheetTransitioningDelegate()
      return instance!
    }

    return instance
  }

  override func responds(to aSelector: Selector!) -> Bool {
    super.responds(to: aSelector) || presentationController.responds(to: aSelector)
  }

  override func forwardingTarget(for aSelector: Selector!) -> Any? {
    if presentationController.responds(to: aSelector) {
      return presentationController
    }
    return super.forwardingTarget(for: aSelector)
  }
}

extension NEActionSheetTransitioningDelegate: UIViewControllerTransitioningDelegate {
  func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    presentationController
  }

  func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    dismissalController
  }

  func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
    presentationController.dismissAnimator
  }
}
