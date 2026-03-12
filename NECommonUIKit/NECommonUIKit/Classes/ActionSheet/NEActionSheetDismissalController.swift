// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

class NEActionSheetDismissalController: NSObject {}

extension NEActionSheetDismissalController: UIViewControllerAnimatedTransitioning {
  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    transitionContext?.isInteractive ?? false ? 0.6 : 0.2
  }

  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    if let fromViewController = transitionContext.viewController(forKey: .from) {
      let duration = transitionDuration(using: transitionContext)
      let curve: UIView.AnimationOptions = transitionContext.isInteractive ? .curveLinear : .transitionFlipFromBottom
      UIView.animate(withDuration: duration, delay: 0, options: curve) {
        fromViewController.view.transform = CGAffineTransform(translationX: 0, y: fromViewController.view.frame.size.height)
      } completion: { finished in
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
      }
    }
  }
}
