// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

class NEActionSheetPresentationController: NSObject {
  /// 点击空白区域是否收回弹出视图，默认 true
  var dismissOnTouchOutside: Bool = true

  /// 响应驱动消失手势驱动的距离. 默认 30
  var interactiveDismissalDistance: CGFloat = 30

  /// dismiss手势驱动
  var dismissAnimator: UIPercentDrivenInteractiveTransition?

  /// 点击消失的手势
  private var dismissGesture: UITapGestureRecognizer?

  /// 驱动消失手势
  private var dismissDrivenGesture: UIPanGestureRecognizer?

  /// 保存负责动画的父视图
  private var containerView: UIView?

  /// 已弹出的控制器
  private var toViewController: UIViewController?

  /// 处理点击消失
  /// - Parameter sender: 手势
  @objc
  private func handleDismissTap(sender: UITapGestureRecognizer) {
    toViewController?.dismiss(animated: true)
  }

  /// 处理百分比消失
  /// - Parameter sender: 手势
  @objc
  private func handleDismissDrive(sender: UIPanGestureRecognizer) {
    switch sender.state {
    case .began:
      toViewController?.dismiss(animated: true)
    case .changed:
      if let height = toViewController?.view.frame.size.height,
         height > 0 {
        let translateY = sender.translation(in: containerView).y
        let progress = translateY / height
        dismissAnimator?.update(progress)
      }
    case .ended:
      if let toHeight = toViewController?.view.frame.size.height,
         let containerHeight = containerView?.frame.size.height {
        let maxPercent = toHeight / containerHeight
        if dismissAnimator?.percentComplete ?? 0 / maxPercent > 0.3 {
          dismissAnimator?.finish()
        } else {
          dismissAnimator?.cancel()
        }
        dismissAnimator = nil
      }
    case .cancelled, .failed:
      dismissAnimator?.cancel()
      dismissAnimator = nil
    case .possible:
      break
    @unknown default:
      break
    }
  }
}

extension NEActionSheetPresentationController: UIViewControllerAnimatedTransitioning {
  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    0.3
  }

  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    if let toViewController = transitionContext.viewController(forKey: .to) {
      let preferedSize = toViewController.preferredContentSize
      let containerView = transitionContext.containerView
      let duration = transitionDuration(using: transitionContext)
      toViewController.view.frame = CGRect(x: 0, y: transitionContext.containerView.bounds.size.height - preferedSize.height, width: preferedSize.width, height: preferedSize.height)
      toViewController.view.transform = CGAffineTransform(translationX: 0, y: preferedSize.height)
      containerView.addSubview(toViewController.view)
      self.containerView = containerView
      self.toViewController = toViewController

      UIView.animate(withDuration: duration, delay: 0, options: .transitionFlipFromBottom) {
        toViewController.view.transform = .identity
      } completion: { finished in
        if self.dismissOnTouchOutside {
          let tapGesture = UITapGestureRecognizer(target: self, action: #selector(NEActionSheetPresentationController.handleDismissTap(sender:)))
          tapGesture.delegate = self
          tapGesture.numberOfTapsRequired = 1
          tapGesture.numberOfTouchesRequired = 1
          containerView.addGestureRecognizer(tapGesture)
          self.dismissGesture = tapGesture
        }
        if self.interactiveDismissalDistance > 0 {
          let dismissDrivenGesture = UIPanGestureRecognizer(target: self, action: #selector(NEActionSheetPresentationController.handleDismissDrive(sender:)))
          dismissDrivenGesture.delegate = self
          dismissDrivenGesture.minimumNumberOfTouches = 1
          containerView.addGestureRecognizer(dismissDrivenGesture)
          self.dismissDrivenGesture = dismissDrivenGesture
        }
        transitionContext.completeTransition(finished)
      }
    }
  }
}

extension NEActionSheetPresentationController: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if let toViewController = toViewController {
      if gestureRecognizer == dismissGesture {
        let shouldStart = !toViewController.view.bounds.contains(gestureRecognizer.location(in: toViewController.view))
        return shouldStart
      }
      if gestureRecognizer == dismissDrivenGesture {
        let locationInContent = gestureRecognizer.location(in: toViewController.view)
        let shouldStart = locationInContent.y >= 0 && locationInContent.y <= interactiveDismissalDistance
        if shouldStart {
          dismissAnimator = UIPercentDrivenInteractiveTransition()
        }
        return shouldStart
      }
    }
    return false
  }
}
