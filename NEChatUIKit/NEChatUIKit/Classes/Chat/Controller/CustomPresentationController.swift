//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

final class CustomPresentationController: UIPresentationController {
  // MARK: - Properties

  private lazy var dimmingView: UIView = {
    let dimmingView = UIView()
    dimmingView.translatesAutoresizingMaskIntoConstraints = false
    dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    let recognizer = UITapGestureRecognizer(target: self,
                                            action: #selector(handleTap(recognizer:)))
    dimmingView.addGestureRecognizer(recognizer)
    return dimmingView
  }()

  override var frameOfPresentedViewInContainerView: CGRect {
    var frame: CGRect = .zero
    frame.size = size(forChildContentContainer: presentedViewController,
                      withParentContainerSize: containerView!.bounds.size)
    frame.origin.y = frame.size.height - 404
    return frame
  }

  /// 重写开始动画
  override func presentationTransitionWillBegin() {
    guard let containerView = containerView else {
      return
    }
    containerView.insertSubview(dimmingView, at: 0)
    NSLayoutConstraint.activate([
      dimmingView.topAnchor.constraint(equalTo: containerView.topAnchor),
      dimmingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      dimmingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      dimmingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
    ])

    guard let coordinator = presentedViewController.transitionCoordinator else {
      dimmingView.alpha = 1.0
      return
    }

    coordinator.animate(alongsideTransition: { _ in
      self.dimmingView.alpha = 1.0
    })
  }

  /// 重写结束动画
  override func dismissalTransitionWillBegin() {
    guard let coordinator = presentedViewController.transitionCoordinator else {
      dimmingView.alpha = 0.0
      return
    }
    coordinator.animate(alongsideTransition: { _ in
      self.dimmingView.alpha = 0.0
    })
  }

  override func containerViewWillLayoutSubviews() {
    presentedView?.frame = frameOfPresentedViewInContainerView
  }

  override func size(forChildContentContainer container: UIContentContainer,
                     withParentContainerSize parentSize: CGSize) -> CGSize {
    CGSize(width: parentSize.width, height: parentSize.height)
  }
}

// MARK: - Private

private extension CustomPresentationController {
  @objc func handleTap(recognizer: UITapGestureRecognizer) {
    presentingViewController.dismiss(animated: true)
  }
}
